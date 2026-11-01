import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/state/prefs.dart';
import 'package:uiverse/state/saves.dart';
import 'package:uiverse/theme/uiverse_theme.dart';
import 'package:uiverse/widgets/save/save_button.dart';
import 'package:uiverse/widgets/save/save_toast.dart';

Future<SharedPreferences> _pump(
  WidgetTester tester,
  Widget child, {
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: uiverseTheme(Brightness.light),
      builder: (context, c) => SaveToastLayer(child: c!),
      home: Scaffold(body: Center(child: child)),
    ),
  ));
  return prefs;
}

void main() {
  testWidgets('icon save toggles, shows toast, Move to… creates a collection', (tester) async {
    final prefs = await _pump(tester, const SaveButton('s001'));

    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(SaveToast), matching: find.text('Saved')), findsOneWidget);
    expect(find.bySemanticsLabel('Remove from saves'), findsOneWidget);

    await tester.tap(find.text('Move to…'));
    await tester.pumpAndSettle();
    expect(find.text('Move to collection'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Dark dashboards');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Move to collection'), findsNothing); // toast closed
    final stored = SavesState.fromJson(
      jsonDecode(prefs.getString(kSavesKey)!) as Map<String, Object?>,
    );
    expect(stored.collections.map((c) => c.id), ['dark-dashboards']);
    expect(stored.savesIn('dark-dashboards').single.slug, 's001');
  });

  testWidgets('picking an existing collection pins the save', (tester) async {
    final prefs = await _pump(
      tester,
      const SaveButton('s001'),
      initial: {kSavesKey: '{"collections":[{"id":"refs","name":"Refs"}]}'},
    );
    await tester.tap(find.bySemanticsLabel('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refs'));
    await tester.pumpAndSettle();
    expect(find.text('Move to collection'), findsNothing);
    expect(prefs.getString(kSavesKey), contains('"collectionId":"refs"'));
  });

  testWidgets('unsaving shows "Removed" without Move to…; Dismiss hides it', (tester) async {
    await _pump(tester, const SaveButton('s001', variant: SaveButtonVariant.solid));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final Finder button = find.descendant(of: find.byType(SaveButton), matching: find.text('Saved'));
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Removed'), findsOneWidget);
    expect(find.text('Move to…'), findsNothing);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Removed'), findsNothing);
  });

  testWidgets('inline variant labels and toast sits 80 from the bottom on phones',
      (tester) async {
    tester.view
      ..physicalSize = const Size(390, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, const SaveButton('x', variant: SaveButtonVariant.inline));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(SaveButton), matching: find.text('Saved')), findsOneWidget);
    final toast = tester.getRect(find.byType(SaveToast));
    expect(toast.bottom, 800 - 80);
    expect(toast.width, 390 - 32);
  });
}
