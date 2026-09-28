import 'package:flutter/material.dart';

import 'uiverse_colors.dart';
import 'uiverse_text.dart';

/// Light/dark [ThemeData] per design-system.md §16.3.
ThemeData uiverseTheme(Brightness b) {
  final c = b == Brightness.light ? UiverseColors.light : UiverseColors.dark;
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final side = BorderSide(color: c.border, width: 1);
  final base = ThemeData(brightness: b, useMaterial3: true, fontFamily: UiText.monoFamily);

  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    extensions: [c],
    colorScheme: ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: c.accentFg,
      secondary: c.signal,
      onSecondary: c.onSignal,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
      onError: c.bg,
      outline: c.border,
      outlineVariant: c.rule,
    ),
    textTheme: base.textTheme
        .apply(bodyColor: c.text, displayColor: c.text, fontFamily: UiText.monoFamily),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    splashFactory: NoSplash.splashFactory,
    highlightColor: c.bgSubtle,
    hoverColor: c.bgSubtle,
    focusColor: c.focus,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: selectionColor(b),
      cursorColor: c.text,
      selectionHandleColor: c.accent,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: square,
        side: side,
        foregroundColor: c.text,
        backgroundColor: c.surface,
        textStyle: UiText.body,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: square.copyWith(side: side),
        backgroundColor: c.accent,
        foregroundColor: c.accentFg,
        textStyle: UiText.button,
        minimumSize: const Size(0, 44),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: square, foregroundColor: c.text, textStyle: UiText.body),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bgSubtle,
      hintStyle: UiText.mono(14, color: c.text3),
      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: side),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: side),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: c.borderStrong),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    dialogTheme: DialogThemeData(
      shape: square.copyWith(side: side),
      backgroundColor: c.bg,
      barrierColor: c.overlay,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: square.copyWith(side: side),
      backgroundColor: c.bg,
      modalBarrierColor: c.overlay,
      elevation: 0,
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: square.copyWith(side: side),
      color: c.surface,
      elevation: 0,
    ),
  );
}

/// Text selection background (§14): `signal`, with the selected text in
/// `on-signal`. Flutter paints the selection under unchanged text colour, so
/// in light mode (ink text) solid signal matches the web; in dark mode the
/// light text would sit on solid yellow at ~1.3:1, so the signal is laid at
/// 40% over the dark surface instead (text stays ≥ 4.5:1).
Color selectionColor(Brightness b) => b == Brightness.light
    ? UiverseColors.light.signal
    : UiverseColors.dark.signal.withValues(alpha: 0.4);
