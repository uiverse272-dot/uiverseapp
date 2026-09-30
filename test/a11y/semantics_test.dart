import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/router/detail.dart';
import 'package:uiverse/shell/bottom_nav.dart';
import 'package:uiverse/shell/navbar.dart';
import 'package:uiverse/shell/rail.dart';

import '../shell/app_harness.dart';
import 'a11y_harness.dart';

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  group('every tappable has an accessible name (§14)', () {
    for (final w in kAuditWidths) {
      for (final r in kMainRoutes) {
        testWidgets('$r @ ${w.toInt()}', (tester) async {
          final h = tester.ensureSemantics();
          await pumpApp(tester, width: w, location: r);
          tester.view.physicalSize = Size(w, 2400);
          await settleTimers(tester);
          await expectLabeledTapTargets(tester);
          await _drain(tester);
          h.dispose();
        });
      }
    }
  });

  testWidgets('icon-only shell buttons carry the §14 labels', (tester) async {
    final h = tester.ensureSemantics();
    await pumpApp(tester, width: 390);
    expect(tester.getSemantics(find.bySemanticsLabel('Uiverse home')), isSemantics(isLink: true, hasTapAction: true));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Switch to dark theme')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    await pumpApp(tester, width: 1024);
    final saved = find.descendant(of: find.byType(Navbar), matching: find.bySemanticsLabel('Saved'));
    expect(tester.getSemantics(saved), isSemantics(isLink: true, hasTapAction: true));
    h.dispose();
  });

  testWidgets('active nav items expose selected on rail and bottom nav', (tester) async {
    final h = tester.ensureSemantics();
    await pumpApp(tester, width: 390, location: '/explore');
    final explore = find.descendant(of: find.byType(BottomNav), matching: find.text('Explore'));
    final home = find.descendant(of: find.byType(BottomNav), matching: find.text('Home'));
    expect(tester.getSemantics(explore), isSemantics(isSelected: true, isLink: true));
    expect(tester.getSemantics(home), isNot(isSemantics(isSelected: true)));

    await pumpApp(tester, width: 1024, location: '/palettes');
    final palettes = find.descendant(of: find.byType(Rail), matching: find.text('Palettes'));
    expect(tester.getSemantics(palettes), isSemantics(isSelected: true, isLink: true));
    h.dispose();
  });

  testWidgets('More menu exposes expanded', (tester) async {
    final h = tester.ensureSemantics();
    await pumpApp(tester, width: 1280, location: '/legal/takedown');
    final more = find.text('More');
    expect(tester.getSemantics(more), isSemantics(hasExpandedState: true, isExpanded: false));
    await _tap(tester, more);
    expect(tester.getSemantics(more), isSemantics(hasExpandedState: true, isExpanded: true));
    h.dispose();
  });

  testWidgets('card save toggles between "Save" and "Remove from saves"', (tester) async {
    final h = tester.ensureSemantics();
    await pumpApp(tester, width: 1024, location: '/web');
    final save = find.bySemanticsLabel('Save').first;
    expect(tester.getSemantics(save), isSemantics(hasToggledState: true, isToggled: false, hasTapAction: true));
    await _tap(tester, save);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Remove from saves').first),
      isSemantics(hasToggledState: true, isToggled: true, hasTapAction: true),
    );
    await _drain(tester);
    h.dispose();
  });

  testWidgets('filter Code toggle exposes toggled', (tester) async {
    final h = tester.ensureSemantics();
    await pumpApp(tester, width: 1024, location: '/web');
    final code = find.bySemanticsLabel('Code');
    expect(tester.getSemantics(code), isSemantics(hasToggledState: true, isToggled: false));
    await _tap(tester, code);
    expect(tester.getSemantics(find.bySemanticsLabel('Code')), isSemantics(hasToggledState: true, isToggled: true));
    h.dispose();
  });

  testWidgets('Pick of the week header buttons are labelled; details expose expanded', (tester) async {
    final h = tester.ensureSemantics();
    await pumpApp(tester, width: 1024);
    await settleTimers(tester);
    expect(find.bySemanticsLabel('Hide pick of the week'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Show details')),
      isSemantics(hasExpandedState: true, isExpanded: false, hasTapAction: true),
    );
    await _tap(tester, find.bySemanticsLabel('Show details'));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Show less')),
      isSemantics(hasExpandedState: true, isExpanded: true),
    );
    await _drain(tester);
    h.dispose();
  });

  testWidgets('detail device segments expose toggled; overlay close is labelled', (tester) async {
    final h = tester.ensureSemantics();
    final app = await pumpApp(tester, width: 1024, location: '/web');
    app.router.push<void>('/screen/s001-ledgerly-homepage', extra: DetailPresentation.overlay).ignore();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Close'), findsWidgets);
    final segments = ['Laptop', 'Tablet', 'Mobile'];
    for (final l in segments) {
      expect(tester.getSemantics(find.bySemanticsLabel(l)), isSemantics(hasToggledState: true, hasTapAction: true));
    }
    final on = segments.where(
      (l) => isSemantics(isToggled: true).matches(tester.getSemantics(find.bySemanticsLabel(l)), <dynamic, dynamic>{}),
    );
    expect(on, hasLength(1));
    h.dispose();
  });

  testWidgets('prompt dialog Include rows are checkboxes', (tester) async {
    final h = tester.ensureSemantics();
    await pumpApp(tester, width: 1024, location: '/screen/s001-ledgerly-homepage');
    await _tap(tester, find.text('Prompt'));
    expect(
      tester.getSemantics(find.text('Colour tokens')),
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    await tester.ensureVisible(find.text('Colour tokens'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Colour tokens'));
    expect(tester.getSemantics(find.text('Colour tokens')), isSemantics(hasCheckedState: true, isChecked: false));
    h.dispose();
  });
}
