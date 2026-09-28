import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Location of the current path with [params] as its query (none when empty).
String withQuery(String path, Map<String, String> params) =>
    Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();

/// Replaces the current route's query with [params], keeping the path, so
/// feed state lives in the URL (back button and deep links work).
void goWithQuery(BuildContext context, Map<String, String> params) {
  final String path = GoRouterState.of(context).uri.path;
  context.go(withQuery(path, params));
}
