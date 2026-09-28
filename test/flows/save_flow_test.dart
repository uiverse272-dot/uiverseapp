import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/detail/detail_screen.dart';
import 'package:uiverse/router/detail.dart';
import 'package:uiverse/screens/saved/saved_screen.dart';
import 'package:uiverse/shell/bottom_nav.dart';
import 'package:uiverse/shell/navbar.dart';
import 'package:uiverse/shell/rail.dart';
import 'package:uiverse/state/saves.dart';
import 'package:uiverse/widgets/feed/feed_card.dart';

import 'flow_harness.dart';

/// The "New collection…" field inside the save toast's picker.
final Finder newCollectionField = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'New collection…',
);

void main() {
  for (final double width in <double>[390, 1024]) {
    testWidgets('feed → detail → save → Move to… new collection → Saved ($width)', (tester) async {
      final app = await pumpFlowApp(tester, width: width, location: '/web');
      final Item item = tester.widget<FeedCard>(find.byType(FeedCard).first).item;
      Finder card() => find.ancestor(of: find.text(item.title).first, matching: find.byType(FeedCard));

      // Feed → detail (full-screen on phones, sheet over the feed on tablets).
      await tester.tap(inside(find.byType(FeedCard).first, find.text(item.title)));
      await tester.pumpAndSettle();
      expect(find.byType(DetailOverlay), findsOneWidget);
      expect(find.byType(DetailScreen), findsOneWidget);
      expect(app.router.state.uri.path, '/screen/${item.slug}');

      // Save from the detail rail.
      final Finder save = inside(find.byType(DetailScreen), find.text('Save'));
      await tapVisible(tester, save.first);
      expect(find.text('Saved to $kRecentCollectionName'), findsOneWidget);
      expect(app.container.read(savesProvider).isSaved(item.slug), isTrue);

      // Toast → Move to… → New collection.
      await tester.tap(find.text('Move to…'));
      await tester.pumpAndSettle();
      expect(find.text('Move to collection'), findsOneWidget);
      await tester.enterText(newCollectionField, 'Moodboard');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Move to collection'), findsNothing); // toast closed
      final SavesState saves = app.container.read(savesProvider);
      expect(saves.collectionName('moodboard'), 'Moodboard');
      expect(saves.savesIn('moodboard').map((e) => e.slug), [item.slug]);
      expect(inside(find.byType(DetailScreen), find.text('Saved')), findsWidgets);

      // Close the detail: the card underneath shows the saved state.
      await tester.tap(find.bySemanticsLabel('Close').last);
      await tester.pumpAndSettle();
      expect(find.byType(DetailOverlay), findsNothing);
      expect(app.router.state.uri.path, '/web');
      expect(inside(card(), find.bySemanticsLabel('Remove from saves')), findsOneWidget);

      // Saved screen: the item sits under the new collection's pill.
      final Finder nav = find.byType(width >= 768 ? Rail : BottomNav);
      await tester.tap(inside(nav, find.text('Saved')));
      await tester.pumpAndSettle();
      expect(find.byType(SavedScreen), findsOneWidget);
      expect(find.bySemanticsLabel('All 1'), findsOneWidget);
      expect(find.bySemanticsLabel('$kRecentCollectionName 0'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Moodboard 1'));
      await tester.pumpAndSettle();
      expect(find.text(item.title), findsOneWidget);
      expect(find.byType(FeedCard), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('$kRecentCollectionName 0'));
      await tester.pumpAndSettle();
      expect(find.byType(FeedCard), findsNothing);
      expect(find.text('Nothing saved here yet'), findsOneWidget);
    });
  }

  testWidgets('unsaving from the feed card updates Saved counts', (tester) async {
    final app = await pumpFlowApp(tester, width: 1024, location: '/web');
    final Item item = tester.widget<FeedCard>(find.byType(FeedCard).first).item;
    final Finder card = find.byType(FeedCard).first;

    await tester.tap(inside(card, find.bySemanticsLabel('Save')));
    await tester.pumpAndSettle();
    expect(find.text('Saved to $kRecentCollectionName'), findsOneWidget);
    expect(inside(find.byType(Navbar), find.bySemanticsLabel('Saved, 1')), findsOneWidget);

    await tester.tap(inside(card, find.bySemanticsLabel('Remove from saves')));
    await tester.pumpAndSettle();
    expect(find.text('Removed'), findsOneWidget);
    expect(find.text('Move to…'), findsNothing);
    expect(app.container.read(savesProvider).isSaved(item.slug), isFalse);
  });
}
