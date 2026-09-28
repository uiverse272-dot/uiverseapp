import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/detail/detail_screen.dart';
import 'package:uiverse/dev/mock_gallery.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/router/detail.dart';
import 'package:uiverse/router/routes.dart';
import 'package:uiverse/screens/creators/creators_screen.dart';
import 'package:uiverse/screens/explore/explore_screen.dart';
import 'package:uiverse/screens/feeds/feed_screen.dart';
import 'package:uiverse/screens/home/home_screen.dart';
import 'package:uiverse/screens/layouts/layouts_screen.dart';
import 'package:uiverse/screens/legal/legal_screen.dart';
import 'package:uiverse/screens/palettes/palettes_screen.dart';
import 'package:uiverse/screens/pricing/pricing_screen.dart';
import 'package:uiverse/screens/profile/profile_screen.dart';
import 'package:uiverse/screens/saved/saved_screen.dart';
import 'package:uiverse/screens/search/search_screen.dart';
import 'package:uiverse/screens/source/source_screen.dart';
import 'package:uiverse/screens/upload/upload_screen.dart';
import 'package:uiverse/shell/bottom_nav.dart';
import 'package:uiverse/shell/rail.dart';

import '../shell/app_harness.dart';

void main() {
  const screens = <String, Type>{
    '/': HomeScreen,
    '/web': WebFeedScreen,
    '/apps': AppsFeedScreen,
    '/components': ComponentsFeedScreen,
    '/3d': ThreeDFeedScreen,
    '/explore': ExploreScreen,
    '/search': SearchScreen,
    '/saved': SavedScreen,
    '/source/ledgerly': SourceScreen,
    '/palettes': PalettesScreen,
    '/layouts': LayoutsScreen,
    '/creators': CreatorsScreen,
    '/pricing': PricingScreen,
    '/upload': UploadScreen,
    '/u/me': ProfileScreen,
    '/legal/takedown': LegalScreen,
  };

  for (final e in screens.entries) {
    testWidgets('${e.key} builds ${e.value}', (tester) async {
      await pumpApp(tester, location: e.key);
      expect(find.byType(e.value), findsOneWidget);
    });
  }

  testWidgets('facet paths and query reach the feed', (tester) async {
    await pumpApp(tester, location: '/web/saas/dark?device=mobile');
    final web = tester.widget<WebFeedScreen>(find.byType(WebFeedScreen));
    expect(web.facets, ['saas', 'dark']);
    expect(web.query, {'device': 'mobile'});
  });

  testWidgets('?chip= reaches the home screen', (tester) async {
    await pumpApp(tester, location: '/?chip=dark');
    expect(tester.widget<HomeScreen>(find.byType(HomeScreen)).chip, 'dark');
  });

  testWidgets('a source handle under /u/ redirects to the source page', (tester) async {
    final app = await pumpApp(tester, location: '/u/ledgerly');
    expect(find.byType(SourceScreen), findsOneWidget);
    expect(app.router.state.uri.path, '/source/ledgerly');
  });

  testWidgets('path and query params reach the screen', (tester) async {
    final app = await pumpApp(tester, location: '/source/ledgerly');
    expect(tester.widget<SourceScreen>(find.byType(SourceScreen)).slug, 'ledgerly');
    app.router.go(Routes.searchFor('dark fintech'));
    await tester.pumpAndSettle();
    expect(tester.widget<SearchScreen>(find.byType(SearchScreen)).query, {'q': 'dark fintech'});
  });

  testWidgets('unknown path shows the 404 inside the shell', (tester) async {
    final app = await pumpApp(tester, location: '/nope/nothing');
    expect(find.text('Not found'), findsOneWidget);
    expect(find.byType(BottomNav), findsOneWidget);
    await tester.tap(find.text('Back to the feed'));
    await tester.pumpAndSettle();
    expect(app.router.state.uri.path, '/');
  });

  testWidgets('deep-linked detail is a plain page in the shell', (tester) async {
    await pumpApp(tester, width: 1024, location: '/screen/s001-ledgerly-homepage');
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.byType(Rail), findsOneWidget);
    expect(find.byType(DetailOverlay), findsNothing);
  });

  testWidgets('openDetail on a tablet overlays the feed; scrim tap closes', (tester) async {
    final app = await pumpApp(tester, width: 1024, location: '/explore');
    final ctx = tester.element(find.byType(ExploreScreen));
    openDetailSlug(ctx, Kind.component, 'c0011-ledgerly-navbar').ignore();
    await tester.pumpAndSettle();

    expect(find.byType(DetailOverlay), findsOneWidget);
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.byType(ExploreScreen), findsOneWidget); // page stays underneath
    expect(app.router.state.uri.path, '/component/c0011-ledgerly-navbar');
    expect(find.bySemanticsLabel('Close'), findsWidgets);

    await tester.tapAt(const Offset(5, 450)); // scrim margin, outside the sheet
    await tester.pumpAndSettle();
    expect(find.byType(DetailOverlay), findsNothing);
    expect(app.router.state.uri.path, '/explore');
  });

  testWidgets('openDetail on a phone is a full-screen page with a close button', (tester) async {
    await pumpApp(tester, width: 390, location: '/explore');
    openDetailSlug(tester.element(find.byType(ExploreScreen)), Kind.screen, 's001-ledgerly-homepage').ignore();
    await tester.pumpAndSettle();
    expect(find.byType(DetailOverlay), findsOneWidget);
    expect(find.byType(DetailScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close').last);
    await tester.pumpAndSettle();
    expect(find.byType(DetailOverlay), findsNothing);
    expect(find.byType(ExploreScreen), findsOneWidget);
  });

  test('Routes helpers', () {
    expect(Routes.searchFor('  '), '/search');
    expect(Routes.searchFor('a b'), '/search?q=a+b');
    expect(Routes.facets(Routes.web, ['saas', 'dark']), '/web/saas/dark');
    expect(Routes.screen('s001'), '/screen/s001');
  });

  testWidgets('DetailPresentation.of defaults to page', (tester) async {
    late DetailPresentation p;
    await tester.pumpWidget(Builder(builder: (c) {
      p = DetailPresentation.of(c);
      return const SizedBox();
    }));
    expect(p, DetailPresentation.page);
  });

  testWidgets('/dev/mock builds the mock gallery', (tester) async {
    await pumpApp(tester, location: '/dev/mock');
    expect(find.byType(MockGalleryPage), findsOneWidget);
  });
}
