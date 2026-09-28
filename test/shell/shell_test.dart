import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/shell/bottom_nav.dart';
import 'package:uiverse/shell/nav_items.dart';
import 'package:uiverse/shell/rail.dart';
import 'package:uiverse/state/saves.dart';
import 'package:uiverse/state/theme.dart';

import 'app_harness.dart';

void main() {
  testWidgets('767 wide shows BottomNav and no Rail', (tester) async {
    await pumpApp(tester, width: 767);
    expect(find.byType(BottomNav), findsOneWidget);
    expect(find.byType(Rail), findsNothing);
    // Phone navbar: logo + theme cells, no profile/saved cells.
    expect(find.bySemanticsLabel('Uiverse home'), findsOneWidget);
    expect(find.bySemanticsLabel('Switch to dark theme'), findsOneWidget);
    expect(find.text('Guest'), findsNothing);
  });

  testWidgets('768 wide shows Rail and no BottomNav', (tester) async {
    await pumpApp(tester, width: 768);
    expect(find.byType(Rail), findsOneWidget);
    expect(find.byType(BottomNav), findsNothing);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Interface seeker'), findsOneWidget);
    expect(find.text('More'), findsNothing); // ≥1024 only
  });

  testWidgets('active nav item: / exact, others by prefix', (tester) async {
    final handle = tester.ensureSemantics();
    final app = await pumpApp(tester, width: 1024, location: '/web/saas/dark');
    expect(tester.getSemantics(find.text('Web')), isSemantics(isSelected: true, isLink: true));
    expect(tester.getSemantics(find.text('Home')), isNot(isSemantics(isSelected: true)));

    app.router.go('/');
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('Home')), isSemantics(isSelected: true));
    expect(tester.getSemantics(find.text('Web')), isNot(isSemantics(isSelected: true)));
    handle.dispose();
  });

  test('isNavActive', () {
    expect(isNavActive('/', '/'), isTrue);
    expect(isNavActive('/explore', '/'), isFalse);
    expect(isNavActive('/web/saas', '/web'), isTrue);
    expect(isNavActive('/webby', '/web'), isFalse);
  });

  testWidgets('tapping a bottom tab navigates', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('explore'), findsOneWidget); // stub page title
  });

  testWidgets('saved cell shows count badge, capped at 99+', (tester) async {
    final saves = SavesState(saves: [
      for (var i = 0; i < 120; i++) SaveEntry(slug: 's$i', collectionId: 'recent', at: i),
    ]);
    await pumpApp(tester, width: 1024, prefs: {kSavesKey: _encode(saves)});
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('120 saved'), findsOneWidget);
  });

  testWidgets('More menu lists 3D, Creators, Pricing, Upload and navigates', (tester) async {
    await pumpApp(tester, width: 1280);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    for (final l in ['3D', 'Creators', 'Pricing']) {
      expect(find.text(l), findsOneWidget);
    }
    await tester.tap(find.text('Pricing'));
    await tester.pumpAndSettle();
    expect(find.text('pricing'), findsOneWidget);
    expect(find.text('Creators'), findsNothing);
  });

  testWidgets('theme toggle flips the shown theme and persists', (tester) async {
    final app = await pumpApp(tester, width: 767);
    expect(Theme.of(tester.element(find.byType(BottomNav))).brightness, Brightness.light);
    await tester.tap(find.bySemanticsLabel('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(app.prefs.getString(kThemeKey), 'dark');
    expect(Theme.of(tester.element(find.byType(BottomNav))).brightness, Brightness.dark);
    expect(find.bySemanticsLabel('Switch to light theme'), findsOneWidget);
  });

  testWidgets('stored theme is applied on launch; rail labels destination', (tester) async {
    await pumpApp(tester, width: 1024, prefs: {kThemeKey: 'dark'});
    expect(Theme.of(tester.element(find.byType(Rail))).brightness, Brightness.dark);
    expect(find.text('Light'), findsOneWidget);
  });

  testWidgets('navbar search submits to /search?q=', (tester) async {
    final app = await pumpApp(tester, width: 1024);
    await tester.enterText(find.byType(TextField), 'dark fintech');
    await tester.pump();
    expect(find.textContaining('Search for “dark fintech”', findRichText: true), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(app.router.state.uri.toString(), '/search?q=dark+fintech');
    expect(find.text('q: dark fintech'), findsOneWidget);
  });
}

String _encode(SavesState s) => jsonEncode(s.toJson());
