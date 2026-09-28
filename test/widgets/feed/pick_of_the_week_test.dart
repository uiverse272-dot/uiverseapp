import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/state/pick.dart';

import 'feed_harness.dart';

void main() {
  const eyebrow = 'PICK OF THE WEEK';

  testWidgets('≥768: auto-opens as a card after 700ms; folding persists', (tester) async {
    final app = await pumpFeedApp(tester, width: 1024);
    expect(find.text(eyebrow), findsNothing);
    expect(find.text('Pick of the week'), findsOneWidget); // tab

    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();
    expect(find.text(eyebrow), findsOneWidget);
    expect(find.text('Open breakdown'), findsOneWidget);

    // Expand → details.
    await tester.tap(find.bySemanticsLabel('Show details'));
    await tester.pumpAndSettle();
    expect(find.text('Captured'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Hide pick of the week'));
    await tester.pumpAndSettle();
    expect(find.text(eyebrow), findsNothing);
    expect(app.prefs.getString(kPickKey), 'tab');
  });

  testWidgets('≥768: stays folded when the fold was persisted', (tester) async {
    await pumpFeedApp(tester, width: 1024, prefs: {kPickKey: 'tab'});
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(eyebrow), findsNothing);

    // Unfolding clears the persisted fold.
    final app = await pumpFeedApp(tester, width: 1024, prefs: {kPickKey: 'tab'});
    await tester.tap(find.text('Pick of the week'));
    await tester.pumpAndSettle();
    expect(find.text(eyebrow), findsOneWidget);
    expect(app.prefs.getString(kPickKey), isNull);
  });

  testWidgets('phone: stays a tab', (tester) async {
    await pumpFeedApp(tester, width: 400);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(eyebrow), findsNothing);
    expect(find.text('Pick of the week'), findsOneWidget);
  });

  testWidgets('Open breakdown opens the detail', (tester) async {
    await pumpFeedApp(tester, width: 1024);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open breakdown'));
    await tester.pumpAndSettle();
    // `push` keeps the base URI in `currentConfiguration`; check the stub page.
    expect(find.textContaining(RegExp(r'^detail s\d')), findsOneWidget);
  });
}
