import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/theme/uiverse_theme.dart';
import 'package:uiverse/widgets/copy_value.dart';
import 'package:uiverse/widgets/core/ui_icon.dart';

import '../detail/clipboard_mock.dart';

void main() {
  late FakeClipboard clipboard;
  setUp(() => clipboard = FakeClipboard.install());
  tearDown(FakeClipboard.uninstall);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(MaterialApp(
        theme: uiverseTheme(Brightness.light),
        home: Scaffold(body: Center(child: child)),
      ));

  bool showsIcon(Ui icon) => find
      .byWidgetPredicate((w) => w is UiIcon && w.icon == icon)
      .evaluate()
      .isNotEmpty;

  testWidgets('copies the value and shows Check for 1200ms', (tester) async {
    await pump(tester, const CopyValue('#F47A2C', mono: true));
    expect(find.text('#F47A2C'), findsOneWidget);
    expect(showsIcon(Ui.copy), isTrue);

    await tester.tap(find.bySemanticsLabel('Copy #F47A2C'));
    await tester.pump();
    expect(clipboard.text, '#F47A2C');
    expect(showsIcon(Ui.check), isTrue);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(showsIcon(Ui.check), isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    expect(showsIcon(Ui.copy), isTrue);
    expect(showsIcon(Ui.check), isFalse);
  });

  testWidgets('label replaces the visible text but the value is copied', (tester) async {
    await pump(tester, const CopyValue('a\nb', label: 'Copy as CSS variables', bordered: true));
    expect(find.text('Copy as CSS variables'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Copy as CSS variables'));
    await tester.pump();
    expect(clipboard.text, 'a\nb');
    await tester.pump(kCopiedFor);
  });
}
