import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../state/state_harness.dart';
import 'package:uiverse/theme/uiverse_theme.dart';
import 'package:uiverse/widgets/save/save_toast.dart';

/// Pumps [child] at [width]×[height] (dpr 1) inside a themed app with mock
/// prefs, wrapped in a vertical scroll view like the detail presentations.
/// Returns the provider container so tests can inspect state.
Future<ProviderContainer> pumpDetail(
  WidgetTester tester,
  Widget child, {
  double width = 1400,
  double height = 1000,
  bool scroll = true,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (container, _) = await makeContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: uiverseTheme(Brightness.light),
      builder: (context, c) => SaveToastLayer(child: c!),
      home: Scaffold(body: scroll ? SingleChildScrollView(child: child) : child),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}
