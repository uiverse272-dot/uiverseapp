import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'masonry_layout.dart';

/// A lazily built masonry sliver with a **precomputed** column assignment.
///
/// Children are created only around the viewport (plus cache extent). Each
/// child's column comes from [columnOf] (see [assignColumns]); its vertical
/// position is the measured height of the earlier children in that column, so
/// appending children never moves earlier ones.
class SliverMasonry extends SliverMultiBoxAdaptorWidget {
  const SliverMasonry({
    super.key,
    required super.delegate,
    required this.columns,
    required this.columnOf,
    required this.weights,
    required this.ids,
    this.gap = 16,
  }) : assert(columnOf.length == weights.length && weights.length == ids.length);

  final int columns;

  /// Column index per child.
  final List<int> columnOf;

  /// Unit height per child (see [masonryWeight]); only used to estimate the
  /// extent of children that have not been built yet.
  final List<double> weights;

  /// Stable identity per child. When the new list merely extends the old one
  /// (next page), measured heights are kept; otherwise they are dropped.
  final List<Object> ids;

  final double gap;

  @override
  RenderSliverMasonry createRenderObject(BuildContext context) => RenderSliverMasonry(
        childManager: context as SliverMultiBoxAdaptorElement,
        columns: columns,
        columnOf: columnOf,
        weights: weights,
        ids: ids,
        gap: gap,
      );

  @override
  void updateRenderObject(BuildContext context, RenderSliverMasonry renderObject) {
    renderObject.update(columns: columns, columnOf: columnOf, weights: weights, ids: ids, gap: gap);
  }
}

/// Render object for [SliverMasonry].
class RenderSliverMasonry extends RenderSliverMultiBoxAdaptor {
  RenderSliverMasonry({
    required super.childManager,
    required this._columns,
    required this._columnOf,
    required this._weights,
    required this._ids,
    required this._gap,
  });

  int _columns;
  List<int> _columnOf;
  List<double> _weights;
  List<Object> _ids;
  double _gap;

  /// Measured main-axis extents of children `0 .. _extents.length - 1`.
  /// Always a prefix: children are measured in index order.
  final List<double> _extents = <double>[];
  double? _measuredWidth;
  bool _dropAll = false;

  void update({
    required int columns,
    required List<int> columnOf,
    required List<double> weights,
    required List<Object> ids,
    required double gap,
  }) {
    final bool same = columns == _columns && gap == _gap && identical(ids, _ids) && identical(columnOf, _columnOf);
    if (same) return;
    if (!(columns == _columns && gap == _gap && _isPrefix(_ids, ids))) _reset();
    _columns = columns;
    _columnOf = columnOf;
    _weights = weights;
    _ids = ids;
    _gap = gap;
    markNeedsLayout();
  }

