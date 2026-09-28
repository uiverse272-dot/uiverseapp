import 'package:flutter/material.dart';

@immutable
class UiverseColors extends ThemeExtension<UiverseColors> {
  const UiverseColors({
    required this.bg,
    required this.bgSubtle,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.rule,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentFg,
    required this.signal,
    required this.onSignal,
    required this.focus,
    required this.danger,
    required this.overlay,
  });

  final Color bg, bgSubtle, surface, border, borderStrong, rule;
  final Color text, text2, text3, accent, accentFg, signal, onSignal;
  final Color focus, danger, overlay;

  static const light = UiverseColors(
    bg: Color(0xFFFDF1D6),
    bgSubtle: Color(0xFFF6E4BF),
    surface: Color(0xFFFFF7E6),
    border: Color(0xFF1C1B18),
    borderStrong: Color(0xFF000000),
    rule: Color(0x381C1B18), // 22% of #1c1b18
    text: Color(0xFF1C1B18),
    text2: Color(0xFF4D4A42),
    text3: Color(0xFF7C7667),
    accent: Color(0xFFF47A2C),
    accentFg: Color(0xFF1C1B18),
    signal: Color(0xFFF8DC3D),
    onSignal: Color(0xFF1C1B18),
    focus: Color(0xFFF47A2C),
    danger: Color(0xFFC2331F),
    overlay: Color(0x73281E0A), // rgb(40 30 10 / .45)
  );

  static const dark = UiverseColors(
    bg: Color(0xFF1B1915),
    bgSubtle: Color(0xFF26231D),
    surface: Color(0xFF211E19),
    border: Color(0xFFD8CAA9),
    borderStrong: Color(0xFFF3E6C8),
    rule: Color(0x38D8CAA9),
    text: Color(0xFFF5EAD2),
    text2: Color(0xFFC3B89E),
    text3: Color(0xFF8E856F),
    accent: Color(0xFFF47A2C),
    accentFg: Color(0xFF1B1915),
    signal: Color(0xFFE9CC33),
    onSignal: Color(0xFF1B1915),
    focus: Color(0xFFF47A2C),
    danger: Color(0xFFC2331F),
    overlay: Color(0xB3000000), // black / .70
  );

  /// Theme-independent colours (§2.1 "Hardcoded").
  static const ink = Color(0xFF1C1B18);
  static const paperBadge = Color(0xFFFFF7E6);

  @override
  UiverseColors copyWith() => this;

  @override
  UiverseColors lerp(ThemeExtension<UiverseColors>? other, double t) {
    if (other is! UiverseColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return UiverseColors(
      bg: l(bg, other.bg),
      bgSubtle: l(bgSubtle, other.bgSubtle),
      surface: l(surface, other.surface),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      rule: l(rule, other.rule),
      text: l(text, other.text),
      text2: l(text2, other.text2),
      text3: l(text3, other.text3),
      accent: l(accent, other.accent),
      accentFg: l(accentFg, other.accentFg),
      signal: l(signal, other.signal),
      onSignal: l(onSignal, other.onSignal),
      focus: l(focus, other.focus),
      danger: l(danger, other.danger),
      overlay: l(overlay, other.overlay),
    );
  }
}

extension UiverseX on BuildContext {
  UiverseColors get ui => Theme.of(this).extension<UiverseColors>()!;
}
