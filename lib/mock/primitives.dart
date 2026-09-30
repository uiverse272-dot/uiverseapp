import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' hide Viewport;

import '../data/models.dart';
import 'flex.dart';

export 'flex.dart' show MAlign, MItem, MJustify;

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

/* ------------------------------------------------------------------ art */

/// A decorative paint layer drawn inside a [B]'s rounded rect (gradients,
/// glows, blobs) — the web's absolutely positioned decoration `div`s.
sealed class ArtLayer {
  const ArtLayer();
  void paint(Canvas canvas, Rect r);
}

/// `radial-gradient(rx ry at fx fy, color, transparent stop)`.
class Radial extends ArtLayer {
  const Radial({
    required this.fx,
    required this.fy,
    required this.rx,
    required this.ry,
    required this.color,
    this.stop = 0.7,
  });

  final double fx, fy, rx, ry, stop;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is Radial &&
      other.fx == fx &&
      other.fy == fy &&
      other.rx == rx &&
      other.ry == ry &&
      other.stop == stop &&
      other.color == color;

  @override
  int get hashCode => Object.hash(fx, fy, rx, ry, stop, color);

  @override
  void paint(Canvas canvas, Rect r) {
    if (rx <= 0 || ry <= 0) return;
    final cx = r.left + r.width * fx;
    final cy = r.top + r.height * fy;
    final sy = ry / rx;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1, sy);
    final paint = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, rx, [color, color.withAlpha(0)], [0, stop]);
    canvas.drawRect(
      Rect.fromLTRB(r.left - cx, (r.top - cy) / sy, r.right - cx, (r.bottom - cy) / sy),
      paint,
    );
    canvas.restore();
  }
}

/// `linear-gradient(<angle>deg, colors…)`; a null colour is `transparent`.
class Linear extends ArtLayer {
  const Linear(this.angle, this.colors, this.stops);

  final double angle;
  final List<Color?> colors;
  final List<double> stops;

  @override
  bool operator ==(Object other) =>
      other is Linear &&
      other.angle == angle &&
      listEquals(other.colors, colors) &&
      listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hash(angle, Object.hashAll(colors), Object.hashAll(stops));

  @override
  void paint(Canvas canvas, Rect r) {
    final a = angle * math.pi / 180;
    final dir = Offset(math.sin(a), -math.cos(a));
    final half = (r.width * math.sin(a).abs() + r.height * math.cos(a).abs()) / 2;
    final c = r.center;
    final resolved = <Color>[];
    for (var i = 0; i < colors.length; i++) {
      final col = colors[i];
      resolved.add(col ?? (i > 0 ? resolved[i - 1].withAlpha(0) : const Color(0x00000000)));
    }
    final paint = Paint()
      ..shader = ui.Gradient.linear(c - dir * half, c + dir * half, resolved, stops);
    canvas.drawRect(r, paint);
  }
}

/// An absolutely positioned (rounded) rect or ellipse. Position is
/// `fraction of the frame + pixel offset` on each axis.
class Disc extends ArtLayer {
  const Disc({
    this.fx = 0,
    this.dx = 0,
    this.fy = 0,
    this.dy = 0,
    required this.w,
    required this.h,
    this.r,
    this.fill,
    this.stroke,
    this.strokeW = 1,
  });

  final double fx, dx, fy, dy, w, h, strokeW;

  /// Corner radius; null = ellipse.
  final double? r;
  final Color? fill;
  final Color? stroke;

  @override
  bool operator ==(Object other) =>
      other is Disc &&
      other.fx == fx &&
      other.dx == dx &&
      other.fy == fy &&
      other.dy == dy &&
      other.w == w &&
      other.h == h &&
      other.strokeW == strokeW &&
      other.r == r &&
      other.fill == fill &&
      other.stroke == stroke;

  @override
  int get hashCode => Object.hash(fx, dx, fy, dy, w, h, strokeW, r, fill, stroke);

  @override
  void paint(Canvas canvas, Rect frame) {
    final rect = Rect.fromLTWH(frame.left + frame.width * fx + dx, frame.top + frame.height * fy + dy, w, h);
    if (fill != null) {
      final p = Paint()..color = fill!;
      if (r == null) {
        canvas.drawOval(rect, p);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r!)), p);
      }
    }
    if (stroke != null) {
      final p = Paint()
        ..color = stroke!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW;
      final inner = rect.deflate(strokeW / 2);
      if (r == null) {
        canvas.drawOval(inner, p);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(math.max(0, r! - strokeW / 2))), p);
      }
    }
  }
}

/* -------------------------------------------------------------------- B */

