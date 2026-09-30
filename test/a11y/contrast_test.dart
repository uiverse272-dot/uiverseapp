import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/theme/uiverse_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [('light', UiverseColors.light), ('dark', UiverseColors.dark)]) {
    group('$name contrast (§14)', () {
      test('text, text-2 and text-3 reach AA (4.5) on bg and surface', () {
        for (final fg in [c.text, c.text2, c.text3]) {
          expect(_contrast(fg, c.bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(fg, c.surface), greaterThanOrEqualTo(4.5));
        }
      });

      test('accent-fg on accent and on-signal on signal reach AA', () {
        expect(_contrast(c.accentFg, c.accent), greaterThanOrEqualTo(4.5));
        expect(_contrast(c.onSignal, c.signal), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('light text-3 is the darkened #6f6a5c', () {
    expect(UiverseColors.light.text3, const Color(0xFF6F6A5C));
  });
}
