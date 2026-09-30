import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/widgets/core/ui_icon.dart';
import 'package:uiverse/widgets/core/ui_icon_paths.dart';

void main() {
  test('every icon has geometry inside the 24 grid', () {
    // getBounds covers arc control points, which sit a little outside the
    // drawn curve, so allow 2 units of slack around the 24 grid.
    final grid = const Rect.fromLTWH(0, 0, 24, 24).inflate(2);
    for (final icon in Ui.values) {
      final shape = kUiIconShapes[icon];
      expect(shape, isNotNull, reason: '$icon has no generated path');
      final bounds = shape!.stroke.getBounds();
      expect(bounds.isEmpty, isFalse, reason: '$icon is empty');
      expect(grid.contains(bounds.topLeft) && grid.contains(bounds.bottomRight), isTrue,
          reason: '$icon bounds $bounds leave the grid');
    }
    expect(kUiIconShapes[Ui.bookmarkFilled]!.fill, isNotNull);
    expect(kUiIconShapes[Ui.bookmark]!.fill, isNull);
  });

  testWidgets('UiIcon takes its size and exposes a label only when given one', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UiIcon(Ui.search, size: 20, color: Color(0xFF000000), semanticLabel: 'Search'),
            UiIcon(Ui.chevron, size: 13, color: Color(0xFF000000), turns: 0.5),
          ],
        ),
      ),
    ));
    expect(tester.getSize(find.byType(UiIcon).first), const Size.square(20));
    expect(tester.getSize(find.byType(UiIcon).last), const Size.square(13));
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
  });
}
