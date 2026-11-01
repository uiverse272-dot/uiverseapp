import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../state/save_ops.dart';
import '../state/saves_model.dart';

/// Base URL of the backend, set with `--dart-define=UIVERSE_API_URL=...`.
/// Empty means guest-only: no account UI, no network calls.
const String kApiUrl = String.fromEnvironment('UIVERSE_API_URL');

final apiUrlProvider = Provider<String>((ref) => kApiUrl);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// The API, or null when no backend is configured.
final apiProvider = Provider<UiverseApi?>((ref) {
  final url = ref.watch(apiUrlProvider);
  return url.isEmpty ? null : UiverseApi(ref.watch(httpClientProvider), url);
});

/// A failed call. [status] is 0 when the server was never reached.
class ApiException implements Exception {
  const ApiException(this.status, {this.code, this.retryAfter, this.minutes});

  final int status;

  /// `error` from the body, or Better Auth's `code`.
  final String? code;

  /// From the `Retry-After` header.
  final Duration? retryAfter;

  /// From a form rate limit.
  final int? minutes;

  /// Worth trying again later: the change itself wasn't refused.
  bool get isTransient => status == 0 || status == 429 || status >= 500;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// The signed-in person.
@immutable
class AccountUser {
  const AccountUser({required this.id, required this.email, this.name, this.image});

  final String id;
  final String email;
  final String? name;
  final String? image;

  factory AccountUser.fromJson(Map<String, Object?> j) => AccountUser(
        id: j['id']! as String,
        email: j['email']! as String,
        name: j['name'] as String?,
        image: j['image'] as String?,
      );

  Map<String, Object?> toJson() => {'id': id, 'email': email, 'name': name, 'image': image};

  @override
  bool operator ==(Object other) =>
      other is AccountUser && other.id == id && other.email == email && other.name == name && other.image == image;

  @override
  int get hashCode => Object.hash(id, email, name, image);
}

enum OAuthProvider { google, apple }

/// Fields of the Finds submission form.
@immutable
class FindSubmission {
  const FindSubmission({
    required this.title,
    required this.creator,
    required this.email,
    required this.url,
    required this.imageUrl,
    required this.confirm,
    this.creatorUrl = '',
    this.tags = const [],
    this.note = '',
  });

  final String title;
  final String creator;
  final String email;
  final String url;
  final String imageUrl;
  final String creatorUrl;
  final List<String> tags;
  final String note;
  final bool confirm;

  Map<String, Object?> toJson() => {
        'title': title,
        'creator': creator,
        'email': email,
        'url': url,
        'imageUrl': imageUrl,
        'creatorUrl': creatorUrl,
        'tags': tags,
        'note': note,
        'confirm': confirm,
      };
}

/// Fields of the takedown form.
@immutable
class TakedownRequest {
  const TakedownRequest({
    required this.domain,
    required this.name,
    required this.email,
    required this.confirm,
    this.agent = false,
    this.details = '',
  });

  final String domain;
  final String name;
  final String email;
  final bool agent;
  final String details;
  final bool confirm;

  Map<String, Object?> toJson() => {
        'domain': domain,
        'name': name,
        'email': email,
        'role': agent ? 'agent' : 'owner',
        'details': details,
        'confirm': confirm,
      };
}

/// The calls in `docs/api-v1.md`. Every failure is an [ApiException].
class UiverseApi {
  UiverseApi(this._client, String baseUrl) : _base = Uri.parse(baseUrl);

  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;
  final Uri _base;

  /// Browser address that starts [provider]'s sign-in.
  Uri oauthStart(OAuthProvider provider, String challenge) => _base.replace(
        path: '/api/mobile/start',
        queryParameters: {'provider': provider.name, 'c': challenge},
      );

  Future<void> requestMagicLink(String email, String challenge) =>
      _post('/api/mobile/magic-link', {'email': email, 'c': challenge});

  Future<({String token, AccountUser user})> exchange(String token, String verifier) async {
    final j = await _post('/api/mobile/exchange', {'token': token, 'verifier': verifier});
    return (
      token: j['token']! as String,
      user: AccountUser.fromJson((j['user']! as Map<Object?, Object?>).cast()),
    );
  }

  Future<void> signOut(String token) => _post('/api/auth/sign-out', const {}, token: token);

  Future<void> deleteAccount(String token) => _post('/api/auth/delete-user', const {}, token: token);

  Future<SavesState> loadSaves(String token) async => SavesState.fromJson(await _get('/api/v1/saves', token));

  /// Merges [guest] into the account. Safe to repeat.
  Future<SavesState> mergeSaves(String token, SavesState guest) async =>
      SavesState.fromJson(await _post('/api/v1/saves/sync', {'guest': guest.toJson()}, token: token));

  Future<void> sendOp(String token, SaveOp op) => _post('/api/v1/saves/op', op.toJson(), token: token);

  /// Returns the reference to quote back to the submitter.
  Future<String> submitFind(FindSubmission find) async =>
      (await _post('/api/v1/finds', find.toJson()))['ref']! as String;

  /// Returns the reference and how many captures are held from the domain.
  Future<({String ref, int held})> requestTakedown(TakedownRequest request) async {
    final j = await _post('/api/v1/takedowns', request.toJson());
    return (ref: j['ref']! as String, held: (j['held'] as num?)?.toInt() ?? 0);
  }

  Future<Map<String, Object?>> _get(String path, String token) =>
      _send(() => _client.get(_base.replace(path: path), headers: _headers(token)));

  Future<Map<String, Object?>> _post(String path, Map<String, Object?> body, {String? token}) => _send(
        () => _client.post(_base.replace(path: path), headers: _headers(token), body: jsonEncode(body)),
      );

  // No Cookie, ever: Better Auth skips its origin check for bearer calls.
  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, Object?>> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(0, code: 'timeout');
    } on http.ClientException catch (e) {
      throw ApiException(0, code: e.message);
    }
    final Map<String, Object?> body = _json(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(
      res.statusCode,
      code: (body['error'] ?? body['code']) as String?,
      retryAfter: switch (int.tryParse(res.headers['retry-after'] ?? '')) {
        final int s => Duration(seconds: s),
        null => null,
      },
      minutes: (body['minutes'] as num?)?.toInt(),
    );
  }

  /// An error page isn't JSON; the status still says what happened.
  Map<String, Object?> _json(String body) {
    if (body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException catch (e) {
      debugPrint('api: response is not JSON ($e)');
      return const {};
    }
  }
}
