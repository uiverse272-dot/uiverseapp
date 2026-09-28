import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/shell/rail.dart';
import 'package:uiverse/state/pick.dart';
import 'package:uiverse/state/saves.dart';
import 'package:uiverse/state/theme.dart';
import 'package:uiverse/widgets/feed/feed_card.dart';
import 'package:uiverse/widgets/save/save_toast.dart';

import 'flow_harness.dart';

const String kPickEyebrow = 'PICK OF THE WEEK';

final Finder newCollectionField = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'New collection…',
);

Brightness shownBrightness(WidgetTester tester) => Theme.of(tester.element(find.byType(Rail))).brightness;

/// Saves the [i]th feed card from its icon and opens "Move to…".
Future<Item> saveCardAndPick(WidgetTester tester, int i) async {
  final Finder card = find.byType(FeedCard).at(i);
  final Item item = tester.widget<FeedCard>(card).item;
  await tester.tap(inside(card, find.bySemanticsLabel('Save')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Move to…'));
  await tester.pumpAndSettle();
  return item;
}

void main() {
  testWidgets('theme, saves + collection and folded pick survive a restart', (tester) async {
    // 1. Theme → dark, fold Pick of the week (home, tablet).
    final app = await pumpFlowApp(tester, width: 1024, location: '/');
    expect(shownBrightness(tester), Brightness.light);
    await tester.tap(find.bySemanticsLabel('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(shownBrightness(tester), Brightness.dark);

    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();
    expect(find.text(kPickEyebrow), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Hide pick of the week'));
    await tester.pumpAndSettle();
    expect(find.text(kPickEyebrow), findsNothing);

    // 2. Save two items into a new collection.
    app.router.go('/web');
    await tester.pumpAndSettle();
    final Item a = await saveCardAndPick(tester, 0);
    await tester.enterText(newCollectionField, 'Keepers');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final Item b = await saveCardAndPick(tester, 1);
    await tester.tap(inside(find.byType(SaveToast), find.text('Keepers')));
    await tester.pumpAndSettle();
    expect(app.container.read(savesProvider).savesIn('keepers').map((e) => e.slug), [b.slug, a.slug]);

    // 3. Restart: a fresh store seeded with what was written.
    final Map<String, Object> stored = snapshotPrefs(app.prefs);
    expect(stored.keys, containsAll(<String>[kThemeKey, kSavesKey, kPickKey]));
    await pumpFlowApp(tester, width: 1024, location: '/', initial: stored);
    final SharedPreferences fresh = await SharedPreferences.getInstance();
    expect(identical(fresh, app.prefs), isFalse);

    expect(shownBrightness(tester), Brightness.dark);
    expect(find.bySemanticsLabel('Switch to light theme'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(kPickEyebrow), findsNothing);
    expect(find.text('Pick of the week'), findsOneWidget); // the folded tab

    await tester.tap(inside(find.byType(Rail), find.text('Saved')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('All 2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Keepers 2'));
    await tester.pumpAndSettle();
    expect(find.text(a.title), findsOneWidget);
    expect(find.text(b.title), findsOneWidget);
  });

  testWidgets('restarting with the same SharedPreferences instance restores state', (tester) async {
    final app = await pumpFlowApp(tester, width: 767, location: '/web');
    await tester.tap(find.bySemanticsLabel('Switch to dark theme'));
    await tester.pumpAndSettle();
    final Item a = await saveCardAndPick(tester, 0);
    await tester.enterText(newCollectionField, 'Later');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final again = await pumpFlowApp(tester, width: 767, location: '/saved', prefs: app.prefs);
    expect(find.bySemanticsLabel('Switch to light theme'), findsOneWidget);
    expect(again.container.read(savesProvider).savesIn('later').single.slug, a.slug);
    expect(find.bySemanticsLabel('Later 1'), findsOneWidget);
    expect(again.container.read(pickFoldedProvider), isFalse);
  });
}
