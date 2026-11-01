import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/api/api_client.dart';
import 'package:uiverse/state/auth.dart';
import 'package:uiverse/state/prefs.dart';
import 'package:uiverse/state/saves.dart';
import 'package:uiverse/state/saves_sync.dart';

import '../api/fake_backend.dart';
import 'account_harness.dart';

const String _a = 'ana@example.com';
const String _b = 'bo@example.com';

String _userJson(String id, String email) => jsonEncode(AccountUser(id: id, email: email).toJson());

/// A signed-in or guest app with sync running and retries instant.
class _App {
  _App(this.rig, this.container, this.prefs, this.delays);

  final AccountRig rig;
  final ProviderContainer container;
  final SharedPreferences prefs;
  final List<Duration> delays;

  SavesNotifier get saves => container.read(savesProvider.notifier);
  SavesState get state => container.read(savesProvider);
  AuthNotifier get auth => container.read(authProvider.notifier);
  FakeBackend get backend => rig.backend;
  SavesSync get sync => container.read(savesSyncProvider)!;

  Future<void> settle() async {
    await pumpEventQueue();
    await sync.settle();
    await pumpEventQueue();
  }

  Future<void> signIn(String email) async {
    await auth.sendMagicLink(email);
    await auth.handleLink(rig.returnLink(email));
    await settle();
  }
}

Future<_App> _guest({Map<String, Object> values = const {}, AccountRig? rig, List<Override> extra = const []}) async {
  final r = rig ?? AccountRig();
  final delays = <Duration>[];
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer.test(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    syncDelayProvider.overrideWithValue((d) async => delays.add(d)),
    ...r.overrides,
    ...extra,
  ]);
  container.read(savesSyncProvider);
  await pumpEventQueue();
  return _App(r, container, prefs, delays);
}

