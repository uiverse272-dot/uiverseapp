/// The box primitive [B] and its render object.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' hide Viewport;

import 'art.dart';
import 'ctx.dart';

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
