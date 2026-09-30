import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/theme/uiverse_theme.dart';
import 'package:uiverse/widgets/core/links.dart';

Widget _host(Widget child) =>
    MaterialApp(theme: uiverseTheme(Brightness.light), home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('LinkInk.quiet taps through and keeps its text as the accessible name', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(LinkInk.quiet('Save as a layout', onTap: () => taps++)));
    await tester.tap(find.text('Save as a layout'));
    expect(taps, 1);
    expect(find.bySemanticsLabel('Save as a layout'), findsOneWidget);
  });

  testWidgets('InlineLinkText can be focused and activated from the keyboard', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(InlineLinkText(
      before: 'See the ',
      link: 'attribution policy',
      after: '.',
      onTap: () => taps++,
      style: const TextStyle(fontSize: 12),
    )));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });
}
