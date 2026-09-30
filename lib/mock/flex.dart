// Private setters back these fields; named params cannot be private formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A small CSS-flexbox / CSS-grid layout engine for the mock renderer.
///
/// The web renderer is written against CSS flexbox, whose semantics differ from
/// Flutter's [Flex] in ways the port relies on:
///
/// * items keep their content size (basis) and `grow` shares out *positive*
///   free space only — a column with a min height but unbounded max still
///   grows its `grow` children, which is how "fill the frame, but follow the
///   content when it is taller" works without intrinsics;
/// * `stretch` (the column default) makes children fill the cross axis, but
///   explicitly sized primitives keep their size and sit at the start;
/// * overflow is simply painted (and clipped by the preview frame) instead of
///   being reported as a layout error — a preview is a screenshot, and content
///   running off the edge of it is normal.
///
/// Nothing here computes intrinsics, so every layout is a single measuring
/// pass plus a second pass only for growing / stretched children.

enum MAlign { start, center, end, stretch }

enum MJustify { start, center, end, spaceBetween, spaceAround }

class MParentData extends ContainerBoxParentData<RenderBox> {
  /// `flex-grow` with a content basis.
  double grow = 0;

  /// `flex: n` — grow n with a zero basis (equal-width columns).
  double flex = 0;

  /// `margin-<start>: auto` — soaks up the free space before this child.
  bool autoBefore = false;

  /// Grid column span.
  int span = 1;

  /// `max-width`/`max-height` along the main axis while growing, in px.
  double maxMain = double.infinity;

  /// Scratch for [RenderMFlex.performLayout]: this child's main-axis size so
  /// far (kept here instead of a list allocated on every layout).
  double basis = 0;
}

/// Per-child flex / grid settings. Must be a direct child of [MFlex]/[MGridBox].
class MItem extends ParentDataWidget<MParentData> {
  const MItem({
    super.key,
    this.grow = 0,
    this.flex = 0,
    this.autoBefore = false,
    this.span = 1,
    this.maxMain = double.infinity,
    required super.child,
  });

  final double grow;
  final double flex;
  final bool autoBefore;
  final int span;
  final double maxMain;

  @override
  void applyParentData(RenderObject renderObject) {
    final pd = renderObject.parentData! as MParentData;
    var dirty = false;
    if (pd.grow != grow) {
      pd.grow = grow;
      dirty = true;
    }
    if (pd.flex != flex) {
      pd.flex = flex;
      dirty = true;
    }
    if (pd.autoBefore != autoBefore) {
      pd.autoBefore = autoBefore;
      dirty = true;
    }
    if (pd.span != span) {
      pd.span = span;
      dirty = true;
    }
    if (pd.maxMain != maxMain) {
      pd.maxMain = maxMain;
      dirty = true;
    }
    if (dirty) renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => MFlex;
}

/// CSS-style flex container. See the library comment.
class MFlex extends MultiChildRenderObjectWidget {
  const MFlex({
    super.key,
    required this.axis,
    this.gap = 0,
    this.align = MAlign.start,
    this.justify = MJustify.start,
    this.pad = EdgeInsets.zero,
    super.children,
  });

  final Axis axis;

  /// Gap between children, in logical pixels.
  final double gap;
  final MAlign align;
  final MJustify justify;

  /// Inner padding, in logical pixels.
  final EdgeInsets pad;

  @override
  RenderMFlex createRenderObject(BuildContext context) =>
      RenderMFlex(axis: axis, gap: gap, align: align, justify: justify, pad: pad);

  @override
  void updateRenderObject(BuildContext context, RenderMFlex renderObject) {
    renderObject
      ..axis = axis
      ..gap = gap
      ..align = align
      ..justify = justify
      ..pad = pad;
  }
}

class RenderMFlex extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MParentData> {
  RenderMFlex({
    required Axis axis,
    required double gap,
    required MAlign align,
    required MJustify justify,
    required EdgeInsets pad,
  })  : _axis = axis,
        _gap = gap,
        _align = align,
        _justify = justify,
        _pad = pad;

  Axis _axis;
  set axis(Axis v) {
    if (v == _axis) return;
    _axis = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  MAlign _align;
  set align(MAlign v) {
    if (v == _align) return;
    _align = v;
    markNeedsLayout();
  }

  MJustify _justify;
  set justify(MJustify v) {
    if (v == _justify) return;
    _justify = v;
    markNeedsLayout();
  }

  EdgeInsets _pad;
  set pad(EdgeInsets v) {
    if (v == _pad) return;
    _pad = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MParentData) child.parentData = MParentData();
  }

