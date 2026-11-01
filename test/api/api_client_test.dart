import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uiverse/api/api_client.dart';
import 'package:uiverse/state/save_ops.dart';
import 'package:uiverse/state/saves_model.dart';

import 'fake_backend.dart';

void main() {
  late FakeBackend backend;
  late UiverseApi api;

  setUp(() {
    backend = FakeBackend();
    api = UiverseApi(MockClient(backend.handle), 'https://uiverse.test');
  });

  test('parses the contract fixture, keeping designs unknown to the app', () {
    final raw = File('test/api/fixtures/saves_state.json').readAsStringSync();
    final s = SavesState.fromJson(jsonDecode(raw) as Map<String, Object?>);
    expect(s.saves.map((e) => e.slug), contains('web-only-capture'));
    expect(s.saves.first.note, 'hero');
    expect(s.collections.single.description, 'Client work');
    expect(s.savesIn('refs').single.slug, 's001-ledgerly-homepage');
  });

  test('ops reach the server and read back', () async {
    final token = backend.sessionFor('a@b.co');
    await api.sendOp(token, const CreateCollection('refs', 'Refs'));
    await api.sendOp(token, const SetPinned('s001', 'refs', pinned: true, at: 5));
    final s = await api.loadSaves(token);
    expect(s.saves.single, const SaveEntry(slug: 's001', at: 5));
    expect(s.pins.single.collectionId, 'refs');
    expect(s.collections.single.name, 'Refs');
  });

  test('merge keeps the account copy and is safe to repeat', () async {
    final token = backend.sessionFor('a@b.co');
    await api.sendOp(token, const SetSaved('a', saved: true, at: 9));
    const guest = SavesState(
      saves: [SaveEntry(slug: 'a', at: 1), SaveEntry(slug: 'b', at: 2), SaveEntry(slug: 'unknown-x', at: 3)],
      collections: [SaveCollection(id: 'refs', name: 'Refs')],
      pins: [SavePin(slug: 'b', collectionId: 'refs', at: 2)],
    );
    await api.mergeSaves(token, guest);
    final s = await api.mergeSaves(token, guest);
    expect(s.saves.map((e) => e.slug), unorderedEquals(['a', 'b']));
    expect(s.saves.firstWhere((e) => e.slug == 'a').at, 9);
    expect(s.pins, hasLength(1));
  });

  test('sends the bearer token and never a cookie', () async {
    late http.Request seen;
    final client = MockClient((r) async {
      seen = r;
      return http.Response('{"saves":[]}', 200);
    });
    await UiverseApi(client, 'https://uiverse.test').loadSaves('tok');
    expect(seen.headers['Authorization'], 'Bearer tok');
    expect(seen.headers.keys.map((k) => k.toLowerCase()), isNot(contains('cookie')));
  });

  test('a refused op carries its code and is not transient', () async {
    final token = backend.sessionFor('a@b.co');
    await expectLater(
      api.sendOp(token, const SetSaved('unknown-x', saved: true, at: 1)),
      throwsA(isA<ApiException>()
          .having((e) => e.status, 'status', 422)
          .having((e) => e.code, 'code', 'unknown-item')
          .having((e) => e.isTransient, 'transient', isFalse)),
    );
  });

  test('429 reads Retry-After and form minutes', () async {
    backend.forceNext(http.Response('{"error":"rate","minutes":42}', 429, headers: {'retry-after': '30'}));
    await expectLater(
      api.loadSaves(backend.sessionFor('a@b.co')),
      throwsA(isA<ApiException>()
          .having((e) => e.retryAfter, 'retryAfter', const Duration(seconds: 30))
          .having((e) => e.minutes, 'minutes', 42)
          .having((e) => e.isTransient, 'transient', isTrue)),
    );
  });

  test('a non-JSON error page still reports its status', () async {
    backend.forceNext(http.Response('<html>Bad gateway</html>', 502));
    await expectLater(
      api.loadSaves('x'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 502)),
    );
  });

  test('a dropped connection is status 0 and transient', () async {
    final client = MockClient((_) async => throw http.ClientException('offline'));
    await expectLater(
      UiverseApi(client, 'https://uiverse.test').loadSaves('tok'),
      throwsA(isA<ApiException>()
          .having((e) => e.status, 'status', 0)
          .having((e) => e.isTransient, 'transient', isTrue)),
    );
  });

  test('401 without a session', () async {
    await expectLater(
      api.loadSaves('nobody'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
  });

  test('oauthStart builds the browser address', () {
    final uri = api.oauthStart(OAuthProvider.apple, 'abc');
    expect(uri.toString(), 'https://uiverse.test/api/mobile/start?provider=apple&c=abc');
  });

  test('forms return their reference', () async {
    final ref = await api.submitFind(const FindSubmission(
      title: 'Tidal',
      creator: 'Ana',
      email: 'ana@example.com',
      url: 'https://example.com/a',
      imageUrl: 'https://example.com/a.png',
      confirm: true,
      tags: ['motion'],
    ));
    expect(ref, startsWith('FD-'));

    final takedown = await api.requestTakedown(const TakedownRequest(
      domain: 'example.com',
      name: 'Ana',
      email: 'ana@example.com',
      confirm: true,
    ));
    expect(takedown.ref, startsWith('TD-'));
    expect(takedown.held, 3);
    expect(backend.forms.last['role'], 'owner');
  });

  test('a form field error names the field', () async {
    await expectLater(
      api.requestTakedown(const TakedownRequest(domain: 'nope', name: 'A', email: 'a@b.co', confirm: true)),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'domain')),
    );
  });
}
