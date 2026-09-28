import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/screens/layouts/layouts_screen.dart';

import '../directory/directory_harness.dart';

void main() {
  final LayoutEntry first = kLayouts.first;

  test('helpers: component feed link and skeleton heights', () {
    expect(componentFeedFor('navbar'), '/components?component=navbar');
    expect(skeletonHeight('hero'), 26);
    expect(skeletonHeight('footer'), 14);
    expect(skeletonHeight('pricing'), 11);
  });

  for (final double width in [390, 1024]) {
    testWidgets('renders layout cards without overflow at $width', (tester) async {
      await pumpDirectory(tester, location: '/layouts', width: width);
      expect(find.text(first.name), findsOneWidget);
      expect(find.text('${first.uses} uses'), findsOneWidget);
      expect(find.bySemanticsLabel('Duplicate'), findsWidgets);
      expect(find.bySemanticsLabel('Open in builder'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a section link opens that component feed', (tester) async {
    final router = await pumpDirectory(tester, location: '/layouts', width: 1024);
    final block = first.sections.first;
    await tapVisible(tester, find.text(block.label).first);
    expect(locationOf(router), '/components?component=${block.type}');
  });

  testWidgets('footer note about the Phase 3 builder', (tester) async {
    await pumpDirectory(tester, location: '/layouts', width: 1280);
    final footer = find.textContaining('The drag-and-drop builder is Phase 3.');
    await tester.scrollUntilVisible(
      footer,
      400,
      scrollable: find.descendant(of: find.byType(LayoutsScreen), matching: find.byType(Scrollable)).first,
    );
    expect(footer, findsOneWidget);
  });
}
