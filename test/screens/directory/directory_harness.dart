import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/app.dart';
import 'package:uiverse/router/router.dart';
import 'package:uiverse/screens/creators/creators_screen.dart';
import 'package:uiverse/screens/layouts/layouts_screen.dart';
import 'package:uiverse/screens/legal/legal_screen.dart';
import 'package:uiverse/screens/palettes/palettes_screen.dart';
import 'package:uiverse/screens/pricing/pricing_screen.dart';
import 'package:uiverse/screens/profile/profile_screen.dart';
import 'package:uiverse/screens/upload/upload_screen.dart';
import 'package:uiverse/shell/app_shell.dart';
import 'package:uiverse/state/prefs.dart';

/// Routes the directory screens inside [AppShell] the way `routes.dart`
/// will, with plain stand-ins for the pages they link to.
GoRouter directoryTestRouter(String initialLocation) {
  Widget stub(String text) => Center(child: Text(text));
  GoRoute route(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, pageBuilder: (c, s) => NoTransitionPage<void>(key: s.pageKey, child: build(s)));

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (c, s, child) => AppShell(location: s.uri.path, child: child),
        routes: [
          route('/', (s) => stub('home stub')),
          route('/palettes', (s) => const PalettesScreen()),
          route('/layouts', (s) => const LayoutsScreen()),
          route('/creators', (s) => const CreatorsScreen()),
          route('/pricing', (s) => const PricingScreen()),
          route('/upload', (s) => const UploadScreen()),
          GoRoute(
            path: '/u/:handle',
            redirect: (c, s) => profileRedirect(s.pathParameters['handle']!),
            pageBuilder: (c, s) => NoTransitionPage<void>(
              key: s.pageKey,
              child: ProfileScreen(handle: s.pathParameters['handle']!),
            ),
          ),
          route('/legal/:doc', (s) => LegalScreen(doc: s.pathParameters['doc']!)),
          route('/source/:slug', (s) => stub('source ${s.pathParameters['slug']}')),
          route('/components', (s) => stub('components ${s.uri.query}')),
          route('/saved', (s) => stub('saved stub')),
        ],
      ),
    ],
  );
}

/// Pumps the full app at [width]×[height] on [directoryTestRouter].
Future<GoRouter> pumpDirectory(
  WidgetTester tester, {
  required String location,
  double width = 390,
  double height = 900,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(const {});
  final sp = await SharedPreferences.getInstance();
  final router = directoryTestRouter(location);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      routerProvider.overrideWithValue(router),
    ],
    child: const UiverseApp(),
  ));
  await tester.pumpAndSettle();
  return router;
}

/// Current router location (path + query).
String locationOf(GoRouter router) => router.routerDelegate.currentConfiguration.uri.toString();

/// Scrolls [finder] into view and taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
