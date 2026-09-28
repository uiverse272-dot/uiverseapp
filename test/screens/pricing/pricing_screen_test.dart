import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/screens/pricing/pricing_screen.dart';

import '../directory/directory_harness.dart';

void main() {
  for (final double width in [390, 1024]) {
    testWidgets('plans, table and footer render without overflow at $width', (tester) async {
      await pumpDirectory(tester, location: '/pricing', width: width, height: 2400);
      expect(find.text('Simple, honest pricing'), findsOneWidget);
      for (final Plan p in kPlans) {
        expect(find.text(p.price), findsOneWidget);
      }
      expect(find.text('Popular'), findsOneWidget);
      expect(find.bySemanticsLabel('Start free'), findsOneWidget);
      expect(find.bySemanticsLabel('Choose plan'), findsNWidgets(2));
      expect(find.text('Feature'), findsOneWidget);
      expect(find.text('AI prompt generation'), findsOneWidget);
      expect(find.bySemanticsLabel('Included'), findsNWidgets(5));
      expect(find.text('No countdown timers, no fake scarcity, cancel in one click.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('plan cards stack on phones', (tester) async {
    await pumpDirectory(tester, location: '/pricing', width: 390, height: 2400);
    expect(tester.getTopLeft(find.text('£12')).dy, greaterThan(tester.getTopLeft(find.text('£0')).dy));
  });

  testWidgets('plan cards sit in a row on tablets', (tester) async {
    await pumpDirectory(tester, location: '/pricing', width: 1024, height: 2400);
    expect(tester.getTopLeft(find.text('£12')).dy, tester.getTopLeft(find.text('£0')).dy);
  });
}
