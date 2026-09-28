import 'package:flutter_test/flutter_test.dart';

import '../../widgets/feed/feed_harness.dart';

void main() {
  testWidgets('/web shows the generic title and a result count', (tester) async {
    await pumpFeedApp(tester, width: 400, location: '/web');
    expect(find.text('Websites'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+ results$')), findsOneWidget);
  });

  testWidgets('/web/<facet> names the facet in the title', (tester) async {
    await pumpFeedApp(tester, width: 400, location: '/web/saas');
    expect(find.text('SaaS websites'), findsOneWidget);
  });

  testWidgets('/components and /3d render their headers', (tester) async {
    await pumpFeedApp(tester, width: 400, location: '/components');
    expect(find.text('Components'), findsWidgets);
    await pumpFeedApp(tester, width: 400, location: '/3d');
    expect(find.text('3D & motion'), findsOneWidget);
  });

  testWidgets('/apps renders the app feed', (tester) async {
    await pumpFeedApp(tester, width: 400, location: '/apps');
    expect(find.text('Mobile & app UI'), findsOneWidget);
  });
}
