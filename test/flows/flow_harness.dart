import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/app.dart';
import 'package:uiverse/router/router.dart';
import 'package:uiverse/state/prefs.dart';

/// A running app from [pumpFlowApp].
typedef FlowApp = ({SharedPreferences prefs, GoRouter router, ProviderContainer container});

/// Pumps the whole app (real [createRouter]) at [width]×[height], dpr 1.
///
/// Pass [prefs] to reuse an existing store (an app "restart"), or
/// [initial] to seed a fresh one. [clock] overrides [clockProvider]; pass a
/// closure over a mutable variable to move time during a test.
Future<FlowApp> pumpFlowApp(
  WidgetTester tester, {
  double width = 390,
  double height = 900,
  String location = '/',
  SharedPreferences? prefs,
  Map<String, Object> initial = const {},
  Clock? clock,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final SharedPreferences sp;
  if (prefs != null) {
    sp = prefs;
  } else {
    SharedPreferences.setMockInitialValues(initial);
    sp = await SharedPreferences.getInstance();
  }
  final router = createRouter(initialLocation: location);
  addTearDown(router.dispose);
  // A different root first, so a second call really restarts the app.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      routerProvider.overrideWithValue(router),
      if (clock != null) clockProvider.overrideWithValue(clock),
    ],
    child: const UiverseApp(),
  ));
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(tester.element(find.byType(UiverseApp)));
  return (prefs: sp, router: router, container: container);
}

/// Everything in [prefs], to seed a fresh store on "restart".
Map<String, Object> snapshotPrefs(SharedPreferences prefs) => <String, Object>{
      for (final String k in prefs.getKeys()) k: prefs.get(k)!,
    };

/// Scrolls [f] into view, taps it and settles.
Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// [matching] inside [of].
Finder inside(Finder of, Finder matching) => find.descendant(of: of, matching: matching);