/// The box primitive: explicit width/height (design units or a fraction of
/// the available space), radius, background, 1u border (or single sides),
/// padding, decorative [layers], optional clipping and child alignment.
///
/// Sizing follows CSS: an explicit size wins (and the box sits at the start
/// if a stretching parent offers more); otherwise the box takes what the
/// parent forces and shrink-wraps its child. The child fills the width like
/// a block; with [fill] it also fills the height (a flex container child).
class B extends SingleChildRenderObjectWidget {
  B(
    MockCtx c, {
    super.key,
    double? w,
    this.wf,
    double? h,
    this.hf,
    double? maxW,
    double r = 0,
    Color? bg,
    Color? border,
    double bw = 1,
    Color? bt,
    Color? bb,
    Color? bl,
    Color? br,
    this.pad = EdgeInsets.zero,
    this.align,
    this.fill = false,
    this.clip = false,
    this.layers = const [],
    double o = 1,
    super.child,
  })  : w = w == null ? null : c.u(w),
        h = h == null ? null : c.u(h),
        maxW = maxW == null ? null : c.u(maxW),
        r = c.u(r),
        bg = bg == null ? null : op(bg, o),
        border = border == null ? null : op(border, o),
        bt = bt == null ? null : op(bt, o),
        bb = bb == null ? null : op(bb, o),
        bl = bl == null ? null : op(bl, o),
        br = br == null ? null : op(br, o),
        line = c.u(bw);

  final double? w, h, wf, hf, maxW;
  final double r, line;
  final Color? bg, border, bt, bb, bl, br;
  final EdgeInsets pad;
  final Alignment? align;
  final bool fill, clip;
  final List<ArtLayer> layers;

  @override
  RenderMBox createRenderObject(BuildContext context) => RenderMBox()..configure(this);

  @override
  void updateRenderObject(BuildContext context, RenderMBox renderObject) => renderObject.configure(this);
}

class RenderMBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  double? _w, _h, _wf, _hf, _maxW;
  double _r = 0, _line = 1;
  Color? _bg, _border, _bt, _bb, _bl, _br;
  EdgeInsets _pad = EdgeInsets.zero;
  Alignment? _align;
  bool _fill = false, _clip = false;
  List<ArtLayer> _layers = const [];

  Size _deco = Size.zero;
  final LayerHandle<ClipRRectLayer> _clipLayer = LayerHandle<ClipRRectLayer>();
  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  // One scratch paint per box: paint() runs for every box of every mock.
  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  void configure(B b) {
    final layout = _w != b.w ||
        _h != b.h ||
        _wf != b.wf ||
        _hf != b.hf ||
        _maxW != b.maxW ||
        _pad != b.pad ||
        _align != b.align ||
        _fill != b.fill;
    final paint = layout ||
        _r != b.r ||
        _line != b.line ||
        _bg != b.bg ||
        _border != b.border ||
        _bt != b.bt ||
        _bb != b.bb ||
        _bl != b.bl ||
        _br != b.br ||
        _clip != b.clip ||
        !listEquals(_layers, b.layers);
    _w = b.w;
    _h = b.h;
    _wf = b.wf;
    _hf = b.hf;
    _maxW = b.maxW;
    _r = b.r;
    _line = b.line;
    _bg = b.bg;
    _border = b.border;
    _bt = b.bt;
    _bb = b.bb;
    _bl = b.bl;
    _br = b.br;
    _pad = b.pad;
    _align = b.align;
    _fill = b.fill;
    _clip = b.clip;
    _layers = b.layers;
    if (layout) {
      markNeedsLayout();
    } else if (paint) {
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    var c = constraints;
    if (_maxW != null && _maxW! < c.maxWidth) {
      // CSS max-width: cap the box; a stretching parent's extra room is left
      // empty after it.
      final cap = _maxW!;
      c = c.copyWith(maxWidth: cap, minWidth: math.min(c.minWidth, cap));
    }
    final ew = _w ?? (_wf != null ? (c.hasBoundedWidth ? c.maxWidth * _wf! : 0.0) : null);
    final eh = _h ?? (_hf != null ? (c.hasBoundedHeight ? c.maxHeight * _hf! : 0.0) : null);
    final ph = _pad.horizontal;
    final pv = _pad.vertical;
    var inner = Size.zero;
    final kid = child;
    if (kid != null) {
      double minW, maxW, minH, maxH;
      if (ew != null) {
        minW = maxW = math.max(0, ew - ph);
      } else {
        minW = math.max(0, c.minWidth - ph);
        maxW = math.max(0, c.maxWidth - ph);
      }
      if (eh != null) {
        maxH = math.max(0, eh - pv);
        minH = _fill ? maxH : 0;
      } else {
        maxH = math.max(0, c.maxHeight - pv);
        minH = _fill ? math.max(0, c.minHeight - pv) : 0;
      }
      if (_align != null) {
        minW = 0;
        minH = 0;
      }
      kid.layout(BoxConstraints(minWidth: minW, maxWidth: maxW, minHeight: minH, maxHeight: maxH),
          parentUsesSize: true);
      inner = kid.size;
    }
    final bw = ew ?? c.constrainWidth(inner.width + ph);
    final bh = eh ?? c.constrainHeight(inner.height + pv);
    _deco = Size(bw, bh);
    size = constraints.constrain(_deco);
    if (kid != null) {
      var off = _pad.topLeft;
      if (_align != null) {
        final room = Size(_deco.width - ph, _deco.height - pv);
        off += _align!.alongOffset((room - kid.size) as Offset);
      }
      (kid.parentData! as BoxParentData).offset = off;
    }
  }

  RRect _rrect(Offset offset) {
    final rect = offset & _deco;
    final rad = math.min(_r, _deco.shortestSide / 2);
    return RRect.fromRectAndRadius(rect, Radius.circular(rad));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final rect = offset & _deco;
    final rounded = _r > 0;
    final rrect = rounded ? _rrect(offset) : null;
    if (_bg != null) {
      _fillPaint.color = _bg!;
      rounded ? canvas.drawRRect(rrect!, _fillPaint) : canvas.drawRect(rect, _fillPaint);
    }
    if (_layers.isNotEmpty) {
      canvas.save();
      // Square boxes clip on pixel edges: no anti-aliasing needed.
      rounded ? canvas.clipRRect(rrect!) : canvas.clipRect(rect, doAntiAlias: false);
      for (final l in _layers) {
        l.paint(canvas, rect);
      }
      canvas.restore();
    }
    if (_border != null) {
      _strokePaint
        ..color = _border!
        ..strokeWidth = _line;
      final d = _line / 2;
      if (rounded) {
        canvas.drawRRect(rrect!.deflate(d), _strokePaint);
      } else {
        canvas.drawRect(rect.deflate(d), _strokePaint);
      }
    }
    if (_bt != null) {
      canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, _line), _fillPaint..color = _bt!);
    }
    if (_bb != null) {
      canvas.drawRect(Rect.fromLTWH(rect.left, rect.bottom - _line, rect.width, _line), _fillPaint..color = _bb!);
    }
    if (_bl != null) {
      canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, _line, rect.height), _fillPaint..color = _bl!);
    }
    if (_br != null) {
      canvas.drawRect(Rect.fromLTWH(rect.right - _line, rect.top, _line, rect.height), _fillPaint..color = _br!);
    }

    final kid = child;
    if (kid == null) return;
    final childOffset = (kid.parentData! as BoxParentData).offset;
    if (_clip && rounded) {
      _clipRectLayer.layer = null;
      _clipLayer.layer = context.pushClipRRect(
        needsCompositing,
        offset,
        Offset.zero & _deco,
        _rrect(Offset.zero),
        (ctx, o) => ctx.paintChild(kid, o + childOffset),
        oldLayer: _clipLayer.layer,
      );
    } else if (_clip) {
      _clipLayer.layer = null;
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & _deco,
        (ctx, o) => ctx.paintChild(kid, o + childOffset),
        clipBehavior: Clip.hardEdge,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipLayer.layer = null;
      _clipRectLayer.layer = null;
      context.paintChild(kid, offset + childOffset);
    }
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final kid = child;
    if (kid == null) return false;
    final off = (kid.parentData! as BoxParentData).offset;
    return result.addWithPaintOffset(
      offset: off,
      position: position,
      hitTest: (r, p) => kid.hitTest(r, position: p),
    );
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }
}

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

