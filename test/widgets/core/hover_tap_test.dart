import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/theme/uiverse_theme.dart';
import 'package:uiverse/widgets/core/hover_tap.dart';

Widget _host(Widget child) =>
    MaterialApp(theme: uiverseTheme(Brightness.light), home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('a labelled HoverTap keeps its tap action for assistive tech', (tester) async {
    final h = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(_host(HoverTap(
      onTap: () => taps++,
      label: 'Close',
      builder: (_, _) => const SizedBox(width: 20, height: 20),
    )));
    final node = tester.getSemantics(find.bySemanticsLabel('Close'));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    expect(taps, 1);
    h.dispose();
  });

  testWidgets('an unlabelled HoverTap is one tappable node named by its child', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(_host(HoverTap(
      onTap: () {},
      link: true,
      builder: (_, _) => const Text('from Ledgerly'),
    )));
    expect(
      tester.getSemantics(find.bySemanticsLabel('from Ledgerly')),
      isSemantics(isLink: true, hasTapAction: true, label: 'from Ledgerly'),
    );
    h.dispose();
  });

  testWidgets('keeps the visual size but hits at least 48×48', (tester) async {
    await tester.pumpWidget(_host(HoverTap(
      onTap: () {},
      label: 'Save',
      builder: (_, _) => const SizedBox(width: 28, height: 28),
    )));
    expect(tester.getSize(find.byType(HoverTap)), const Size(48, 48));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
