import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// In-memory stand-in for the web backend in `docs/api-v1.md`.
///
/// Mirrors `src/lib/saves/db.ts` on its own rather than sharing the app's
/// code, so a misread rule shows up as a failing test. No Flutter imports:
/// `tool/fake_server.dart` runs this under plain `dart run`.
class FakeBackend {
  FakeBackend({this.unknownSlugPrefix = 'unknown'});

  /// Slugs starting with this are "not in the web catalog".
  final String unknownSlugPrefix;

  final Map<String, FakeAccount> _accounts = {};
  final Map<String, FakeAccount> _sessions = {};
  final Map<String, ({String c, FakeAccount account})> _oneTime = {};
  final Queue<http.Response> _forced = Queue();
  final Random _random = Random();

  /// Every request as `METHOD /path`, oldest first.
  final List<String> requests = [];

  /// Bodies of accepted form posts.
  final List<Map<String, Object?>> forms = [];

  /// Bodies of ops, in arrival order.
  final List<Map<String, Object?>> ops = [];

  /// Emails asked for a sign-in link, with their challenge.
  final List<({String email, String c})> links = [];

  /// Sessions younger than this may delete; flip to false to get 400.
  bool sessionFresh = true;

  /// The next request gets [response] instead of being handled.
  void forceNext(http.Response response) => _forced.add(response);

  FakeAccount account(String email) =>
      _accounts.putIfAbsent(email, () => FakeAccount('u${_accounts.length + 1}', email));

  bool hasAccount(String email) => _accounts.containsKey(email);

  /// What `/api/mobile/done` does: a token only the holder of [c]'s verifier
  /// can redeem.
  String issueToken(String email, String c) {
    final token = 'ott-${_random.nextInt(1 << 32)}';
    _oneTime[token] = (c: c, account: account(email));
    return token;
  }

  /// A live session, for tests that skip the sign-in steps.
  String sessionFor(String email) {
    final token = 'sess-${_random.nextInt(1 << 32)}';
    _sessions[token] = account(email);
    return token;
  }

  Future<http.Response> handle(http.Request r) async {
    requests.add('${r.method} ${r.url.path}');
    if (_forced.isNotEmpty) return _forced.removeFirst();
    final Map<String, Object?> body = r.body.isEmpty ? {} : (jsonDecode(r.body) as Map<String, Object?>);
    final FakeAccount? me = _sessions[(r.headers['Authorization'] ?? r.headers['authorization'] ?? '').replaceFirst('Bearer ', '')];
    return switch ('${r.method} ${r.url.path}') {
      'POST /api/mobile/magic-link' => _magicLink(body),
      'POST /api/mobile/exchange' => _exchange(body),
      'POST /api/v1/finds' => _find(body),
      'POST /api/v1/takedowns' => _takedown(body),
      _ when me == null => _error(401, 'signed-out'),
      'POST /api/auth/sign-out' => _signOut(r),
      'POST /api/auth/delete-user' => _deleteUser(me),
      'GET /api/v1/saves' => _json(200, me.toJson()),
      'POST /api/v1/saves/sync' => _sync(me, body),
      'POST /api/v1/saves/op' => _op(me, body),
      _ => _error(404, 'not-found'),
    };
  }

  http.Response _magicLink(Map<String, Object?> b) {
    links.add((email: b['email']! as String, c: b['c']! as String));
    return _json(200, {'ok': true});
  }

  http.Response _exchange(Map<String, Object?> b) {
    final entry = _oneTime.remove(b['token']);
    if (entry == null) return _error(401, 'invalid-token');
    final hash = base64Url.encode(sha256.convert(utf8.encode(b['verifier']! as String)).bytes).replaceAll('=', '');
    if (hash != entry.c) return _error(401, 'invalid-token');
    final token = sessionFor(entry.account.email);
    return _json(200, {
      'token': token,
      'user': {'id': entry.account.id, 'email': entry.account.email, 'name': null, 'image': null},
    });
  }

  http.Response _signOut(http.Request r) {
    _sessions.removeWhere((token, _) => (r.headers['Authorization'] ?? '').endsWith(token));
    return _json(200, {'success': true});
  }

  http.Response _deleteUser(FakeAccount me) {
    if (!sessionFresh) return http.Response(jsonEncode({'code': 'SESSION_EXPIRED'}), 400);
    _accounts.remove(me.email);
    _sessions.removeWhere((_, a) => a == me);
    return _json(200, {'success': true});
  }

  http.Response _sync(FakeAccount me, Map<String, Object?> b) {
    final guest = (b['guest']! as Map<String, Object?>);
    for (final c in _maps(guest['collections'])) {
      if (!_validBoard(c['id'], c['name']) || me.board(c['id']! as String) != null) continue;
      me.collections.add({'id': c['id'], 'name': c['name'], 'description': c['description'] ?? ''});
    }
    for (final s in _maps(guest['saves'])) {
      final slug = s['slug']! as String;
      if (slug.startsWith(unknownSlugPrefix) || me.save(slug) != null) continue;
      me.saves.add({'slug': slug, 'at': s['at'], 'note': s['note'] ?? ''});
    }
    for (final p in _maps(guest['pins'])) {
      if (me.board(p['collectionId']! as String) == null || me.save(p['slug']! as String) == null) continue;
      if (me.pin(p['slug']! as String, p['collectionId']! as String) == null) me.pins.add(p);
    }
    return _json(200, me.toJson());
  }

