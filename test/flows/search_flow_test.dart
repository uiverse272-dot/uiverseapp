import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/data/query.dart';
import 'package:uiverse/screens/search/search_screen.dart';
import 'package:uiverse/shell/navbar.dart';
import 'package:uiverse/widgets/feed/feed_card.dart';

import 'flow_harness.dart';

/// CLAUDE.md "Data parity": `searchItems("dark fintech dashboard")`.
const List<String> kParityResults = <String>[
  's002-ledgerly-spend-overview',
  's036-current-accounts',
  'c0361-current-stats',
  'c0021-ledgerly-stats',
  'c0022-ledgerly-table',
];

List<Item> shownItems(WidgetTester tester) => <Item>[
      for (final FeedCard c in tester.widgetList<FeedCard>(find.byType(FeedCard, skipOffstage: false))) c.item,
    ];

void main() {
  for (final double width in <double>[390, 1024]) {
    testWidgets('navbar search → parse chips → remove a chip → Components tab ($width)', (tester) async {
      final app = await pumpFlowApp(tester, width: width, height: 1400, location: '/explore');

      await tester.enterText(inside(find.byType(Navbar), find.byType(TextField)), 'dark fintech dashboard');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(app.router.state.uri.queryParameters, {'q': 'dark fintech dashboard'});

      // The parse is shown back as chips; results are exactly the parity set.
      expect(find.text('Reading as'), findsOneWidget);
      expect(find.text('Style: Dark'), findsOneWidget);
      expect(find.text('Industry: Fintech'), findsOneWidget);
      expect(find.text('Type: Dashboard'), findsOneWidget);
      expect(find.text('All 5'), findsOneWidget);
      expect(shownItems(tester).map((i) => i.slug).toSet(), kParityResults.toSet());
      expect(find.text('5 results · end of feed'), findsOneWidget);

      // Remove "dark": q drops the word; the results are a superset. (Every
      // fintech dashboard in the catalogue is dark, so the count holds at 5.)
      await tapVisible(tester, find.text('Style: Dark'));
      expect(app.router.state.uri.queryParameters, {'q': 'fintech dashboard'});
      expect(find.text('Style: Dark'), findsNothing);
      expect(find.text('Industry: Fintech'), findsOneWidget);
      final int noStyle = searchItems('fintech dashboard').results.length;
      expect(noStyle, greaterThanOrEqualTo(5));
      expect(find.text('All $noStyle'), findsOneWidget);
      expect(shownItems(tester).map((i) => i.slug).toSet(), containsAll(kParityResults));

      // Remove "dashboard" too: now the result set really grows.
      await tapVisible(tester, find.text('Type: Dashboard'));
      expect(app.router.state.uri.queryParameters, {'q': 'fintech'});
      final int widened = searchItems('fintech').results.length;
      expect(widened, greaterThan(noStyle));
      expect(find.text('All $widened'), findsOneWidget);

      // Components tab: only component results, kind in the URL.
      final int comps = searchItems('fintech', const Filters(kind: 'component')).results.length;
      await tapVisible(tester, find.text('Components $comps'));
      expect(app.router.state.uri.queryParameters, {'q': 'fintech', 'kind': 'component'});
      final List<Item> shown = shownItems(tester);
      expect(shown, isNotEmpty);
      expect(shown.every((i) => i.kind == Kind.component), isTrue);
      expect(find.text('All $widened'), findsOneWidget);
      expect(shown.length, lessThanOrEqualTo(comps));
    });
  }
}