/* --------------------------------------------------------------- bars */

/// One bar column: stacked segments from the bottom, heights as fractions
/// of the drawing height, separated by [sep] px.
class BarSeg {
  const BarSeg(this.frac, this.color);
  final double frac;
  final Color color;

  @override
  bool operator ==(Object other) => other is BarSeg && other.frac == frac && other.color == color;

  @override
  int get hashCode => Object.hash(frac, color);
}

/// Equal-width bar columns painted in one pass (chart panels). Fills whatever
/// size its parent gives it — zero when unconstrained, like a `%` height.
class Bars extends LeafRenderObjectWidget {
  const Bars({super.key, required this.columns, required this.gap, required this.radius, this.sep = 0});

  final List<List<BarSeg>> columns;
  final double gap, radius, sep;

  bool _sameAs(Bars o) {
    if (o.gap != gap || o.radius != radius || o.sep != sep || o.columns.length != columns.length) return false;
    for (var i = 0; i < columns.length; i++) {
      if (!listEquals(o.columns[i], columns[i])) return false;
    }
    return true;
  }

  @override
  RenderBars createRenderObject(BuildContext context) => RenderBars(this);

  @override
  void updateRenderObject(BuildContext context, RenderBars renderObject) => renderObject.spec = this;
}

class RenderBars extends RenderBox {
  RenderBars(this._spec);

  Bars _spec;
  set spec(Bars s) {
    final same = s._sameAs(_spec);
    _spec = s;
    if (!same) markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.smallest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final cols = _spec.columns;
    if (cols.isEmpty || size.isEmpty) return;
    final n = cols.length;
    final colW = (size.width - _spec.gap * (n - 1)) / n;
    if (colW <= 0) return;
    final canvas = context.canvas;
    final paint = Paint();
    for (var i = 0; i < n; i++) {
      final x = offset.dx + i * (colW + _spec.gap);
      var bottom = offset.dy + size.height;
      for (final seg in cols[i].reversed) {
        final h = size.height * seg.frac;
        final rect = Rect.fromLTWH(x, bottom - h, colW, h);
        final rad = math.min(_spec.radius, math.min(colW, h) / 2);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(rad)), paint..color = seg.color);
        bottom -= h + _spec.sep;
      }
    }
  }
}
