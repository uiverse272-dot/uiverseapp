import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shell/app_harness.dart';
import 'a11y_harness.dart';

/// Pumps [location] at [width] with a tall view so most of the page is
/// built (and in the semantics tree), then lets load-time timers settle.
Future<void> _pumpTall(WidgetTester tester, double width, String location) async {
  await pumpApp(tester, width: width, location: location);
  tester.view.physicalSize = Size(width, 2400);
  await settleTimers(tester);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Runs out any toasts / pick timers so the test ends with no pending timers.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  group('every tappable is at least 48×48 (§14)', () {
    for (final w in kAuditWidths) {
      for (final r in kMainRoutes) {
        testWidgets('$r @ ${w.toInt()}', (tester) async {
          final h = tester.ensureSemantics();
          await _pumpTall(tester, w, r);
          await expectTapTargets48(tester);
          await _drain(tester);
          h.dispose();
        });
      }
    }
  });

  group('interactive states keep 48×48 targets', () {
    final states = <String, (double, String, Future<void> Function(WidgetTester))>{
      'More menu open': (1280, '/legal/takedown', (t) => _tap(t, find.text('More'))),
      'filter popover open (≥768)': (1024, '/web', (t) => _tap(t, find.text('Type'))),
      'filter sheet open (phone)': (390, '/web', (t) => _tap(t, find.text('Type'))),
      'Pick of the week details open': (1024, '/', (t) => _tap(t, find.bySemanticsLabel('Show details'))),
      'navbar search dropdown': (1024, '/', (t) async {
        await t.enterText(find.byType(EditableText).first, 'dark fintech');
        await t.pumpAndSettle();
      }),
      'detail Breakdown tab': (1024, '/screen/s001-ledgerly-homepage', (t) => _tap(t, find.text('Breakdown'))),
      'detail Code tab': (1024, '/screen/s001-ledgerly-homepage', (t) => _tap(t, find.text('Code'))),
      'prompt dialog': (1024, '/screen/s001-ledgerly-homepage', (t) => _tap(t, find.text('Prompt'))),
      'save toast picker': (1024, '/web', (t) async {
        await _tap(t, find.bySemanticsLabel('Save'));
        await _tap(t, find.text('Move to…'));
      }),
    };
    for (final e in states.entries) {
      testWidgets(e.key, (tester) async {
        final h = tester.ensureSemantics();
        final (w, location, open) = e.value;
        await pumpApp(tester, width: w, location: location);
        await settleTimers(tester);
        await open(tester);
        await expectTapTargets48(tester);
        await _drain(tester);
        h.dispose();
      });
    }
  });
}
