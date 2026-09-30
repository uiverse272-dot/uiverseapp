/// Chart bars painted in one pass.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Viewport;


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
