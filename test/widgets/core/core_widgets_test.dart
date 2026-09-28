import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/theme/uiverse_theme.dart';
import 'package:uiverse/widgets/core/lift_on_press.dart';
import 'package:uiverse/widgets/core/logo_mark.dart';

Widget _host(Widget child) =>
    MaterialApp(theme: uiverseTheme(Brightness.light), home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('LiftOnPress fires onTap and reports lift on press', (tester) async {
    var taps = 0;
    final lifts = <bool>[];
    await tester.pumpWidget(_host(LiftOnPress(
      onTap: () => taps++,
      onLiftChanged: lifts.add,
      child: const SizedBox(width: 100, height: 100, child: Text('plate')),
    )));
    await tester.tap(find.text('plate'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(lifts, [true, false]);
  });

  testWidgets('LogoMark exposes a semantics label', (tester) async {
    await tester.pumpWidget(_host(const LogoMark()));
    expect(find.bySemanticsLabel('Uiverse'), findsOneWidget);
  });
}
