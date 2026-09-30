/// Mock renderer context: unit scale, palette, item and viewport, plus the
/// colour, weight and noise helpers every section uses.
library;


import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' hide Viewport;

import '../data/models.dart';

/// Everything a mock section needs: the unit scale, palette, item and viewport.
///
/// Designs are authored in pixels at the viewport's design width `W`
/// (1440 / 834 / 390). `u(n) = n / W * containerWidth` maps them to logical
/// pixels, so a preview is resolution-independent (§11.1).
class MockCtx {
  const MockCtx({required this.scale, required this.item, required this.vp});

  /// `containerWidth / W`.
  final double scale;
  final Item item;
  final Viewport vp;

  Palette get p => item.palette;

  /// Design units → logical pixels.
  double u(double n) => n * scale;

  /// `pick(vp)(desktop, tablet, mobile)`.
  V v<V>(V desktop, V tablet, V mobile) => vp.pick(desktop, tablet, mobile);

  bool get isDesktop => vp == Viewport.desktop;
  bool get isTablet => vp == Viewport.tablet;
  bool get isMobile => vp == Viewport.mobile;

  /// CSS padding shorthand in design units: `ins(a)`, `ins(a, b)`,
  /// `ins(a, b, c)`, `ins(a, b, c, d)`.
  EdgeInsets ins(double a, [double? b, double? c, double? d]) {
    final top = a;
    final right = b ?? a;
    final bottom = c ?? a;
    final left = d ?? right;
    return EdgeInsets.fromLTRB(u(left), u(top), u(right), u(bottom));
  }
}

/// Deterministic 0..1 from two ints — chart bars and line widths.
///
/// A bit-exact port of the web hash (`Math.imul`, `>>>`), rounded to 4dp, so
/// the same bars come out on every platform.
double noise(int a, [int b = 1]) {
  int imul(int x, int y) => (x.toSigned(32) * y.toSigned(32)).toSigned(32);
  int ushr(int x, int n) => (x & 0xFFFFFFFF) >> n;

  var t = (imul(a, 374761393) + imul(b, 668265263)).toSigned(32);
  t = imul((t ^ ushr(t, 13)).toSigned(32), 1274126177);
  t = (t ^ ushr(t, 16)) & 0xFFFFFFFF;
  return (t / 4294967296 * 10000).round() / 10000;
}

/// Colour at a multiplied opacity (CSS `opacity` folded into the paint).
Color op(Color c, double o) => o >= 1 ? c : c.withValues(alpha: c.a * o);

/// CSS `#rrggbbAA` suffix: the colour with an absolute 0–255 alpha.
Color hexA(Color c, int alpha) => c.withAlpha(alpha);

/// Web variable-font weights (430, 450, 520…) → the nearest [FontWeight].
FontWeight mockWeight(int w) {
  final i = ((w / 100).round() - 1).clamp(0, 8);
  return FontWeight.values[i];
}
