import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/data/query.dart';
import 'package:uiverse/screens/feeds/feed_screen.dart';
import 'package:uiverse/screens/home/home_screen.dart';
import 'package:uiverse/screens/source/source_data.dart';
import 'package:uiverse/screens/source/source_screen.dart';
import 'package:uiverse/shell/bottom_nav.dart';
import 'package:uiverse/shell/rail.dart';
import 'package:uiverse/widgets/feed/feed_card.dart';

import 'flow_harness.dart';

List<Item> shownItems(WidgetTester tester) => <Item>[
      for (final FeedCard c in tester.widgetList<FeedCard>(find.byType(FeedCard, skipOffstage: false))) c.item,
    ];

void main() {
  final Source first = kSources.first;

  for (final double width in <double>[390, 1024]) {
    group('deep links ($width)', () {
      // `saas` is both a category and an industry; like the web, the first
      // facet dictionary (category) wins.
      for (final (String path, Filters f) in <(String, Filters)>[
        ('/web/saas', const Filters(kind: 'screen', platform: 'web', category: 'saas')),
        ('/web/saas/dark', const Filters(kind: 'screen', platform: 'web', category: 'saas', style: 'dark')),
      ]) {
        testWidgets('$path: facet title, filtered count, matching cards', (tester) async {
          await pumpFlowApp(tester, width: width, location: path);
          final List<Item> expected = applyFilters(kItems, f);
          expect(find.byType(WebFeedScreen), findsOneWidget);
          expect(find.text('SaaS websites'), findsOneWidget);
          expect(find.text('${expected.length} results'), findsOneWidget);
          expect(find.byType(width >= 768 ? Rail : BottomNav), findsOneWidget);
          final List<Item> shown = shownItems(tester);
          if (expected.isEmpty) {
            expect(find.text('Nothing matches those filters'), findsOneWidget);
          } else {
            expect(shown, isNotEmpty);
          }
          final Set<String> allowed = {for (final Item i in expected) i.slug};
          expect(shown.every((i) => allowed.contains(i.slug)), isTrue);
        });
      }

      testWidgets('/components?component=navbar: filter selected, only navbars', (tester) async {
        final app = await pumpFlowApp(tester, width: width, location: '/components?component=navbar');
        final List<Item> expected = applyFilters(kItems, const Filters(kind: 'component', componentType: 'navbar'));
        expect(find.byType(ComponentsFeedScreen), findsOneWidget);
        expect(find.text('${expected.length} results'), findsOneWidget);
        // The Component popover shows the chosen option instead of its label.
        expect(find.text('Navbar'), findsWidgets);
        final List<Item> shown = shownItems(tester);
        expect(shown, isNotEmpty);
        expect(shown.every((i) => i.kind == Kind.component && i.componentType == 'navbar'), isTrue);

        // "Clear" drops the query param and shows every component again.
        await tapVisible(tester, find.text('Clear'));
        expect(app.router.state.uri.toString(), '/components');
        final int all = applyFilters(kItems, const Filters(kind: 'component')).length;
        expect(find.text('$all results', skipOffstage: false), findsOneWidget);
      });

      testWidgets('/source/<first>?tab=components shows that tab', (tester) async {
        await pumpFlowApp(tester, width: width, location: '/source/${first.slug}?tab=components');
        final v = sourceView(first.slug)!;
        expect(find.byType(SourceScreen), findsOneWidget);
        expect(find.text(first.name), findsWidgets);
        final List<Item> shown = shownItems(tester);
        expect(shown, isNotEmpty);
        expect(shown.every((i) => i.kind == Kind.component && i.source.slug == first.slug), isTrue);
        expect(shown.length, lessThanOrEqualTo(v.components.length));
      });

      testWidgets('/source/<first>?tab=system shows the palette tab', (tester) async {
        await pumpFlowApp(tester, width: width, location: '/source/${first.slug}?tab=system');
        expect(find.text('Inferred palette'), findsOneWidget);
        expect(find.byType(FeedCard), findsNothing);
      });

      testWidgets('/u/<source> redirects to the source page', (tester) async {
        final app = await pumpFlowApp(tester, width: width, location: '/u/${first.slug}');
        expect(app.router.state.uri.path, '/source/${first.slug}');
        expect(find.byType(SourceScreen), findsOneWidget);
        expect(find.text(first.name), findsWidgets);
      });

      testWidgets('unknown route → 404 → Back to the feed', (tester) async {
        final app = await pumpFlowApp(tester, width: width, location: '/definitely/not/here');
        expect(find.text('Not found'), findsOneWidget);
        expect(find.text("That page doesn't exist."), findsOneWidget);
        expect(find.byType(width >= 768 ? Rail : BottomNav), findsOneWidget);
        await tapVisible(tester, find.text('Back to the feed'));
        expect(app.router.state.uri.path, '/');
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Not found'), findsNothing);
      });

      testWidgets('unknown detail slug → Not found → Back to the feed', (tester) async {
        final app = await pumpFlowApp(tester, width: width, location: '/screen/nope');
        expect(find.text('Not found'), findsOneWidget);
        await tapVisible(tester, find.text('Back to the feed'));
        expect(app.router.state.uri.path, '/');
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });
  }
}
