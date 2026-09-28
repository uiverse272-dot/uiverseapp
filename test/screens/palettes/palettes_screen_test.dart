import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/palettes.dart';
import 'package:uiverse/screens/palettes/palettes_screen.dart';

import '../../support/clipboard_mock.dart';
import '../directory/directory_harness.dart';

void main() {
  final PaletteEntry first = kPaletteItems.first;

  test('paletteSwatches lists bg, surface, raised, accent, text', () {
    final roles = paletteSwatches(first.palette);
    expect(roles.map((r) => r.token), ['bg', 'surface', 'raised', 'accent', 'text']);
    expect(roles.first.value, hexOf(first.palette.bg));
  });

  for (final double width in [390, 1024]) {
    testWidgets('renders palette cards without overflow at $width', (tester) async {
      await pumpDirectory(tester, location: '/palettes', width: width);
      expect(find.text(first.palette.name), findsOneWidget);
      expect(find.text('from ${first.source.name}'), findsWidgets);
      expect(find.bySemanticsLabel('Copy ${hexOf(first.palette.accent)}'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('CSS vars and Tailwind copy the palette', (tester) async {
    final clip = FakeClipboard.install();
    addTearDown(FakeClipboard.uninstall);
    await pumpDirectory(tester, location: '/palettes', width: 1024);

    await tester.tap(find.bySemanticsLabel('CSS vars').first);
    await tester.pump();
    expect(clip.text, contains('  --bg: ${hexOf(first.palette.bg)};'));
    expect(clip.text, contains('  --text: ${hexOf(first.palette.text)};'));

    await tester.tap(find.bySemanticsLabel('Tailwind').first);
    await tester.pump();
    expect(clip.text, startsWith('@theme {\n  --color-bg: '));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('"from {source}" opens the source page', (tester) async {
    final router = await pumpDirectory(tester, location: '/palettes', width: 1024);
    await tapVisible(tester, find.text('from ${first.source.name}').first);
    expect(locationOf(router), '/source/${first.source.slug}');
  });
}
