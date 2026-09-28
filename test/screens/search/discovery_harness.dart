import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/app.dart';
import 'package:uiverse/router/router.dart';
import 'package:uiverse/screens/explore/explore_screen.dart';
import 'package:uiverse/screens/saved/saved_screen.dart';
import 'package:uiverse/screens/search/search_screen.dart';
import 'package:uiverse/screens/source/source_screen.dart';
import 'package:uiverse/shell/app_shell.dart';
import 'package:uiverse/state/prefs.dart';

/// A router wiring the Discovery screens the way `routes.dart` will, with
/// plain stand-ins (showing path + query) for the feeds, home and detail.
GoRouter discoveryTestRouter(String initialLocation) {
  Page<void> page(GoRouterState s, Widget child) => NoTransitionPage<void>(key: s.pageKey, child: child);
  Widget stub(GoRouterState s) => Center(child: Text('stub ${s.uri}'));
  GoRoute stubRoute(String path) => GoRoute(path: path, pageBuilder: (c, s) => page(s, stub(s)));

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/screen/:slug', builder: (c, s) => stub(s)),
      GoRoute(path: '/component/:slug', builder: (c, s) => stub(s)),
      ShellRoute(
        builder: (c, s, child) => AppShell(location: s.uri.path, child: child),
        routes: [
          stubRoute('/'),
          stubRoute('/web'),
          stubRoute('/apps'),
          stubRoute('/components'),
          GoRoute(path: '/explore', pageBuilder: (c, s) => page(s, const ExploreScreen())),
          GoRoute(
            path: '/search',
            pageBuilder: (c, s) => page(s, SearchScreen(query: s.uri.queryParameters)),
          ),
          GoRoute(
            path: '/saved',
            pageBuilder: (c, s) => page(s, SavedScreen(query: s.uri.queryParameters)),
          ),
          GoRoute(
            path: '/source/:slug',
            pageBuilder: (c, s) =>
                page(s, SourceScreen(slug: s.pathParameters['slug']!, query: s.uri.queryParameters)),
          ),
        ],
      ),
    ],
  );
}

/// Pumps the full app at [width]×[height] with [discoveryTestRouter] at [location].
Future<({SharedPreferences prefs, GoRouter router})> pumpDiscovery(
  WidgetTester tester, {
  double width = 390,
  double height = 900,
  String location = '/',
  Map<String, Object> prefs = const {},
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final router = discoveryTestRouter(location);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      routerProvider.overrideWithValue(router),
    ],
    child: const UiverseApp(),
  ));
  await tester.pumpAndSettle();
  return (prefs: sp, router: router);
}

/// Current router location (path + query).
String locationOf(GoRouter router) => router.routerDelegate.currentConfiguration.uri.toString();
