import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/spec.dart';
import 'package:uiverse/detail/breakdown.dart';

import 'clipboard_mock.dart';
import 'detail_harness.dart';

void main() {
  final item = bySlug('s001-ledgerly-homepage')!;
  final roles = colorRoles(item);

  test('CSS variables and Tailwind theme match the web strings', () {
    expect(cssVariables(roles).split('\n').first, '  --${roles.first.token}: ${roles.first.value};');
    expect(cssVariables(roles).split('\n'), hasLength(roles.length));
    final tw = tailwindTheme(roles);
    expect(tw, startsWith('@theme {\n  --color-background: '));
    expect(tw, endsWith(';\n}'));
    expect(tw.split('\n'), hasLength(roles.length + 2));
  });

  testWidgets('lists every block, colour role and type step', (tester) async {
    await pumpDetail(tester, Breakdown(item: item));
    final n = item.blocks.length;
    expect(find.text('$n blocks detected'), findsOneWidget);
    for (int i = 1; i <= n; i++) {
      expect(find.text(i.toString().padLeft(2, '0')), findsOneWidget);
    }
    for (final b in item.blocks) {
      // once in the outline, once in the derived layout
      expect(find.text(b.label), findsNWidgets(2 * item.blocks.where((x) => x.label == b.label).length));
    }
    for (final r in roles) {
      expect(find.text(r.label), findsOneWidget);
    }
    for (final t in typeScale(item)) {
      expect(find.text(t.use), findsOneWidget);
    }
    expect(find.text('Save as a layout →'), findsOneWidget);
    expect(find.text('4px base'), findsOneWidget);
    expect(find.text(layoutSpec(item).container), findsOneWidget);
  });

  testWidgets('copy buttons put the token blocks on the clipboard', (tester) async {
    final clipboard = FakeClipboard.install();
    addTearDown(FakeClipboard.uninstall);
    await pumpDetail(tester, Breakdown(item: item));

    await tester.ensureVisible(find.text('Copy as Tailwind theme'));
    await tester.tap(find.text('Copy as Tailwind theme'));
    await tester.pump();
    expect(clipboard.text, tailwindTheme(roles));

    await tester.tap(find.text('Copy as CSS variables'));
    await tester.pump();
    expect(clipboard.text, cssVariables(roles));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('lays out on a phone without overflow', (tester) async {
    await pumpDetail(tester, Breakdown(item: item), width: 360, height: 800);
    expect(tester.takeException(), isNull);
  });
}
