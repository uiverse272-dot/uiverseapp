import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/widgets/feed/card_focus_overlay.dart';

import 'themed_harness.dart';

void main() {
  group('radialTargets', () {
    const screen = Size(400, 800);
    const margin = 34.0;

    final holds = <String, Offset>{
      'centre': const Offset(200, 400),
      'left edge': const Offset(10, 400),
      'right edge': const Offset(390, 400),
      'top edge': const Offset(200, 20),
      'top-left corner': const Offset(5, 5),
      'top-right corner': const Offset(395, 5),
      'bottom-left corner': const Offset(5, 795),
      'bottom-right corner': const Offset(395, 795),
    };

    for (final MapEntry(key: name, value: hold) in holds.entries) {
      test('spaces buttons evenly and on-screen at $name', () {
        final targets = radialTargets(hold: hold, count: 4, screen: screen, margin: margin);
        expect(targets, hasLength(4));

        final gaps = [for (var i = 1; i < targets.length; i++) (targets[i] - targets[i - 1]).distance];
        for (final gap in gaps) {
          expect(gap, closeTo(gaps.first, 0.5));
        }
        expect(gaps.first, greaterThan(52), reason: 'buttons must not overlap');

        for (final t in targets) {
          expect(t.dx, inInclusiveRange(margin - 0.01, screen.width - margin + 0.01));
          expect(t.dy, inInclusiveRange(margin - 0.01, screen.height - margin + 0.01));
        }
      });
    }

    test('keeps action order left to right when fanned below the finger', () {
      final up = radialTargets(hold: const Offset(200, 400), count: 4, screen: screen);
      final down = radialTargets(hold: const Offset(200, 20), count: 4, screen: screen);
      expect(up.first.dx, lessThan(up.last.dx));
      expect(down.first.dx, lessThan(down.last.dx));
      expect(down.first.dy, greaterThan(20));
    });
  });

  testWidgets('long-press fans actions, release elsewhere cancels', (tester) async {
    await pumpThemed(
      tester,
      Center(
        child: SizedBox(
          width: 200,
          height: 260,
          child: CardFocusOverlay(item: kItems.first, child: const ColoredBox(color: Color(0xFF888888))),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.byType(CardFocusOverlay)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    for (final label in ['Save', 'Open', 'Prompt', 'Share']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Share'), findsNothing);
  });

  testWidgets('dragging onto an action shows its label', (tester) async {
    await pumpThemed(
      tester,
      Center(
        child: SizedBox(
          width: 200,
          height: 260,
          child: CardFocusOverlay(item: kItems.first, child: const ColoredBox(color: Color(0xFF888888))),
        ),
      ),
    );

    final hold = tester.getCenter(find.byType(CardFocusOverlay));
    final gesture = await tester.startGesture(hold);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    final share = radialTargets(hold: hold, count: 4, screen: const Size(400, 900), margin: 34).last;
    await gesture.moveTo(share);
    await tester.pumpAndSettle();
    expect(find.text('Share'), findsOneWidget);

    await gesture.moveTo(hold);
    await tester.pumpAndSettle();
    expect(find.text('Share'), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
