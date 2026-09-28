import 'package:flutter/widgets.dart' hide Viewport;
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/mock/mock_screen.dart';

import 'fixtures.dart';

Widget _host(Widget child, {required double width, bool scroll = false}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: scroll ? SingleChildScrollView(child: child) : child,
        ),
      ),
    );

Future<void> _pump(WidgetTester tester, Widget w, {required double width, bool scroll = false}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(1200, 2000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(w, width: width, scroll: scroll));
  expect(tester.takeException(), isNull);
}

void main() {
  const widths = [120.0, 390.0, 1000.0];

  for (final a in Archetype.values) {
    testWidgets('screen ${a.slug} renders at every viewport and width', (tester) async {
      for (final (i, width) in widths.indexed) {
        final item = fixtureScreen(a, palettes[(a.index + i) % palettes.length]);

        // Feed card: fixed aspect frame, cropped.
        await _pump(tester, MockScreen(item: item), width: width, scroll: true);
        expect(tester.getSize(find.byType(MockScreen)), Size(width, width / item.aspect));

        // Detail frame: content height, min one screen.
        for (final vp in Viewport.values) {
          await _pump(tester, MockScreen(item: item, viewport: vp), width: width, scroll: true);
          final h = tester.getSize(find.byType(MockScreen)).height;
          expect(h, greaterThanOrEqualTo(width / vp.w * vp.h - 0.01), reason: '${a.slug} @ ${vp.name}');
        }
        await _pump(tester, MockScreen(item: item, full: true), width: width, scroll: true);
      }
    });
  }

  for (final item in componentFixtures) {
    testWidgets('component ${item.componentType} of ${item.archetype.slug} renders', (tester) async {
      for (final width in widths) {
        await _pump(tester, MockScreen(item: item), width: width, scroll: true);
        expect(tester.getSize(find.byType(MockScreen)), Size(width, width / item.aspect));
        for (final vp in Viewport.values) {
          await _pump(tester, MockScreen(item: item, viewport: vp), width: width, scroll: true);
        }
      }
    });
  }

  testWidgets('landing shows the brand and copy', (tester) async {
    final item = fixtureScreen(Archetype.saasLanding, paper);
    await _pump(tester, MockScreen(item: item, viewport: Viewport.desktop), width: 1000, scroll: true);
    expect(find.text('Acme', findRichText: true), findsWidgets);
    expect(find.text('Everything in one place', findRichText: true), findsOneWidget);
    expect(find.text('Get started', findRichText: true), findsOneWidget);

    // Phones collapse the nav: no "Get started" button in the header.
    await _pump(tester, MockScreen(item: item, viewport: Viewport.mobile), width: 390, scroll: true);
    expect(find.text('Get started', findRichText: true), findsNothing);
  });

  testWidgets('mobile apps become a web app with a side nav on laptop', (tester) async {
    final item = fixtureScreen(Archetype.mobileFinance, ocean);
    await _pump(tester, MockScreen(item: item, viewport: Viewport.desktop), width: 1000, scroll: true);
    expect(find.text('Payments', findRichText: true), findsOneWidget);
    expect(find.text('9:41', findRichText: true), findsNothing);

    await _pump(tester, MockScreen(item: item), width: 390);
    expect(find.text('9:41', findRichText: true), findsOneWidget);
  });
}
