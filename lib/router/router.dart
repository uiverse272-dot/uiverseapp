import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shell/app_shell.dart';
import 'detail.dart';
import 'not_found_page.dart';
import 'routes.dart';

/// The app router: a [ShellRoute] (Navbar + Rail/BottomNav) around every
/// screen, plus the two detail routes on the root navigator so they can
/// present as an overlay above the whole shell (see [DetailPresentation]).
///
/// Screens are plugged in via [buildRoute] in `routes.dart`.
final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Builds a fresh router (exposed for tests).
GoRouter createRouter({String initialLocation = Routes.home}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  GoRoute screen(AppRoute r, {List<RouteBase> routes = const []}) => GoRoute(
        path: r.path,
        name: r.name,
        pageBuilder: (context, state) =>
            NoTransitionPage<void>(key: state.pageKey, child: buildRoute(r, context, state)),
        routes: routes,
      );

  // `/web`, `/web/saas`, `/web/saas/dark`, … all build the same feed.
  GoRoute facetFeed(AppRoute r) => screen(r, routes: [
        GoRoute(
          path: ':facets(.+)',
          name: '${r.name}Facets',
          pageBuilder: (context, state) =>
              NoTransitionPage<void>(key: state.pageKey, child: buildRoute(r, context, state)),
        ),
      ]);

  GoRoute detail(AppRoute r) => GoRoute(
        path: r.path,
        name: r.name,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) =>
            buildDetailPage(context, state, buildRoute(r, context, state)),
      );

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    errorBuilder: (context, state) =>
        AppShell(location: state.uri.path, child: const NotFoundPage()),
    routes: [
      detail(AppRoute.screen),
      detail(AppRoute.component),
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          for (final r in AppRoute.values)
            if (r.hasFacets)
              facetFeed(r)
            else if (!r.isDetail)
              screen(r),
        ],
      ),
    ],
  );
}
