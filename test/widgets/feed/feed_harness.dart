import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/app.dart';
import 'package:uiverse/router/router.dart';
import 'package:uiverse/router/routes.dart' show facetsOf;
import 'package:uiverse/screens/feeds/feed_screen.dart';
import 'package:uiverse/screens/home/home_screen.dart';
import 'package:uiverse/shell/app_shell.dart';
import 'package:uiverse/state/prefs.dart';

export 'themed_harness.dart';

/// A router wiring this agent's screens the way `routes.dart` will, plus
/// plain stand-ins for detail / explore / source.
GoRouter feedTestRouter(String initialLocation) {
  Page<void> page(GoRouterState s, Widget child) => NoTransitionPage<void>(key: s.pageKey, child: child);
  GoRoute facet(String path, Widget Function(GoRouterState s) build) => GoRoute(
        path: path,
        pageBuilder: (c, s) => page(s, build(s)),
        routes: [GoRoute(path: ':facets(.+)', pageBuilder: (c, s) => page(s, build(s)))],
      );
  Widget stub(String text) => Center(child: Text(text));

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/screen/:slug', builder: (c, s) => stub('detail ${s.pathParameters['slug']}')),
      GoRoute(path: '/component/:slug', builder: (c, s) => stub('detail ${s.pathParameters['slug']}')),
      ShellRoute(
        builder: (c, s, child) => AppShell(location: s.uri.path, child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (c, s) => page(s, HomeScreen(chip: s.uri.queryParameters['chip']))),
          facet('/web', (s) => WebFeedScreen(facets: facetsOf(s), query: s.uri.queryParameters)),
          facet('/apps', (s) => AppsFeedScreen(facets: facetsOf(s), query: s.uri.queryParameters)),
          facet('/components', (s) => ComponentsFeedScreen(facets: facetsOf(s), query: s.uri.queryParameters)),
          GoRoute(path: '/3d', pageBuilder: (c, s) => page(s, ThreeDFeedScreen(query: s.uri.queryParameters))),
          GoRoute(path: '/explore', builder: (c, s) => stub('explore stub')),
          GoRoute(path: '/source/:slug', builder: (c, s) => stub('source ${s.pathParameters['slug']}')),
        ],
      ),
    ],
  );
}

/// Pumps the full app (shell, save toast, theme) at [width]×[height] with
/// [feedTestRouter] at [location].
Future<({SharedPreferences prefs, GoRouter router})> pumpFeedApp(
  WidgetTester tester, {
  double width = 400,
  double height = 900,
  String location = '/',
  Map<String, Object> prefs = const {},
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final router = feedTestRouter(location);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      routerProvider.overrideWithValue(router),
    ],
    child: const UiverseApp(),
  ));
  if (settle) await tester.pumpAndSettle();
  return (prefs: sp, router: router);
}

/// Current router location (path + query).
String locationOf(GoRouter router) => router.routerDelegate.currentConfiguration.uri.toString();
