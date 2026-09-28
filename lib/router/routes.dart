import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../detail/detail_screen.dart';
import '../dev/mock_gallery.dart';
import 'stub_page.dart';

/// Path constants and builders for every §12 screen.
abstract final class Routes {
  static const String home = '/';
  static const String explore = '/explore';
  static const String web = '/web';
  static const String apps = '/apps';
  static const String components = '/components';
  static const String search = '/search';
  static const String saved = '/saved';
  static const String palettes = '/palettes';
  static const String layouts = '/layouts';
  static const String threeD = '/3d';
  static const String creators = '/creators';
  static const String pricing = '/pricing';
  static const String upload = '/upload';
  static const String me = '/u/me';
  static const String devMock = '/dev/mock';

  static String screen(String slug) => '/screen/${Uri.encodeComponent(slug)}';
  static String component(String slug) => '/component/${Uri.encodeComponent(slug)}';
  static String source(String slug) => '/source/${Uri.encodeComponent(slug)}';
  static String user(String handle) => '/u/${Uri.encodeComponent(handle)}';
  static String legal(String doc) => '/legal/${Uri.encodeComponent(doc)}';

  /// `/search?q=…` (bare `/search` when [q] is blank).
  static String searchFor(String q) => q.trim().isEmpty
      ? search
      : Uri(path: search, queryParameters: {'q': q.trim()}).toString();

  /// A facet feed, e.g. `facets(web, ['saas', 'dark'])` → `/web/saas/dark`.
  static String facets(String base, List<String> facets) =>
      facets.isEmpty ? base : '$base/${facets.map(Uri.encodeComponent).join('/')}';
}

/// Every named route. [path] is the go_router pattern relative to its parent.
enum AppRoute {
  home('/'),
  explore('/explore'),
  web('/web'),
  apps('/apps'),
  components('/components'),
  screen('/screen/:slug'),
  component('/component/:slug'),
  search('/search'),
  saved('/saved'),
  palettes('/palettes'),
  layouts('/layouts'),
  threeD('/3d'),
  creators('/creators'),
  source('/source/:slug'),
  pricing('/pricing'),
  upload('/upload'),
  user('/u/:handle'),
  legal('/legal/:doc'),
  devMock('/dev/mock');

  const AppRoute(this.path);
  final String path;

  /// Facet feeds accept any number of trailing segments (`/web/saas/dark`).
  bool get hasFacets => this == web || this == apps || this == components;

  /// Detail routes open as an overlay when pushed from inside the app.
  bool get isDetail => this == screen || this == component;
}

/// The facet segments after a feed's base path: `/web/saas/dark` → `['saas', 'dark']`.
List<String> facetsOf(GoRouterState state) {
  final segs = state.uri.pathSegments;
  return segs.length <= 1 ? const [] : segs.sublist(1);
}

/// ★ Route → screen table. Swap a stub for the real screen here, one line per route.
///
/// Params: `state.pathParameters['slug' | 'handle' | 'doc']`, `facetsOf(state)`,
/// `state.uri.queryParameters['q']` (search), `['chip']` (home). Detail screens
/// can read `DetailPresentation.of(context)` and must not scroll themselves
/// (both presentations wrap them in a scroll view).
Widget buildRoute(AppRoute route, BuildContext context, GoRouterState state) => switch (route) {
      AppRoute.home => StubPage.of(route, state),
      AppRoute.explore => StubPage.of(route, state),
      AppRoute.web => StubPage.of(route, state),
      AppRoute.apps => StubPage.of(route, state),
      AppRoute.components => StubPage.of(route, state),
      AppRoute.screen || AppRoute.component => DetailScreen(slug: state.pathParameters['slug']!),
      AppRoute.search => StubPage.of(route, state),
      AppRoute.saved => StubPage.of(route, state),
      AppRoute.palettes => StubPage.of(route, state),
      AppRoute.layouts => StubPage.of(route, state),
      AppRoute.threeD => StubPage.of(route, state),
      AppRoute.creators => StubPage.of(route, state),
      AppRoute.source => StubPage.of(route, state),
      AppRoute.pricing => StubPage.of(route, state),
      AppRoute.upload => StubPage.of(route, state),
      AppRoute.user => StubPage.of(route, state),
      AppRoute.legal => StubPage.of(route, state),
      AppRoute.devMock => const MockGalleryPage(),
    };
