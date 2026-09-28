import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/state/saves.dart';

import 'state_harness.dart';

/// Exactly what the web store writes to localStorage.
const _webJson =
    '{"saves":[{"slug":"c0011-ledgerly-navbar","collectionId":"recent","at":1759000000000},'
    '{"slug":"s001-ledgerly-homepage","collectionId":"inspo","at":1758000000000,"note":"hero"}],'
    '"collections":[{"id":"recent","name":"Recently saved","sections":[]},'
    '{"id":"inspo","name":"Inspo","sections":["hero","pricing"]}]}';

void main() {
  final at = DateTime.utc(2026, 9, 28, 12);

  test('reads web-shaped JSON and writes it back unchanged', () async {
    final (c, prefs) = await makeContainer(values: {kSavesKey: _webJson});
    final s = c.read(savesProvider);
    expect(s.count, 2);
    expect(s.saves.last.note, 'hero');
    expect(s.collections[1].sections, ['hero', 'pricing']);
    expect(s.savesIn('inspo').single.slug, 's001-ledgerly-homepage');
    expect(jsonEncode(s.toJson()), _webJson);

    c.read(savesProvider.notifier).toggle('x');
    final stored = jsonDecode(prefs.getString(kSavesKey)!) as Map<String, Object?>;
    expect((stored['saves']! as List<Object?>).length, 3);
    expect((stored['collections']! as List<Object?>).length, 2);
  });

  test('empty storage has the default "Recently saved" collection', () async {
    final (c, _) = await makeContainer();
    final s = c.read(savesProvider);
    expect(s.saves, isEmpty);
    expect(s.collections.single.id, 'recent');
    expect(s.collections.single.name, 'Recently saved');
  });

  test('corrupt storage falls back to empty', () async {
    final (c, _) = await makeContainer(values: {kSavesKey: '{nope'});
    expect(c.read(savesProvider).count, 0);
  });

  test('toggle prepends, returns collection name, then removes', () async {
    final (c, _) = await makeContainer(clock: () => at);
    final n = c.read(savesProvider.notifier);
    expect(n.toggle('a'), 'Recently saved');
    expect(n.toggle('b'), 'Recently saved');
    final s = c.read(savesProvider);
    expect(s.saves.map((e) => e.slug), ['b', 'a']);
    expect(s.saves.first.at, at.millisecondsSinceEpoch);
    expect(n.isSaved('a'), isTrue);

    expect(n.toggle('a'), isNull);
    expect(c.read(savesProvider).isSaved('a'), isFalse);
    expect(c.read(savesProvider).count, 1);
  });

  test('move re-files a save at the top', () async {
    final (c, _) = await makeContainer();
    final n = c.read(savesProvider.notifier)
      ..toggle('a')
      ..toggle('b');
    final id = n.createCollection('Dark dashboards');
    n.move('a', id);
    final s = c.read(savesProvider);
    expect(s.saves.first.slug, 'a');
    expect(s.saves.first.collectionId, 'dark-dashboards');
    expect(s.savesIn('dark-dashboards').length, 1);
    expect(s.countIn('recent'), 1);
    expect(s.count, 2);
  });

  test('createCollection is idempotent by id', () async {
    final (c, _) = await makeContainer();
    final n = c.read(savesProvider.notifier);
    expect(n.createCollection('Inspo'), 'inspo');
    expect(n.createCollection('INSPO'), 'inspo');
    expect(c.read(savesProvider).collections.length, 2);
    expect(c.read(savesProvider).collectionName('inspo'), 'Inspo');
  });

  test('empty slug falls back to a timestamp id', () async {
    final (c, _) = await makeContainer(clock: () => at);
    expect(c.read(savesProvider.notifier).createCollection(''),
        'c${at.millisecondsSinceEpoch}');
  });

  group('slugifyCollection', () {
    test('matches the web rule', () {
      expect(slugifyCollection('Dark Fintech / Dashboards!'), 'dark-fintech-dashboards-');
      expect(slugifyCollection('  Hero  sections '), '-hero-sections-');
      expect(slugifyCollection('Café 2026'), 'caf-2026');
      expect(slugifyCollection('!!!'), '-');
      expect(slugifyCollection(''), isNull);
    });

    test('caps at 40 characters', () {
      final id = slugifyCollection('a' * 60)!;
      expect(id.length, 40);
    });
  });
}