  bool get _h => _axis == Axis.horizontal;

  BoxConstraints _make(double mainMin, double mainMax, double crossMin, double crossMax) => _h
      ? BoxConstraints(minWidth: mainMin, maxWidth: mainMax, minHeight: crossMin, maxHeight: crossMax)
      : BoxConstraints(minWidth: crossMin, maxWidth: crossMax, minHeight: mainMin, maxHeight: mainMax);

  double _main(Size s) => _h ? s.width : s.height;
  double _cross(Size s) => _h ? s.height : s.width;

  @override
  void performLayout() {
    final outer = constraints;
    final c = outer.deflate(_pad);
    final mainMin = _h ? c.minWidth : c.minHeight;
    final mainMax = _h ? c.maxWidth : c.maxHeight;
    final crossMin = _h ? c.minHeight : c.minWidth;
    final crossMax = _h ? c.maxHeight : c.maxWidth;
    final crossTight = crossMin >= crossMax;
    final stretch = _align == MAlign.stretch;
    final mainBounded = mainMax.isFinite;

    // Children measured with a tight cross size when we can stretch straight
    // away; loosely otherwise.
    final crossLo = stretch && crossTight ? crossMax : 0.0;
    final crossHi = crossMax;

    var n = 0;
    var content = 0.0;
    var sumFactor = 0.0;
    var sumGrowBasis = 0.0;

    var child = firstChild;
    while (child != null) {
      final pd = child.parentData! as MParentData;
      n++;
      if (pd.flex > 0 && mainBounded) {
        pd.basis = 0;
        sumFactor += pd.flex;
      } else {
        // Widths resolve top-down (a `%` bar is a share of the row), heights
        // bottom-up (a column child is as tall as its content).
        child.layout(_make(0, _h ? mainMax : double.infinity, crossLo, crossHi), parentUsesSize: true);
        final basis = _main(child.size);
        pd.basis = basis;
        content += basis;
        final g = pd.flex > 0 ? pd.flex : pd.grow;
        if (g > 0) {
          sumFactor += g;
          sumGrowBasis += basis;
        }
      }
      child = childAfter(child);
    }
    final gaps = n > 1 ? _gap * (n - 1) : 0.0;
    content += gaps;
    final mainSize = content.clamp(mainMin, mainMax).toDouble();
    final free = mainSize - content;

    // Grow (or shrink) the flexible children.
    if (sumFactor > 0) {
      child = firstChild;
      while (child != null) {
        final pd = child.parentData! as MParentData;
        final basis0 = pd.flex > 0 && mainBounded;
        final g = pd.flex > 0 ? pd.flex : pd.grow;
        if (g > 0) {
          double target;
          if (free > 0) {
            target = pd.basis + free * g / sumFactor;
          } else if (basis0) {
            target = 0;
          } else if (free < 0 && sumGrowBasis > 0) {
            target = math.max(0, pd.basis + free * pd.basis / sumGrowBasis);
          } else {
            target = pd.basis;
          }
          target = math.min(target, pd.maxMain);
          if (basis0 || target != pd.basis) {
            child.layout(_make(target, target, crossLo, crossHi), parentUsesSize: true);
            pd.basis = _main(child.size);
          }
        }
        child = childAfter(child);
      }
    }

    // Cross size.
    var crossSize = 0.0;
    if (crossTight) {
      crossSize = crossMax;
    } else {
      child = firstChild;
      while (child != null) {
        crossSize = math.max(crossSize, _cross(child.size));
        child = childAfter(child);
      }
      crossSize = crossSize.clamp(crossMin, crossMax).toDouble();
    }
    if (stretch && !crossTight) {
      child = firstChild;
      while (child != null) {
        if (_cross(child.size) != crossSize) {
          final pd = child.parentData! as MParentData;
          final m = pd.basis;
          child.layout(_make(m, m, crossSize, crossSize), parentUsesSize: true);
          pd.basis = _main(child.size);
        }
        child = childAfter(child);
      }
    }

    // Position along the main axis.
    var used = gaps;
    var autos = 0;
    child = firstChild;
    while (child != null) {
      used += _main(child.size);
      if ((child.parentData! as MParentData).autoBefore) autos++;
      child = childAfter(child);
    }
    final remaining = mainSize - used;
    var lead = 0.0;
    var between = 0.0;
    var autoExtra = 0.0;
    if (remaining > 0) {
      if (autos > 0) {
        autoExtra = remaining / autos;
      } else {
        switch (_justify) {
          case MJustify.start:
            break;
          case MJustify.center:
            lead = remaining / 2;
          case MJustify.end:
            lead = remaining;
          case MJustify.spaceBetween:
            between = n > 1 ? remaining / (n - 1) : 0;
          case MJustify.spaceAround:
            between = remaining / n;
            lead = between / 2;
        }
      }
    }

    var pos = lead;
    child = firstChild;
    while (child != null) {
      final pd = child.parentData! as MParentData;
      if (pd.autoBefore) pos += autoExtra;
      final cs = _cross(child.size);
      final crossPos = switch (_align) {
        MAlign.start || MAlign.stretch => 0.0,
        MAlign.center => (crossSize - cs) / 2,
        MAlign.end => crossSize - cs,
      };
      pd.offset = _h
          ? Offset(_pad.left + pos, _pad.top + crossPos)
          : Offset(_pad.left + crossPos, _pad.top + pos);
      pos += _main(child.size) + _gap + between;
      child = childAfter(child);
    }

    final inner = _h ? Size(mainSize, crossSize) : Size(crossSize, mainSize);
    size = outer.constrain(Size(inner.width + _pad.horizontal, inner.height + _pad.vertical));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// CSS grid with `repeat(cols, minmax(0, 1fr))` columns and stretched rows.
class MGridBox extends MultiChildRenderObjectWidget {
  const MGridBox({
    super.key,
    required this.cols,
    this.gap = 0,
    this.rowGap = 0,
    this.pad = EdgeInsets.zero,
    super.children,
  });

  final int cols;
  final double gap;
  final double rowGap;
  final EdgeInsets pad;

  @override
  RenderMGrid createRenderObject(BuildContext context) =>
      RenderMGrid(cols: cols, gap: gap, rowGap: rowGap, pad: pad);

  @override
  void updateRenderObject(BuildContext context, RenderMGrid renderObject) {
    renderObject
      ..cols = cols
      ..gap = gap
      ..rowGap = rowGap
      ..pad = pad;
  }
}

class RenderMGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MParentData> {
  RenderMGrid({required int cols, required double gap, required double rowGap, required EdgeInsets pad})
      : _cols = cols,
        _gap = gap,
        _rowGap = rowGap,
        _pad = pad;

  int _cols;
  set cols(int v) {
    if (v == _cols) return;
    _cols = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _rowGap;
  set rowGap(double v) {
    if (v == _rowGap) return;
    _rowGap = v;
    markNeedsLayout();
  }

  EdgeInsets _pad;
  set pad(EdgeInsets v) {
    if (v == _pad) return;
    _pad = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MParentData) child.parentData = MParentData();
  }

  @override
  void performLayout() {
    final c = constraints.deflate(_pad);
    final cols = math.max(1, _cols);
    double width;
    if (c.hasBoundedWidth) {
      width = c.maxWidth;
    } else {
      // No definite width (rare): size columns to the widest child.
      var widest = 0.0;
      var child = firstChild;
      while (child != null) {
        child.layout(const BoxConstraints(), parentUsesSize: true);
        widest = math.max(widest, child.size.width);
        child = childAfter(child);
      }
      width = widest * cols + _gap * (cols - 1);
    }
    final colW = math.max(0.0, (width - _gap * (cols - 1)) / cols);

    // Lay out row by row, then stretch each row's cells to the tallest.
    var y = 0.0;
    var col = 0;
    var rowH = 0.0;
    final row = <RenderBox>[];

    void flush() {
      for (final cell in row) {
        if (cell.size.height != rowH) {
          cell.layout(BoxConstraints.tightFor(width: cell.size.width, height: rowH), parentUsesSize: true);
        }
        final pd = cell.parentData! as MParentData;
        pd.offset = Offset(pd.offset.dx, _pad.top + y);
      }
      y += rowH;
      row.clear();
      rowH = 0;
      col = 0;
    }

    var child = firstChild;
    while (child != null) {
      final pd = child.parentData! as MParentData;
      final span = pd.span.clamp(1, cols);
      if (col + span > cols) {
        flush();
        y += _rowGap;
      }
      final w = colW * span + _gap * (span - 1);
      child.layout(BoxConstraints(minWidth: w, maxWidth: w), parentUsesSize: true);
      pd.offset = Offset(_pad.left + col * (colW + _gap), 0);
      rowH = math.max(rowH, child.size.height);
      row.add(child);
      col += span;
      child = childAfter(child);
    }
    if (row.isNotEmpty) flush();

    size = constraints.constrain(Size(width + _pad.horizontal, y + _pad.vertical));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
