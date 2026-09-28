import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/detail/detail_screen.dart';
import 'package:uiverse/dev/mock_gallery.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/router/detail.dart';
import 'package:uiverse/router/routes.dart';
import 'package:uiverse/shell/bottom_nav.dart';
import 'package:uiverse/shell/rail.dart';

import '../shell/app_harness.dart';

void main() {
  const paths = {
    '/': 'home',
    '/explore': 'explore',
    '/web': 'web',
    '/apps': 'apps',
    '/components': 'components',
    '/search': 'search',
    '/saved': 'saved',
    '/palettes': 'palettes',
    '/layouts': 'layouts',
    '/3d': 'threeD',
    '/creators': 'creators',
    '/source/ledgerly': 'source',
    '/pricing': 'pricing',
    '/upload': 'upload',
    '/u/me': 'user',
    '/legal/takedown': 'legal',
  };

  for (final e in paths.entries) {
    testWidgets('${e.key} builds the ${e.value} screen', (tester) async {
      await pumpApp(tester, location: e.key);
      expect(find.text(e.value), findsOneWidget);
    });
  }

  testWidgets('facet paths resolve to the feed with facets', (tester) async {
    await pumpApp(tester, location: '/web/saas/dark');
    expect(find.text('web'), findsOneWidget);
    expect(find.text('facets: saas/dark'), findsOneWidget);
  });

  testWidgets('path and query params reach the screen', (tester) async {
    final app = await pumpApp(tester, location: '/source/ledgerly');
    expect(find.text('slug: ledgerly'), findsOneWidget);
    app.router.go(Routes.searchFor('dark fintech'));
    await tester.pumpAndSettle();
    expect(find.text('q: dark fintech'), findsOneWidget);
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
    final app = await pumpApp(tester, width: 1024);
    final ctx = tester.element(find.text('home'));
    openDetailSlug(ctx, Kind.component, 'c0011-ledgerly-navbar').ignore();
    await tester.pumpAndSettle();

    expect(find.byType(DetailOverlay), findsOneWidget);
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('home'), findsOneWidget); // feed stays underneath
    expect(app.router.state.uri.path, '/component/c0011-ledgerly-navbar');
    expect(find.bySemanticsLabel('Close'), findsWidgets);

    await tester.tapAt(const Offset(5, 450)); // scrim margin, outside the sheet
    await tester.pumpAndSettle();
    expect(find.byType(DetailOverlay), findsNothing);
    expect(app.router.state.uri.path, '/');
  });

  testWidgets('openDetail on a phone is a full-screen page with a close button', (tester) async {
    await pumpApp(tester, width: 390);
    openDetailSlug(tester.element(find.text('home')), Kind.screen, 's001-ledgerly-homepage').ignore();
    await tester.pumpAndSettle();
    expect(find.byType(DetailOverlay), findsOneWidget);
    expect(find.byType(DetailScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close').last);
    await tester.pumpAndSettle();
    expect(find.byType(DetailOverlay), findsNothing);
    expect(find.text('home'), findsOneWidget);
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
