import 'package:flutter/material.dart';

/// Named text styles from design-system.md §3.4.
///
/// Styles carry no colour; apply one at the call site with
/// `.copyWith(color: context.ui.text2)` (see the "Colour" column in §3.4).
/// Uppercase styles (overline, eyebrow, badge) need `.toUpperCase()` on the string.
abstract final class UiText {
  static const String monoFamily = 'SpaceMono';
  static const String displayFamily = 'Lexend';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Space Mono at [size]. Only 400/700 exist: map 500→400, 600→700 (§3.1).
  static TextStyle mono(
    double size, {
    bool bold = false,
    double height = 1.5,
    double track = -0.01,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: monoFamily,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        height: height,
        letterSpacing: track * size,
        color: color,
      );

  static final TextStyle pageTitle = mono(26, bold: true, height: 1.25, track: -0.03);
  static final TextStyle pageSub = mono(13, height: 1.625);
  static final TextStyle detailTitle = mono(19, bold: true, height: 1.375, track: -0.02);
  static final TextStyle groupTitle = mono(17, bold: true, track: -0.02);
  static final TextStyle sectionHead = mono(15, bold: true);
  static final TextStyle panelTitle = mono(14, bold: true, track: -0.015);
  static final TextStyle bodyLg = mono(14, height: 1.625);
  static const TextStyle cardTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.375,
    letterSpacing: -0.01 * 13.5,
    fontFeatures: tabular,
  );
  static final TextStyle button = mono(13.5);
  static final TextStyle body = mono(13);
  static final TextStyle chip = mono(12.5);
  static final TextStyle small = mono(12);
  static final TextStyle caption = mono(11.5);
  static final TextStyle meta = mono(11);
  static final TextStyle overline = mono(11, bold: true, track: 0.025);
  static final TextStyle navLabel = mono(10.5);
  static final TextStyle tabLabel = mono(10);
  static final TextStyle eyebrow = mono(10.5, bold: true, track: 0.12);
  static final TextStyle badge = mono(10, bold: true, height: 1, track: 0.025);
  static final TextStyle monoValue = mono(11.5);
  static final TextStyle code = mono(12, height: 1.625, track: 0);
}
