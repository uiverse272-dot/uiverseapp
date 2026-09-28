import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/screens/saved/saved_screen.dart';
import 'package:uiverse/state/saves.dart';

import '../search/discovery_harness.dart';

Map<String, Object> _prefs(List<(String, String)> saves, {List<SaveCollection> extra = const []}) => {
      kSavesKey: jsonEncode(SavesState(
        saves: [for (final (slug, col) in saves) SaveEntry(slug: slug, collectionId: col, at: 1)],
        collections: [...kDefaultCollections, ...extra],
      ).toJson()),
    };

final Finder _nameInput =
    find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Collection name');

void main() {
  test('savedItems maps saves to items, per collection, skipping unknown slugs', () {
    const s = SavesState(saves: [
      SaveEntry(slug: 's001-ledgerly-homepage', collectionId: 'recent', at: 2),
      SaveEntry(slug: 'gone', collectionId: 'recent', at: 1),
      SaveEntry(slug: 'c0011-ledgerly-navbar', collectionId: 'mood', at: 0),
    ]);
    expect(savedItems(s, kAllCollections).map((i) => i.slug), ['s001-ledgerly-homepage', 'c0011-ledgerly-navbar']);
    expect(savedItems(s, 'mood').map((i) => i.slug), ['c0011-ledgerly-navbar']);
  });

  for (final double width in <double>[390, 1024]) {
    testWidgets('empty state with nothing saved ($width)', (tester) async {
      await pumpDiscovery(tester, width: width, location: '/saved');
      expect(find.text('Saved'), findsWidgets);
      expect(find.text('All 0'), findsOneWidget);
      expect(find.text('Recently saved 0'), findsOneWidget);
      expect(find.text('New collection'), findsOneWidget);
      expect(find.text('Nothing saved here yet'), findsOneWidget);
      expect(find.text('Tap the bookmark under any card to save it here.'), findsOneWidget);
    });
  }

  testWidgets('collection pills hug their label and share a row', (tester) async {
    await pumpDiscovery(tester, width: 1024, location: '/saved');
    final all = tester.getRect(find.text('All 0'));
    final recent = tester.getRect(find.text('Recently saved 0'));
    expect(tester.getSize(find.ancestor(of: find.text('All 0'), matching: find.byType(AnimatedContainer))).width,
        lessThan(200));
    expect(recent.top, all.top);
  });

  testWidgets('"Browse the feed" goes home', (tester) async {
    final app = await pumpDiscovery(tester, location: '/saved');
    await tester.tap(find.text('Browse the feed'));
    await tester.pumpAndSettle();
    expect(locationOf(app.router), '/');
  });

  testWidgets('shows saved items and filters by collection', (tester) async {
    await pumpDiscovery(
      tester,
      width: 1024,
      location: '/saved',
      prefs: _prefs(
        [('s001-ledgerly-homepage', 'recent'), ('s002-ledgerly-spend-overview', 'mood')],
        extra: const [SaveCollection(id: 'mood', name: 'Mood')],
      ),
    );
    expect(find.text('All 2'), findsOneWidget);
    expect(find.text('Recently saved 1'), findsOneWidget);
    expect(find.text('Mood 1'), findsOneWidget);
    expect(find.text('Homepage'), findsOneWidget);
    expect(find.text('Spend overview'), findsOneWidget);
    expect(find.text('Nothing saved here yet'), findsNothing);

    await tester.tap(find.text('Mood 1'));
    await tester.pumpAndSettle();
    expect(find.text('Homepage'), findsNothing);
    expect(find.text('Spend overview'), findsOneWidget);
  });

  testWidgets('New collection opens an input and creates the collection', (tester) async {
    final app = await pumpDiscovery(tester, location: '/saved');
    await tester.tap(find.text('New collection'));
    await tester.pumpAndSettle();
    expect(find.text('New collection'), findsNothing);
    expect(_nameInput, findsOneWidget);

    await tester.enterText(_nameInput, '  Moodboard ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Moodboard 0'), findsOneWidget);
    expect(find.text('New collection'), findsOneWidget);
    expect(app.prefs.getString(kSavesKey), contains('"name":"Moodboard"'));
  });

  testWidgets('an empty name creates nothing', (tester) async {
    await pumpDiscovery(tester, location: '/saved');
    await tester.tap(find.text('New collection'));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('New collection'), findsOneWidget);
    expect(find.textContaining(RegExp(r' 0$')), findsNWidgets(2));
  });
}
