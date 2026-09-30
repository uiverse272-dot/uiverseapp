import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/app.dart';
import 'package:uiverse/theme/uiverse_colors.dart';
import 'package:uiverse/theme/uiverse_theme.dart';

void main() {
  for (final b in Brightness.values) {
    testWidgets('system bars use bg and contrasting icons in ${b.name}', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: uiverseTheme(b), home: const SizedBox()));
      final style = systemBars(tester.element(find.byType(SizedBox)));
      final c = b == Brightness.light ? UiverseColors.light : UiverseColors.dark;
      final icons = b == Brightness.light ? Brightness.dark : Brightness.light;
      expect(style.statusBarColor, c.bg);
      expect(style.systemNavigationBarColor, c.bg);
      expect(style.statusBarIconBrightness, icons);
      expect(style.systemNavigationBarIconBrightness, icons);
    });
  }
}
