import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/shell/bottom_nav.dart';
import 'package:uiverse/shell/rail.dart';
import 'package:uiverse/theme/uiverse_colors.dart';

import '../shell/app_harness.dart';

/// The 3px accent bar drawn on [side] of the box around [label], if any.
BorderSide? _bar(WidgetTester tester, Finder scope, String label, {required bool left}) {
  final boxes = find.ancestor(
    of: find.descendant(of: scope, matching: find.text(label)),
    matching: find.byType(Container),
  );
  for (final e in boxes.evaluate()) {
    final d = (e.widget as Container).decoration;
    if (d is BoxDecoration && d.border is Border) {
      final b = d.border! as Border;
      final side = left ? b.left : b.top;
      if (side.width == 3) return side;
    }
  }
  return null;
}

void main() {
  testWidgets('Rail marks the active item with a 3px accent bar, not colour alone', (tester) async {
    await pumpApp(tester, width: 1024, location: '/palettes');
    final accent = UiverseColors.light.accent;
    final rail = find.byType(Rail);
    expect(_bar(tester, rail, 'Palettes', left: true)?.color, accent);
    expect(_bar(tester, rail, 'Home', left: true)?.color, isNot(accent));
  });

  testWidgets('BottomNav marks the active tab with a 3px accent bar', (tester) async {
    await pumpApp(tester, width: 390, location: '/explore');
    final accent = UiverseColors.light.accent;
    final nav = find.byType(BottomNav);
    expect(_bar(tester, nav, 'Explore', left: false)?.color, accent);
    expect(_bar(tester, nav, 'Home', left: false)?.color, isNot(accent));
  });

  testWidgets('More menu marks the active entry: selected + 3px accent bar', (tester) async {
    final h = tester.ensureSemantics();
    await pumpApp(tester, width: 1280, location: '/pricing');
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    final accent = UiverseColors.light.accent;
    final menu = find.byType(Overlay).first;
    expect(_bar(tester, menu, 'Pricing', left: true)?.color, accent);
    expect(_bar(tester, menu, 'Creators', left: true)?.color, isNot(accent));
    expect(tester.getSemantics(find.text('Pricing').last), isSemantics(isSelected: true, isLink: true));
    expect(tester.getSemantics(find.text('Creators')), isNot(isSemantics(isSelected: true)));
    expect(tester.getSize(find.text('Creators')).height, lessThan(48));
    expect(
      tester.getSize(find.ancestor(of: find.text('Creators'), matching: find.byType(Container)).first).height,
      greaterThanOrEqualTo(48),
    );
    h.dispose();
  });
}