  http.Response _op(FakeAccount me, Map<String, Object?> o) {
    ops.add(o);
    final String? slug = o['slug'] as String?;
    final int at = (o['at'] as num?)?.toInt() ?? 0;
    switch (o['type']) {
      case 'set' when o['saved'] == true:
        if (slug!.startsWith(unknownSlugPrefix)) return _error(422, 'unknown-item');
        if (me.save(slug) == null) me.saves.insert(0, {'slug': slug, 'at': at, 'note': ''});
      case 'set':
        me.saves.removeWhere((s) => s['slug'] == slug);
        me.pins.removeWhere((p) => p['slug'] == slug);
      case 'pin' when o['pinned'] == true:
        final id = o['collectionId']! as String;
        if (me.board(id) == null) return _error(422, 'unknown-collection');
        if (slug!.startsWith(unknownSlugPrefix)) return _error(422, 'unknown-item');
        if (me.save(slug) == null) me.saves.insert(0, {'slug': slug, 'at': at, 'note': ''});
        if (me.pin(slug, id) == null) me.pins.insert(0, {'slug': slug, 'collectionId': id, 'at': at});
      case 'pin':
        me.pins.removeWhere((p) => p['slug'] == slug && p['collectionId'] == o['collectionId']);
      case 'create':
        if (!_validBoard(o['id'], o['name'])) return _error(422, 'invalid');
        if (me.board(o['id']! as String) == null) {
          me.collections.add({'id': o['id'], 'name': o['name'], 'description': o['description'] ?? ''});
        }
      case 'update':
        final board = me.board(o['id']! as String);
        if (board == null) return _error(422, 'unknown-collection');
        board
          ..['name'] = o['name']
          ..['description'] = o['description'] ?? '';
      case 'delete':
        me.collections.removeWhere((c) => c['id'] == o['id']);
        me.pins.removeWhere((p) => p['collectionId'] == o['id']);
      case 'note':
        me.save(slug!)?['note'] = o['note'];
      default:
        return _error(422, 'invalid');
    }
    return _json(200, {'ok': true});
  }

  http.Response _find(Map<String, Object?> b) {
    for (final field in ['title', 'creator']) {
      if ((b[field] as String? ?? '').trim().isEmpty) return _error(422, field);
    }
    if (!(b['email'] as String? ?? '').contains('@')) return _error(422, 'email');
    for (final field in ['url', 'imageUrl']) {
      if (!(b[field] as String? ?? '').startsWith('http')) return _error(422, field);
    }
    if (b['confirm'] != true) return _error(422, 'confirm');
    forms.add(b);
    return _json(200, {'ref': 'FD-20261101-ABC123', 'email': b['email']});
  }

  http.Response _takedown(Map<String, Object?> b) {
    if (!(b['domain'] as String? ?? '').contains('.')) return _error(422, 'domain');
    if ((b['name'] as String? ?? '').trim().isEmpty) return _error(422, 'name');
    if (!(b['email'] as String? ?? '').contains('@')) return _error(422, 'email');
    if (b['confirm'] != true) return _error(422, 'confirm');
    forms.add(b);
    return _json(200, {'ref': 'TD-20261101-ABC123', 'domain': b['domain'], 'email': b['email'], 'held': 3});
  }

  bool _validBoard(Object? id, Object? name) =>
      id is String &&
      RegExp(r'^[a-z0-9-]{1,40}$').hasMatch(id) &&
      !const {'all', 'unsorted', 'recent'}.contains(id) &&
      name is String &&
      name.trim().isNotEmpty;

  List<Map<String, Object?>> _maps(Object? list) => [
        for (final o in (list as List<Object?>?) ?? const <Object?>[]) (o! as Map<Object?, Object?>).cast(),
      ];

  http.Response _json(int status, Object body) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  http.Response _error(int status, String code) => _json(status, {'error': code});
}

/// One account's server-side saves.
class FakeAccount {
  FakeAccount(this.id, this.email);

  final String id;
  final String email;
  final List<Map<String, Object?>> saves = [];
  final List<Map<String, Object?>> collections = [];
  final List<Map<String, Object?>> pins = [];

  Map<String, Object?>? save(String slug) => _first(saves, (s) => s['slug'] == slug);
  Map<String, Object?>? board(String id) => _first(collections, (c) => c['id'] == id);
  Map<String, Object?>? pin(String slug, String id) =>
      _first(pins, (p) => p['slug'] == slug && p['collectionId'] == id);

  Map<String, Object?>? _first(List<Map<String, Object?>> list, bool Function(Map<String, Object?>) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }

  Map<String, Object?> toJson() => {'saves': saves, 'collections': collections, 'pins': pins};
}
