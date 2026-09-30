/// Mock renderer primitives (web `primitives.tsx`): flex wrappers, text and
/// shape helpers, re-exporting the context, box, art and bars pieces.
library;


import 'package:flutter/widgets.dart' hide Viewport;

import 'box.dart';
import 'ctx.dart';
import 'flex.dart';

export 'art.dart';
export 'bars.dart';
export 'box.dart';
export 'ctx.dart';
export 'flex.dart' show MAlign, MItem, MJustify;

/* --------------------------------------------------------- flex wrappers */

/// `Row` from primitives.tsx: gap in design units, items centred by default.
class MRow extends MFlex {
  MRow(
    MockCtx c, {
    super.key,
    double gap = 0,
    super.align = MAlign.center,
    super.justify,
    super.pad,
    super.children,
  }) : super(axis: Axis.horizontal, gap: c.u(gap));
}

/// `Col` from primitives.tsx: gap in design units, items stretched by default.
class MCol extends MFlex {
  MCol(
    MockCtx c, {
    super.key,
    double gap = 0,
    super.align = MAlign.stretch,
    super.justify,
    super.pad,
    super.children,
  }) : super(axis: Axis.vertical, gap: c.u(gap));
}

/// `Grid`: equal-width columns; rows stretch to their tallest cell.
class MGrid extends MGridBox {
  MGrid(
    MockCtx c, {
    super.key,
    required super.cols,
    double gap = 0,
    double? rowGap,
    super.pad,
    super.children,
  }) : super(gap: c.u(gap), rowGap: c.u(rowGap ?? gap));
}

/// A fixed vertical/horizontal space in design units.
Widget gapBox(MockCtx c, {double w = 0, double h = 0}) => SizedBox(width: c.u(w), height: c.u(h));

/* ------------------------------------------------------------------- T */

/// Text: system sans, line-height 1.16, tracking −0.028em above 40 design px
/// else −0.011em (§11.3). Never scaled by the OS text size — it is a picture.
class T extends StatelessWidget {
  const T(
    this.c,
    this.text, {
    super.key,
    required this.size,
    this.weight = 400,
    this.color,
    this.align,
    this.height,
    this.track,
    this.maxW,
    this.o = 1,
  });

  final MockCtx c;
  final String text;
  final double size;
  final int weight;
  final Color? color;
  final TextAlign? align;

  /// Line-height override (web default 1.16).
  final double? height;

  /// Letter spacing in em.
  final double? track;

  /// Max width in design units.
  final double? maxW;
  final double o;

  @override
  Widget build(BuildContext context) {
    final px = c.u(size);
    final em = track ?? (size > 40 ? -0.028 : -0.011);
    final text = RichText(
      textAlign: align ?? TextAlign.start,
      textScaler: TextScaler.noScaling,
      text: TextSpan(
        text: this.text,
        style: TextStyle(
          inherit: false,
          color: op(color ?? c.p.text, o),
          fontSize: px,
          fontWeight: mockWeight(weight),
          height: height ?? 1.16,
          leadingDistribution: TextLeadingDistribution.even,
          letterSpacing: px * em,
        ),
      ),
    );
    if (maxW == null) return text;
    return B(c, maxW: maxW, child: text);
  }
}

/* ------------------------------------------------------------- shapes */

/// A placeholder text bar. Width in design units ([w]) or a fraction ([wf]).
B line(MockCtx c, {double? w, double? wf, double h = 10, required Color col, double o = 0.18, double r = 3}) =>
    B(c, w: w, wf: w == null ? wf : null, h: h, r: r, bg: col, o: o);

/// [n] placeholder bars, the last one [last] wide.
Widget lines(
  MockCtx c, {
  required int n,
  double? w,
  double h = 10,
  double gap = 8,
  required Color col,
  double o = 0.15,
  double last = 0.6,
}) {
  final col_ = MCol(c, gap: gap, children: [
    for (var i = 0; i < n; i++) line(c, wf: i == n - 1 ? last : 1, h: h, col: col, o: o),
  ]);
  return w == null ? col_ : B(c, w: w, child: col_);
}

B circle(MockCtx c, double s, {Color? bg, double o = 1, Color? border, double bw = 1}) =>
    B(c, w: s, h: s, r: 999, bg: bg, o: o, border: border, bw: bw);

/// Pill/rect button; `w: 0` fills the parent's width.
B btn(
  MockCtx c, {
  String? label,
  double w = 132,
  double h = 44,
  double r = 8,
  Color? bg,
  Color? fg,
  double size = 15,
  Color? border,
}) =>
    B(
      c,
      w: w == 0 ? null : w,
      wf: w == 0 ? 1 : null,
      h: h,
      r: r,
      bg: bg,
      border: border,
      align: Alignment.center,
      child: label == null ? null : T(c, label, size: size, weight: 520, color: fg),
    );

/// The collapsed-navigation affordance.
Widget burger(MockCtx c, Color col, {double s = 22}) => B(
      c,
      w: s,
      child: MCol(c, gap: s * 0.22, children: [
        for (var i = 0; i < 3; i++) B(c, w: s, h: s * 0.09, r: 2, bg: col, o: 0.8),
      ]),
    );
