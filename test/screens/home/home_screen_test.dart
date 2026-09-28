import 'package:flutter_test/flutter_test.dart';

import '../../widgets/feed/feed_harness.dart';

void main() {
  testWidgets('For You shows Popular this week; a chip filters and updates ?chip=', (tester) async {
    final app = await pumpFeedApp(tester, width: 400);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Popular this week'), findsOneWidget);

    await tester.ensureVisible(find.text('Fintech'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fintech'));
    await tester.pumpAndSettle();
    expect(locationOf(app.router), '/?chip=fintech');
    expect(find.text('Popular this week'), findsNothing);
    expect(find.textContaining(RegExp(r'^Fintech · \d+ results$')), findsOneWidget);
  });

  testWidgets('unknown chip falls back to For You', (tester) async {
    await pumpFeedApp(tester, width: 400, location: '/?chip=nope');
    expect(find.text('Popular this week'), findsOneWidget);
  });
}
