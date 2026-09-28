import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/format.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/data/palettes.dart';
import 'package:uiverse/screens/source/source_data.dart';

import '../search/discovery_harness.dart';

void main() {
  group('sourceView', () {
    test('unknown slug → null', () => expect(sourceView('nope'), isNull));

    test('splits items and infers the palette from the first screen', () {
      final v = sourceView('ledgerly')!;
      final all = kItems.where((i) => i.source.slug == 'ledgerly').toList();
      expect(v.all.length, all.length);
      expect(v.screens.every((i) => i.kind == Kind.screen), isTrue);
      expect(v.components.every((i) => i.kind == Kind.component), isTrue);
      expect(v.screens.length + v.components.length, all.length);
      expect(v.palette, same(v.screens.first.palette));
      expect(v.totalSaves, all.fold<int>(0, (a, i) => a + i.saves));
      expect(v.paletteRows.map((r) => r.$1), ['Background', 'Surface', 'Raised', 'Border', 'Text', 'Muted', 'Accent']);
      expect(v.recurringBlocks.toSet().length, v.recurringBlocks.length);
    });

    test('tabs: Screens / Components with counts, Palette & type without', () {
      final v = sourceView('ledgerly')!;
      expect(sourceTabs(v), [
        ('screens', 'Screens', v.screens.length),
        ('components', 'Components', v.components.length),
        ('system', 'Palette & type', 0),
      ]);
    });
  });

  for (final double width in <double>[390, 1024]) {
    testWidgets('header, chips, totals and tabs ($width)', (tester) async {
      await pumpDiscovery(tester, width: width, location: '/source/ledgerly');
      final v = sourceView('ledgerly')!;
      expect(find.text('Ledgerly'), findsWidgets);
      expect(find.text('Business banking and spend management for operators.'), findsOneWidget);
      expect(find.text('ledgerly.com'), findsOneWidget);
      expect(find.text('Fintech'), findsOneWidget);
      expect(find.text('Next.js'), findsOneWidget);
      expect(find.text('· ${compact(v.totalSaves)} saves across ${v.all.length} items'), findsOneWidget);
      expect(find.text('Screens ${v.screens.length}'), findsOneWidget);
      expect(find.text('Components ${v.components.length}'), findsOneWidget);
      expect(find.text('Palette & type'), findsOneWidget);
      expect(find.text('Homepage'), findsOneWidget);
    });

    testWidgets('system tab shows palette and structure ($width)', (tester) async {
      await pumpDiscovery(tester, width: width, location: '/source/ledgerly?tab=system');
      final v = sourceView('ledgerly')!;
      expect(find.text('Inferred palette'), findsOneWidget);
      expect(find.text('Accent'), findsOneWidget);
      expect(find.text(hexOf(v.palette!.accent)), findsWidgets);
      await tester.scrollUntilVisible(find.text('Recurring structure'), 300, scrollable: find.byType(Scrollable).last);
      expect(find.text('Recurring structure'), findsOneWidget);
      expect(find.text(v.recurringBlocks.first), findsOneWidget);
    });
  }

  testWidgets('tabs switch via ?tab=', (tester) async {
    final app = await pumpDiscovery(tester, location: '/source/ledgerly');
    final v = sourceView('ledgerly')!;
    await tester.tap(find.text('Components ${v.components.length}'));
    await tester.pumpAndSettle();
    expect(locationOf(app.router), '/source/ledgerly?tab=components');
    expect(find.text('Homepage'), findsNothing);

    // The tab row scrolls horizontally at phone width.
    await tester.ensureVisible(find.text('Palette & type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Palette & type'));
    await tester.pumpAndSettle();
    expect(find.text('Inferred palette'), findsOneWidget);
  });

  testWidgets('industry chip opens the filtered feed', (tester) async {
    final app = await pumpDiscovery(tester, location: '/source/ledgerly');
    await tester.tap(find.text('Fintech'));
    await tester.pumpAndSettle();
    expect(locationOf(app.router), '/web?industry=fintech');
  });

  testWidgets('unknown slug shows Not found', (tester) async {
    await pumpDiscovery(tester, location: '/source/nope');
    expect(find.text('Not found'), findsOneWidget);
    expect(find.text('Back to the feed'), findsOneWidget);
  });
}
