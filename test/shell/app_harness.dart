import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/app.dart';
import 'package:uiverse/router/router.dart';
import 'package:uiverse/state/prefs.dart';

/// Pumps the full app at [width]×900 (dpr 1) starting at [location].
Future<({SharedPreferences prefs, GoRouter router})> pumpApp(
  WidgetTester tester, {
  double width = 400,
  String location = '/',
  Map<String, Object> prefs = const {},
}) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final router = createRouter(initialLocation: location);
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
