import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/dev/mock_gallery.dart';
import 'package:uiverse/mock/mock_screen.dart';
import 'package:uiverse/theme/uiverse_theme.dart';

void main() {
  testWidgets('mock gallery builds and scrolls without errors', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: uiverseTheme(Brightness.light), home: const MockGalleryPage()));
    expect(find.byType(MockScreen), findsWidgets);
    expect(find.text('saas-landing · Carbon'), findsOneWidget);
    for (var i = 0; i < 30 && find.text('Components (block only)').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pump();
    }
    expect(find.text('Components (block only)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
