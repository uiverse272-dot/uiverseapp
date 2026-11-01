import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import 'prefs.dart';

/// Prefs key of the signed-in [AccountUser], so the account shows on the
/// first frame. The token itself stays in [SecretStore].
const String kAuthUserKey = 'uiv.auth.user';

const String _tokenKey = 'uiv.auth.token';
const String _verifierKey = 'uiv.auth.verifier';

/// Secrets kept out of prefs. Tests swap in a map.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class DeviceSecretStore implements SecretStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final secretStoreProvider = Provider<SecretStore>((ref) => DeviceSecretStore());

/// `uiverse://auth` links arriving at the app, including the one that opened it.
final authLinksProvider = Provider<Stream<Uri>>((ref) => AppLinks().uriLinkStream);

/// Opens an address in the system browser; false if nothing could.
final openBrowserProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// A random secret that never leaves this install until the exchange.
String newVerifier() {
  final Random random = Random.secure();
  return base64Url
      .encode(List<int>.generate(32, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

/// What the server gets to hold instead of the verifier.
String challengeFor(String verifier) =>
    base64Url.encode(sha256.convert(utf8.encode(verifier)).bytes).replaceAll('=', '');

enum AuthFailure {
  /// The link was used, expired or wasn't ours.
  badLink,

  /// The server couldn't be reached.
  network,

  /// The provider or the server refused the sign-in.
  refused,

  /// No browser could be opened.
  browser,

  /// Secure storage failed on this device.
  device,
}

@immutable
class AuthState {
  const AuthState({this.user, this.waiting = false, this.sentTo, this.failure, this.expired = false});

  final AccountUser? user;

  /// Sign-in is out in the browser or an email.
  final bool waiting;

  /// The address a link went to, while [waiting] for it.
  final String? sentTo;

  final AuthFailure? failure;

  /// The server ended the session; local data stays until sign-in or sign-out.
  final bool expired;

  bool get signedIn => user != null;

  AuthState copyWith({AccountUser? user, bool? expired}) =>
      AuthState(user: user ?? this.user, expired: expired ?? this.expired);

  /// Sign-in attempt state replaced, the account untouched.
  AuthState attempt({bool waiting = false, String? sentTo, AuthFailure? failure}) =>
      AuthState(user: user, expired: expired, waiting: waiting, sentTo: sentTo, failure: failure);
}

enum DeleteResult { deleted, needsFreshSignIn, failed }

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Sign-in flow in `docs/api-v1.md`. Without an API this stays signed out and
/// touches no plugin.
class AuthNotifier extends Notifier<AuthState> {
  bool _exchanging = false;

  SecretStore get _secrets => ref.read(secretStoreProvider);

  @override
  AuthState build() {
    if (ref.watch(apiProvider) == null) return const AuthState();
    final sub = ref.read(authLinksProvider).listen(
          handleLink,
          onError: (Object e) => debugPrint('auth: link stream failed ($e)'),
        );
    ref.onDispose(sub.cancel);
    final user = _storedUser();
    // iOS keeps the keychain across a reinstall, prefs don't: no user, no session.
    if (user == null) unawaited(_secrets.delete(_tokenKey));
    return AuthState(user: user);
  }

  AccountUser? _storedUser() {
    final raw = ref.read(sharedPreferencesProvider).getString(kAuthUserKey);
    if (raw == null) return null;
    try {
      return AccountUser.fromJson((jsonDecode(raw) as Map<Object?, Object?>).cast());
    } on Object catch (e) {
      debugPrint('uiv.auth.user: could not parse stored user ($e); signing out');
      return null;
    }
  }

  /// The session token, or null when signed out.
  Future<String?> token() => _secrets.read(_tokenKey);

  /// Emails a sign-in link to [email].
  Future<void> sendMagicLink(String email) async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    await _begin((challenge) async {
      await api.requestMagicLink(email, challenge);
      return true;
    }, sentTo: email);
  }

  /// Opens [provider]'s sign-in in the browser.
  Future<void> startOAuth(OAuthProvider provider) async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    await _begin((challenge) => ref.read(openBrowserProvider)(api.oauthStart(provider, challenge)));
  }

  /// The browser or email now has the job. The verifier goes to secure storage
  /// first: the OS may kill the app while the browser is in front.
  Future<void> _begin(Future<bool> Function(String challenge) start, {String? sentTo}) async {
    state = state.attempt(waiting: true, sentTo: sentTo);
    try {
      final verifier = newVerifier();
      await _secrets.write(_verifierKey, verifier);
      if (!await start(challengeFor(verifier))) {
        await _abandon(AuthFailure.browser);
      }
    } on ApiException catch (e) {
      debugPrint('auth: could not start sign-in ($e)');
      await _abandon(e.isTransient ? AuthFailure.network : AuthFailure.refused);
    } on PlatformException catch (e) {
      debugPrint('auth: secure storage failed ($e)');
      await _abandon(AuthFailure.device);
    }
  }

  Future<void> _abandon(AuthFailure? failure) async {
    await _secrets.delete(_verifierKey);
    state = state.attempt(failure: failure);
  }

  /// Stops waiting. A link that arrives later is ignored.
  Future<void> cancel() => _abandon(null);

  /// Clears a shown failure.
  void clearFailure() => state = state.attempt(waiting: state.waiting, sentTo: state.sentTo);

  /// A `uiverse://auth` link came in. Without a verifier of ours it is ignored,
  /// or anyone could sign this app into their own account with a crafted link.
  Future<void> handleLink(Uri uri) async {
    final api = ref.read(apiProvider);
    if (api == null || uri.scheme != 'uiverse' || uri.host != 'auth' || _exchanging) return;
    _exchanging = true;
    try {
      final verifier = await _secrets.read(_verifierKey);
      if (verifier == null) return;
      final String? token = uri.queryParameters['token'];
      if (token == null) {
        await _abandon(AuthFailure.refused);
        return;
      }
      final result = await api.exchange(token, verifier);
      await _secrets.write(_tokenKey, result.token);
      await _secrets.delete(_verifierKey);
      await ref.read(sharedPreferencesProvider).setString(kAuthUserKey, jsonEncode(result.user.toJson()));
      state = AuthState(user: result.user);
    } on ApiException catch (e) {
      debugPrint('auth: exchange failed ($e)');
      if (e.isTransient) {
        // The token wasn't spent: tapping the link again can still work.
        state = state.attempt(waiting: true, sentTo: state.sentTo, failure: AuthFailure.network);
      } else {
        await _abandon(AuthFailure.badLink);
      }
    } on PlatformException catch (e) {
      debugPrint('auth: secure storage failed ($e)');
      await _abandon(AuthFailure.device);
    } finally {
      _exchanging = false;
    }
  }

  /// Ends the session here whatever the server says: someone signing out of a
  /// shared phone can't wait for the network.
  Future<void> signOut() async {
    final api = ref.read(apiProvider);
    final token = await this.token();
    if (api != null && token != null) {
      try {
        await api.signOut(token);
      } on ApiException catch (e) {
        debugPrint('auth: server sign-out failed ($e)');
      }
    }
    await _forget();
  }

  Future<void> _forget() async {
    await _secrets.delete(_tokenKey);
    await ref.read(sharedPreferencesProvider).remove(kAuthUserKey);
    state = const AuthState();
  }

  /// Deletes the account and everything in it on the server, then forgets it
  /// here. The server only allows this from a session under an hour old.
  Future<DeleteResult> deleteAccount() async {
    final api = ref.read(apiProvider);
    final token = await this.token();
    if (api == null || token == null) return DeleteResult.failed;
    try {
      await api.deleteAccount(token);
    } on ApiException catch (e) {
      debugPrint('auth: delete failed ($e)');
      if (e.code == 'SESSION_EXPIRED' || e.status == 401) return DeleteResult.needsFreshSignIn;
      return DeleteResult.failed;
    }
    await _forget();
    return DeleteResult.deleted;
  }

  /// The server said 401. Everything local stays; the UI offers sign-in.
  void sessionExpired() {
    if (state.signedIn) state = state.copyWith(expired: true);
  }
}
