import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/state/saves.dart';

import 'state_harness.dart';

/// What the web store and this app wrote before boards.
const _beforeBoards =
    '{"saves":[{"slug":"a","collectionId":"refs","at":2,"note":"hero"},'
    '{"slug":"b","collectionId":"recent","at":1},'
    '{"slug":"c","collectionId":"gone","at":0}],'
    '"collections":[{"id":"recent","name":"Recently saved","sections":[]},'
    '{"id":"refs","name":"Refs","sections":["hero"]}]}';

/// Exactly what the web store writes to localStorage today.
const _webJson =
    '{"saves":[{"slug":"a","at":2,"note":"hero"},{"slug":"b","at":1}],'
    '"collections":[{"id":"refs","name":"Refs","description":"Client work"}],'
    '"pins":[{"slug":"a","collectionId":"refs","at":2}]}';

void main() {
  final at = DateTime.utc(2026, 9, 28, 12);

  test('reads web-shaped JSON and writes it back unchanged', () async {
    final (c, prefs) = await makeContainer(values: {kSavesKey: _webJson});
    final s = c.read(savesProvider);
    expect(s.count, 2);
    expect(s.saves.first.note, 'hero');
    expect(s.savesIn('refs').single.slug, 'a');
    expect(s.unsorted.single.slug, 'b');
    expect(jsonEncode(s.toJson()), _webJson);

    c.read(savesProvider.notifier).toggle('x');
    final stored = jsonDecode(prefs.getString(kSavesKey)!) as Map<String, Object?>;
    expect((stored['saves']! as List<Object?>).length, 3);
    expect((stored['pins']! as List<Object?>).length, 1);
  });

  test('reads the shape before boards: a collection becomes a pin', () async {
    final (c, _) = await makeContainer(values: {kSavesKey: _beforeBoards});
    final s = c.read(savesProvider);
    expect(s.collections, const [SaveCollection(id: 'refs', name: 'Refs')]);
    expect(s.saves, const [
      SaveEntry(slug: 'a', at: 2, note: 'hero'),
      SaveEntry(slug: 'b', at: 1),
      SaveEntry(slug: 'c', at: 0),
    ]);
    expect(s.pins, const [SavePin(slug: 'a', collectionId: 'refs', at: 2)]);
  });

  test('server payload parses, keeping designs the app has no card for', () {
    final s = SavesState.fromJson({
      'saves': [
        {'slug': 'web-only-capture', 'at': 3, 'note': ''},
      ],
      'collections': [
        {'id': 'refs', 'name': 'Refs', 'description': ''},
      ],
      'pins': <Object?>[],
    });
    expect(s.saves.single, const SaveEntry(slug: 'web-only-capture', at: 3));
    expect(s.collections.single.description, isNull);
  });

  test('bad entries are dropped, not trusted', () {
    final s = SavesState.fromJson({
      'saves': [
        'nope',
        {'at': 1},
        {'slug': 'a', 'at': 'soon'},
      ],
      'collections': [
        {'id': 'all', 'name': 'All'},
        {'id': 'x'},
      ],
      'pins': [
        {'slug': 'a'},
      ],
    });
    expect(s.saves, const [SaveEntry(slug: 'a', at: 0)]);
    expect(s.collections, isEmpty);
    expect(s.pins, isEmpty);
  });

  test('empty storage has no boards', () async {
    final (c, _) = await makeContainer();
    expect(c.read(savesProvider), const SavesState());
  });

  test('corrupt storage falls back to empty', () async {
    final (c, _) = await makeContainer(values: {kSavesKey: '{nope'});
    expect(c.read(savesProvider).count, 0);
  });

  test('toggle prepends, says it saved, then removes', () async {
    final (c, _) = await makeContainer(clock: () => at);
    final n = c.read(savesProvider.notifier);
    expect(n.toggle('a'), isTrue);
    expect(n.toggle('b'), isTrue);
    final s = c.read(savesProvider);
    expect(s.saves.map((e) => e.slug), ['b', 'a']);
    expect(s.saves.first.at, at.millisecondsSinceEpoch);
    expect(n.isSaved('a'), isTrue);

    expect(n.toggle('a'), isFalse);
    expect(c.read(savesProvider).isSaved('a'), isFalse);
    expect(c.read(savesProvider).count, 1);
  });

  test('pins one design to many boards; unsaving takes it off all of them', () async {
    final (c, _) = await makeContainer();
    final n = c.read(savesProvider.notifier);
    final a = n.createCollection('Client A');
    final b = n.createCollection('Client B');
    n
      ..pin('x', a) // pinning saves it
      ..pin('x', b);
    expect(n.isSaved('x'), isTrue);
    expect(c.read(savesProvider).pins.map((p) => p.collectionId), [b, a]);

    n.pin('x', a, pinned: false);
    expect(c.read(savesProvider).pins.map((p) => p.collectionId), [b]);
    expect(n.toggle('x'), isFalse);
    expect(c.read(savesProvider).saves, isEmpty);
    expect(c.read(savesProvider).pins, isEmpty);
  });

  test('pinning to a missing board changes nothing', () async {
    final (c, _) = await makeContainer();
    c.read(savesProvider.notifier).pin('x', 'gone');
    expect(c.read(savesProvider).count, 0);
  });

  test('deleting a board keeps its designs saved', () async {
    final (c, _) = await makeContainer();
    final n = c.read(savesProvider.notifier);
    final id = n.createCollection('Old');
    n
      ..pin('x', id)
      ..deleteCollection(id);
    final s = c.read(savesProvider);
    expect(s.collections, isEmpty);
    expect(s.pins, isEmpty);
    expect(s.saves.single.slug, 'x');
  });

  test('renaming keeps the id', () async {
    final (c, _) = await makeContainer();
    final n = c.read(savesProvider.notifier);
    final id = n.createCollection('Old');
    n.updateCollection(id, '  New ', description: ' Later ');
    expect(c.read(savesProvider).collections.single,
        const SaveCollection(id: 'old', name: 'New', description: 'Later'));
    n.updateCollection(id, '   ');
    expect(c.read(savesProvider).collectionName(id), 'New');
  });

  test('keeps a note per saved design and persists it', () async {
    final (c, prefs) = await makeContainer();
    final n = c.read(savesProvider.notifier)
      ..toggle('x')
      ..setNote('x', '  spacing  ')
      ..setNote('y', 'not saved');
    expect(c.read(savesProvider).saves.single.note, 'spacing');
    expect(prefs.getString(kSavesKey), contains('"note":"spacing"'));

    n.setNote('x', '');
    expect(c.read(savesProvider).saves.single.note, isNull);
  });

  test('ops survive a JSON round trip', () {
    const ops = <SaveOp>[
      SetSaved('a', saved: true, at: 1),
      SetPinned('a', 'b', pinned: false, at: 2),
      CreateCollection('b', 'B', description: 'd'),
      UpdateCollection('b', 'C'),
      DeleteCollection('b'),
      SetNote('a', 'n'),
    ];
    for (final op in ops) {
      expect(SaveOp.fromJson(op.toJson())?.toJson(), op.toJson());
    }
    expect(SaveOp.fromJson({'type': 'set', 'slug': 1}), isNull);
    expect(SaveOp.fromJson({'type': 'wipe'}), isNull);
  });

  test('createCollection is idempotent by id', () async {
    final (c, _) = await makeContainer();
    final n = c.read(savesProvider.notifier);
    expect(n.createCollection('Inspo'), 'inspo');
    expect(n.createCollection('INSPO'), 'inspo');
    expect(c.read(savesProvider).collections.length, 1);
    expect(c.read(savesProvider).collectionName('inspo'), 'Inspo');
  });

  test('empty slug falls back to a timestamp id', () async {
    final (c, _) = await makeContainer(clock: () => at);
    expect(c.read(savesProvider.notifier).createCollection(''), 'c${at.millisecondsSinceEpoch}');
  });

  group('slugifyCollection', () {
    test('matches the web rule', () {
      expect(slugifyCollection('Dark Fintech / Dashboards!'), 'dark-fintech-dashboards');
      expect(slugifyCollection('  Hero  sections '), 'hero-sections');
      expect(slugifyCollection('Café 2026'), 'caf-2026');
      expect(slugifyCollection('!!!'), isNull);
      expect(slugifyCollection(''), isNull);
    });

    test('never names a board after a view of the saves', () {
      expect(slugifyCollection('All'), 'all-board');
      expect(slugifyCollection('Unsorted'), 'unsorted-board');
      expect(slugifyCollection('Recent'), 'recent-board');
    });

    test('caps at 40 characters', () {
      final id = slugifyCollection('a' * 60)!;
      expect(id.length, 40);
    });
  });
}
