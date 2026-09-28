import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/shell/bottom_nav.dart';
import 'package:uiverse/shell/navbar.dart';
import 'package:uiverse/shell/rail.dart';
import 'package:uiverse/widgets/feed/feed_card.dart';

import 'flow_harness.dart';

void main() {
  group('shell switches by window width on the real router', () {
    // (width, rail, More menu, profile "Browse" section)
    const cases = <(double, bool, bool, bool)>[
      (390, false, false, true),
      (767, false, false, true),
      (768, true, false, false),
      (1023, true, false, false),
      (1024, true, true, false),
      (1280, true, true, false),
    ];
    for (final (double w, bool rail, bool more, bool browse) in cases) {
      testWidgets('$w: rail=$rail more=$more browse=$browse', (tester) async {
        await pumpFlowApp(tester, width: w, location: '/u/me');
        expect(find.byType(Rail), rail ? findsOneWidget : findsNothing);
        expect(find.byType(BottomNav), rail ? findsNothing : findsOneWidget);
        expect(inside(find.byType(Navbar), find.text('More')), more ? findsOneWidget : findsNothing);
        expect(find.text('Your profile'), findsOneWidget);
        expect(find.text('Browse'), browse ? findsOneWidget : findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('resizing across 768 swaps BottomNav for Rail and keeps the route', (tester) async {
      final app = await pumpFlowApp(tester, width: 767, location: '/palettes');
      expect(find.byType(BottomNav), findsOneWidget);
      tester.view.physicalSize = const Size(768, 900);
      await tester.pumpAndSettle();
      expect(find.byType(Rail), findsOneWidget);
      expect(find.byType(BottomNav), findsNothing);
      expect(app.router.state.uri.path, '/palettes');
    });
  });

  group('masonry columns on /web follow useColumns', () {
    // Window width → expected columns (kColumnBreakpoints: 760/1180/1540/1900).
    const cases = <(double, int)>[
      (390, 2),
      (759, 2),
      (760, 3),
      (1179, 3),
      (1180, 4),
      (1539, 4),
      (1540, 5),
      (1899, 5),
      (1900, 6),
    ];
    for (final (double w, int cols) in cases) {
      testWidgets('$w → $cols columns', (tester) async {
        await pumpFlowApp(tester, width: w, height: 1400, location: '/web');
        final Set<double> xs = {
          for (final e in find.byType(FeedCard).evaluate()) tester.getTopLeft(find.byWidget(e.widget)).dx,
        };
        expect(xs.length, cols);
      });
    }
  });
}
