import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/shell/search_field.dart';
import 'package:uiverse/theme/uiverse_colors.dart';
import 'package:uiverse/theme/uiverse_theme.dart';

import '../shell/app_harness.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('light selection is solid signal under ink text (§14)', () {
    final t = uiverseTheme(Brightness.light).textSelectionTheme;
    expect(t.selectionColor, UiverseColors.light.signal);
    expect(_contrast(UiverseColors.light.text, UiverseColors.light.signal), greaterThanOrEqualTo(4.5));
  });

  test('dark selection keeps the light text readable', () {
    final c = UiverseColors.dark;
    final sel = uiverseTheme(Brightness.dark).textSelectionTheme.selectionColor!;
    expect(sel.withValues(alpha: 1), c.signal);
    for (final bg in [c.bg, c.surface, c.bgSubtle]) {
      expect(_contrast(c.text, Color.alphaBlend(sel, bg)), greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('the navbar field on the yellow cell uses a visible selection tint', (tester) async {
    await pumpApp(tester, width: 1024);
    final field = find.descendant(of: find.byType(SearchField), matching: find.byType(EditableText));
    await tester.tap(field); // TextField only passes a selection colour while focused
    await tester.pumpAndSettle();
    final sel = tester.widget<EditableText>(field).selectionColor!;
    expect(sel, isNot(UiverseColors.light.signal));
    expect(sel.a, lessThan(1));
  });
}
