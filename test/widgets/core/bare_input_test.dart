import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/theme/uiverse_theme.dart';
import 'package:uiverse/widgets/core/bare_input.dart';

void main() {
  testWidgets('bareInput ignores the theme fill and borders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: uiverseTheme(Brightness.light),
      home: Scaffold(
        body: TextField(decoration: bareInput(hintText: 'Hint', hintStyle: const TextStyle())),
      ),
    ));
    final context = tester.element(find.byType(TextField));
    final d = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!
        .applyDefaults(Theme.of(context).inputDecorationTheme);
    expect(d.filled, isFalse);
    expect(d.enabledBorder, InputBorder.none);
    expect(d.focusedBorder, InputBorder.none);
    expect(find.text('Hint'), findsOneWidget);
  });
}
