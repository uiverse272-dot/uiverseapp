import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/api/api_client.dart';
import 'package:uiverse/state/auth.dart';
import 'package:uiverse/state/prefs.dart';

import '../api/fake_backend.dart';

class MapSecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Everything an app with a backend needs, faked.
class AccountRig {
  AccountRig({FakeBackend? backend}) : backend = backend ?? FakeBackend();

  final FakeBackend backend;
  final MapSecretStore secrets = MapSecretStore();
  final StreamController<Uri> links = StreamController<Uri>.broadcast();
  final List<Uri> opened = [];
  bool browserWorks = true;

  List<Override> get overrides => [
        apiUrlProvider.overrideWithValue('https://uiverse.test'),
        httpClientProvider.overrideWithValue(MockClient(backend.handle)),
        secretStoreProvider.overrideWithValue(secrets),
        authLinksProvider.overrideWithValue(links.stream),
        openBrowserProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return browserWorks;
        }),
      ];

  /// The challenge from the last sign-in the server saw: emailed, or in the
  /// browser address.
  String get lastChallenge => backend.links.isNotEmpty ? backend.links.last.c : opened.last.queryParameters['c']!;

  /// The link the browser hands back after the server issues a token.
  Uri returnLink(String email) => Uri.parse('uiverse://auth?token=${backend.issueToken(email, lastChallenge)}');
}

Future<(ProviderContainer, SharedPreferences)> accountContainer(
  AccountRig rig, {
  Map<String, Object> values = const {},
  Clock? clock,
}) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer.test(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    if (clock != null) clockProvider.overrideWithValue(clock),
    ...rig.overrides,
  ]);
  return (container, prefs);
}
