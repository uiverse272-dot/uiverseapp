import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import 'routes.dart';

/// Placeholder screen: route name + params. Replaced route-by-route in `routes.dart`.
class StubPage extends StatelessWidget {
  const StubPage({super.key, required this.name, this.params = const {}, this.scrolls = true});

  /// Stub for [route] showing its path params, facets and query params.
  factory StubPage.of(AppRoute route, GoRouterState state, {bool scrolls = true}) {
    final facets = route.hasFacets ? facetsOf(state) : const <String>[];
    return StubPage(
      name: route.name,
      scrolls: scrolls,
      params: {
        ...state.pathParameters,
        if (facets.isNotEmpty) 'facets': facets.join('/'),
        ...state.uri.queryParameters,
      },
    );
  }

  final String name;
  final Map<String, String> params;

  /// False for detail stubs, which are wrapped in a scroll view by their presentation.
  final bool scrolls;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final wide = MediaQuery.sizeOf(context).width >= 768;
    final body = Padding(
      padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 28, wide ? 24 : 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: UiText.pageTitle.copyWith(color: c.text)),
          for (final e in params.entries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${e.key}: ${e.value}', style: UiText.body.copyWith(color: c.text2)),
            ),
        ],
      ),
    );
    return scrolls ? SingleChildScrollView(child: body) : body;
  }
}