/// Already signed in as [email] when the app starts.
Future<_App> _signedIn(String email, {Map<String, Object> values = const {}, AccountRig? rig}) async {
  final r = rig ?? AccountRig();
  final account = r.backend.account(email);
  r.secrets.values['uiv.auth.token'] = r.backend.sessionFor(email);
  final app = await _guest(rig: r, values: {kAuthUserKey: _userJson(account.id, email), ...values});
  await app.settle();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signing in merges guest saves into the account and clears the guest copy', () async {
    final app = await _guest();
    app.saves.toggle('guest-design');
    final board = app.saves.createCollection('Refs');
    app.saves.pin('guest-design', board);

    await app.signIn(_a);

    final remote = app.backend.account(_a);
    expect(remote.saves.single['slug'], 'guest-design');
    expect(remote.collections.single['id'], 'refs');
    expect(remote.pins.single['collectionId'], 'refs');
    expect(app.state.isSaved('guest-design'), isTrue);
    expect(app.state.isPinned('guest-design', 'refs'), isTrue);
    expect(app.prefs.containsKey(kSavesKey), isFalse);
    expect(app.saves.pendingMerge, isNull);
  });

  test('account wins a merge conflict, and account saves appear', () async {
    final rig = AccountRig();
    rig.backend.account(_a).saves.add({'slug': 'shared', 'at': 9, 'note': 'mine'});
    rig.backend.account(_a).saves.add({'slug': 'from-web', 'at': 8, 'note': ''});
    final app = await _guest(rig: rig);
    app.saves.toggle('shared');
    await app.signIn(_a);
    expect(app.state.saves.map((s) => s.slug), unorderedEquals(['shared', 'from-web']));
    expect(app.state.saves.firstWhere((s) => s.slug == 'shared').note, 'mine');
  });

  test('guest saves stay visible while offline, and merge when back', () async {
    final app = await _guest();
    app.saves.toggle('guest-design');
    app.backend.forceOn('/api/v1/saves/sync', http.Response('', 503));
    await app.signIn(_a);

    expect(app.saves.pendingMerge, isNotNull);
    expect(app.state.isSaved('guest-design'), isTrue);

    app.sync.run(full: true);
    await app.settle();
    expect(app.saves.pendingMerge, isNull);
    expect(app.backend.account(_a).saves.single['slug'], 'guest-design');
  });

  test('a merge killed before it finished retries next launch', () async {
    final rig = AccountRig();
    rig.backend.account(_a);
    final key = pendingMergeKey('u1');
    final app = await _signedIn(_a, rig: rig, values: {
      key: '{"saves":[{"slug":"kept","at":1}],"collections":[]}',
    });
    expect(app.backend.account(_a).saves.single['slug'], 'kept');
    expect(app.prefs.containsKey(key), isFalse);
  });

  test('changes go to the server in order, and leave the outbox', () async {
    final app = await _signedIn(_a);
    final id = app.saves.createCollection('Refs');
    app.saves.pin('a', id);
    app.saves.setNote('a', 'hi');
    await app.settle();
    expect(app.backend.ops.map((o) => o['type']), ['create', 'pin', 'note']);
    expect(app.saves.outbox, isEmpty);
    expect(app.backend.account(_a).save('a')?['note'], 'hi');
  });

  test('a change while offline survives a restart and goes out later', () async {
    final rig = AccountRig();
    final app = await _signedIn(_a, rig: rig);
    rig.backend.forceNext(http.Response('', 503));
    app.saves.toggle('offline');
    await app.settle();
    expect(app.saves.outbox, hasLength(1));

    final stored = {for (final k in app.prefs.getKeys()) k: app.prefs.get(k)!};
    final again = await _signedIn(_a, rig: rig, values: stored);
    expect(again.saves.outbox, isEmpty);
    expect(rig.backend.account(_a).save('offline'), isNotNull);
  });

  test('a change made while the GET was in flight survives adopting', () async {
    final rig = AccountRig();
    final app = await _signedIn(_a, rig: rig);
    final gate = Completer<void>();
    rig.backend.gate = gate;
    app.sync.run(full: true);
    await pumpEventQueue();
    app.saves.toggle('made-mid-flight');
    gate.complete();
    await app.settle();
    expect(app.state.isSaved('made-mid-flight'), isTrue);
    expect(rig.backend.account(_a).save('made-mid-flight'), isNotNull);
  });

  test('422 drops the change and resyncs to the server truth', () async {
    final app = await _signedIn(_a);
    app.saves.toggle('unknown-to-web');
    expect(app.state.isSaved('unknown-to-web'), isTrue);
    await app.settle();
    expect(app.saves.outbox, isEmpty);
    expect(app.state.isSaved('unknown-to-web'), isFalse);
  });

  test('429 waits Retry-After, then sends', () async {
    final app = await _signedIn(_a);
    app.backend.forceNext(http.Response('{"error":"rate"}', 429, headers: {'retry-after': '7'}));
    app.saves.toggle('a');
    await app.settle();
    expect(app.delays, [const Duration(seconds: 7)]);
    expect(app.backend.account(_a).save('a'), isNotNull);
  });

  test('a 500 backs off, then drops so one op cannot block the queue', () async {
    final app = await _signedIn(_a);
    for (var i = 0; i < kMaxOpAttempts; i++) {
      app.backend.forceNext(http.Response('', 500));
    }
    app.saves.toggle('poison');
    await app.settle();
    expect(app.delays, [const Duration(seconds: 2), const Duration(seconds: 4)]);
    expect(app.saves.outbox, isEmpty);

    app.saves.toggle('next');
    await app.settle();
    expect(app.backend.account(_a).save('next'), isNotNull);
  });

  test('401 keeps everything local and asks for sign-in', () async {
    final app = await _signedIn(_a);
    app.backend.forceNext(http.Response('{"error":"signed-out"}', 401));
    app.saves.toggle('a');
    await app.settle();
    expect(app.container.read(authProvider).expired, isTrue);
    expect(app.saves.outbox, hasLength(1));
    expect(app.state.isSaved('a'), isTrue);
  });

  test('signing back in after 401 sends what waited', () async {
    final app = await _signedIn(_a);
    app.backend.forceNext(http.Response('{"error":"signed-out"}', 401));
    app.saves.toggle('a');
    await app.settle();

    await app.signIn(_a);
    expect(app.container.read(authProvider).expired, isFalse);
    expect(app.backend.account(_a).save('a'), isNotNull);
    expect(app.saves.outbox, isEmpty);
  });

  test('sign-out wipes account copies; a late answer cannot resurrect them', () async {
    final rig = AccountRig();
    rig.backend.account(_a).saves.add({'slug': 'private', 'at': 1, 'note': ''});
    final app = await _signedIn(_a, rig: rig);
    expect(app.state.isSaved('private'), isTrue);

    final gate = Completer<void>();
    rig.backend.gate = gate;
    app.sync.run(full: true);
    await pumpEventQueue();
    await app.auth.signOut();
    gate.complete();
    await app.settle();

    expect(app.state.count, 0);
    expect(app.prefs.getKeys().where((k) => k.startsWith('uiv.saves.')), isEmpty);
  });

  test('a different account never sees the last one\'s copy', () async {
    final rig = AccountRig();
    rig.backend.account(_a).saves.add({'slug': 'ana-only', 'at': 1, 'note': ''});
    final app = await _signedIn(_a, rig: rig);
    rig.backend.forceNext(http.Response('{"error":"signed-out"}', 401));
    app.saves.toggle('ana-unsent');
    await app.settle();

    await app.signIn(_b);
    expect(app.state.isSaved('ana-only'), isFalse);
    expect(app.state.isSaved('ana-unsent'), isFalse);
    expect(rig.backend.account(_b).saves, isEmpty);
    expect(app.prefs.getKeys().where((k) => k.contains('u1')), isEmpty);
  });

  test('sign-out before a merge lands gives guest saves back', () async {
    final rig = AccountRig();
    final app = await _signedIn(_a, rig: rig, values: {
      pendingMergeKey('u1'): '{"saves":[{"slug":"mine","at":1}]}',
    });
    // The merge above ran; put one back as if it hadn't.
    app.prefs.setString(pendingMergeKey('u1'), '{"saves":[{"slug":"mine","at":1}]}').ignore();
    await app.auth.signOut();
    expect(app.state.isSaved('mine'), isTrue);
    expect(app.prefs.containsKey(kSavesKey), isTrue);
  });

  test('an outbox with junk in it keeps the real ops', () async {
    final app = await _signedIn(_a, values: {
      outboxKey('u1'): '["nope",{"type":"wipe"},{"type":"set","slug":"a","saved":true,"at":1}]',
    });
    expect(app.backend.ops.single['slug'], 'a');
  });

  test('settle waits for the last send', () async {
    final app = await _signedIn(_a);
    app.saves.toggle('a');
    await app.sync.settle();
    expect(app.backend.account(_a).save('a'), isNotNull);
  });

  test('without a backend there is no sync and saves stay local', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = MockClient((_) async => fail('no network call expected'));
    final c = ProviderContainer.test(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      httpClientProvider.overrideWithValue(client),
    ]);
    expect(c.read(savesSyncProvider), isNull);
    c.read(savesProvider.notifier).toggle('a');
    expect(prefs.getString(kSavesKey), contains('"a"'));
  });
}
