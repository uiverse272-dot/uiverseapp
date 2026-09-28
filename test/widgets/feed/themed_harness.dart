import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/state/prefs.dart';
import 'package:uiverse/theme/uiverse_theme.dart';

/// Pumps [child] inside the app theme and a [ProviderScope] (no router) at
/// [width]×[height].
Future<SharedPreferences> pumpThemed(
  WidgetTester tester,
  Widget child, {
  double width = 400,
  double height = 900,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(const {});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
    child: MaterialApp(
      theme: uiverseTheme(Brightness.light),
      home: Material(child: child),
    ),
  ));
  await tester.pumpAndSettle();
  return sp;
}