  static bool _isPrefix(List<Object> a, List<Object> b) {
    if (a.length > b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _reset() {
    _extents.clear();
    _dropAll = true;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverGridParentData) child.parentData = SliverGridParentData();
  }

  @override
  double childCrossAxisPosition(RenderBox child) =>
      (child.parentData! as SliverGridParentData).crossAxisOffset ?? 0;

  double _minOf(List<double> xs) => xs.reduce(math.min);

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final int n = _columnOf.length;
    final int cols = _columns;
    final double gap = _gap;
    final double colW = math.max(0, (constraints.crossAxisExtent - gap * (cols - 1)) / cols);
    if (_measuredWidth != colW) {
      _measuredWidth = colW;
      _reset();
    }
    if (_dropAll) {
      _dropAll = false;
      collectGarbage(childCount, 0);
    }
    if (_extents.length > n) _extents.removeRange(n, _extents.length);

    if (n == 0) {
      collectGarbage(childCount, 0);
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    final double start = constraints.scrollOffset + constraints.cacheOrigin;
    final double end = start + constraints.remainingCacheExtent;
    final BoxConstraints childConstraints = BoxConstraints.tightFor(width: colW);

    // (a) Walk the measured prefix to find the range of children to build.
    List<double> colH = List<double>.filled(cols, 0);
    int? firstIndex;
    int scan = 0;
    for (; scan < _extents.length; scan++) {
      if (_minOf(colH) > end) break;
      final int c = _columnOf[scan];
      final double y = colH[c];
      final double h = _extents[scan];
      if (firstIndex == null && y + h >= start && y <= end) firstIndex = scan;
      colH[c] = y + h + gap;
    }
    final bool needsMeasure = scan == _extents.length && scan < n && _minOf(colH) <= end;
    if (needsMeasure) {
      firstIndex ??= scan;
    } else {
      firstIndex ??= math.max(0, scan - 1);
    }
    final int? lastKnown = needsMeasure ? null : math.max(firstIndex, scan - 1);

    if (firstChild != null) {
      collectGarbage(
        calculateLeadingGarbage(firstIndex: firstIndex),
        lastKnown != null ? calculateTrailingGarbage(lastIndex: lastKnown) : 0,
      );
    } else {
      collectGarbage(0, 0);
    }

    // Column heights before [firstIndex].
    colH = List<double>.filled(cols, 0);
    for (int i = 0; i < firstIndex; i++) {
      colH[_columnOf[i]] += _extents[i] + gap;
    }

    if (firstChild == null && !addInitialChild(index: firstIndex, layoutOffset: colH[_columnOf[firstIndex]])) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }
    while (indexOf(firstChild!) > firstIndex) {
      if (insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true) == null) break;
    }

    // (b) Lay out children from [firstIndex] until every column passes [end].
    RenderBox? child = firstChild;
    RenderBox? prev;
    int index = firstIndex;
    while (index < n && _minOf(colH) <= end) {
      if (child == null || indexOf(child) != index) {
        child = prev == null ? null : insertAndLayoutChild(childConstraints, after: prev, parentUsesSize: true);
        if (child == null) break;
      } else {
        child.layout(childConstraints, parentUsesSize: true);
      }
      final double h = paintExtentOf(child);
      if (index < _extents.length) {
        _extents[index] = h;
      } else {
        _extents.add(h);
      }
      final int c = _columnOf[index];
      final pd = child.parentData! as SliverGridParentData
        ..layoutOffset = colH[c]
        ..crossAxisOffset = c * (colW + gap);
      assert(pd.index == index);
      colH[c] += h + gap;
      prev = child;
      child = childAfter(child);
      index++;
    }
    if (prev != null) collectGarbage(0, calculateTrailingGarbage(lastIndex: indexOf(prev)));

    // (c) Extent: measured heights where known, estimates for the rest.
    final double ratio = _estimateRatio(colW);
    for (int i = index; i < n; i++) {
      final double h = i < _extents.length ? _extents[i] : _weights[i] * colW * ratio;
      colH[_columnOf[i]] += h + gap;
    }
    final double total = math.max(0, colH.reduce(math.max) - gap);
    final bool reachedEnd = index >= n;

    geometry = SliverGeometry(
      scrollExtent: total,
      paintExtent: calculatePaintOffset(constraints, from: 0, to: total),
      cacheExtent: calculateCacheOffset(constraints, from: 0, to: total),
      maxPaintExtent: total,
      hasVisualOverflow: true,
    );
    if (reachedEnd) childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }

  /// Measured extent per unit of estimated extent (1 until something is measured).
  double _estimateRatio(double colW) {
    if (_extents.isEmpty || colW <= 0) return 1;
    double measured = 0;
    double estimated = 0;
    for (int i = 0; i < _extents.length; i++) {
      measured += _extents[i];
      estimated += _weights[i] * colW;
    }
    return estimated > 0 ? measured / estimated : 1;
  }

  @visibleForTesting
  List<double> get debugExtents => List<double>.unmodifiable(_extents);
}
