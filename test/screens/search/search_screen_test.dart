import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'discovery_harness.dart';

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  for (final double width in <double>[390, 1024]) {
    testWidgets('no query shows suggestions and the explainer ($width)', (tester) async {
      await pumpDiscovery(tester, width: width, location: '/search');
      expect(find.text('Try a natural-language query'), findsOneWidget);
      expect(find.text('brutalist portfolio'), findsOneWidget);
      expect(find.textContaining('Queries are parsed against the taxonomy first'), findsOneWidget);
      expect(find.text('Reading as'), findsNothing);
    });

    testWidgets('a query shows kind tabs, parse chips and results ($width)', (tester) async {
      await pumpDiscovery(tester, width: width, location: '/search?q=dark%20fintech%20dashboard');
      expect(find.text('All 5'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^Designs \d+$')), findsOneWidget);
      expect(find.textContaining(RegExp(r'^Components \d+$')), findsOneWidget);
      expect(find.text('Reading as'), findsOneWidget);
      expect(find.text('Style: Dark'), findsOneWidget);
      expect(find.text('Industry: Fintech'), findsOneWidget);
      expect(find.text('Type: Dashboard'), findsOneWidget);
      expect(find.textContaining('as free text'), findsNothing);
      expect(find.textContaining('Spend overview'), findsWidgets);
    });
  }

  testWidgets('tapping a suggestion runs it', (tester) async {
    await pumpDiscovery(tester, location: '/search');
    await tapVisible(tester, find.text('brutalist portfolio'));
    expect(find.text('Reading as'), findsOneWidget);
    expect(find.text('Style: Brutalist'), findsOneWidget);
    expect(find.text('Try a natural-language query'), findsNothing);
  });

  testWidgets('removing a parse chip rewrites q', (tester) async {
    await pumpDiscovery(tester, location: '/search?q=dark%20fintech%20dashboard');
    await tapVisible(tester, find.text('Style: Dark'));
    expect(find.text('Style: Dark'), findsNothing);
    expect(find.text('Industry: Fintech'), findsOneWidget);
    expect(find.text('Type: Dashboard'), findsOneWidget);
  });

  testWidgets('kind tabs filter the results', (tester) async {
    await pumpDiscovery(tester, location: '/search?q=dark%20fintech%20dashboard');
    final Finder designs = find.textContaining(RegExp(r'^Designs \d+$'));
    await tapVisible(tester, designs);
    final Semantics sem = tester.widget<Semantics>(
      find.ancestor(of: designs, matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.selected == true)).first,
    );
    expect(sem.properties.selected, isTrue);
    expect(find.textContaining(RegExp(r'^\d+ results · end of feed$')), findsOneWidget);
  });

  testWidgets('residual words are shown as free text', (tester) async {
    await pumpDiscovery(tester, location: '/search?q=dark%20glow');
    expect(find.text('Style: Dark'), findsOneWidget);
    expect(find.text('+ “glow” as free text'), findsOneWidget);
  });
}
