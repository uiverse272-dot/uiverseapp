/// Pure layout maths for the feed: column counts (web `useColumns.ts`) and
/// the deterministic masonry assignment (web `Masonry.tsx`).
library;

/// `(minimum window width, columns)`, widest first. Thresholds already
/// account for the 88px desktop rail (§4.4).
const List<(double, int)> kColumnBreakpoints = <(double, int)>[
  (1900, 6),
  (1540, 5),
  (1180, 4),
  (760, 3),
  (0, 2),
];

/// Masonry column count for a **window** width (web `useColumns`).
/// [maxCols] caps it, except that 2-column phones stay at ≤ 2.
int columnsFor(double windowWidth, {int? maxCols}) {
  int cols = 2;
  for (final (double min, int n) in kColumnBreakpoints) {
    if (windowWidth >= min) {
      cols = n;
      break;
    }
  }
  if (maxCols != null && maxCols > 0) return cols == 2 ? (maxCols < 2 ? maxCols : 2) : maxCols;
  return cols;
}

/// Precomputed unit height of a card: `1 / aspect` plus a constant caption
/// allowance (no measuring).
double masonryWeight(double aspect) => 1 / aspect + 0.14;

/// Column index for each item, shortest column first (ties → leftmost).
///
/// Assignment is incremental: appending aspects never changes the columns of
/// earlier items.
List<int> assignColumns(List<double> aspects, int cols) {
  assert(cols > 0);
  final List<double> heights = List<double>.filled(cols, 0);
  final List<int> out = List<int>.filled(aspects.length, 0);
  for (int i = 0; i < aspects.length; i++) {
    int target = 0;
    for (int c = 1; c < cols; c++) {
      if (heights[c] < heights[target]) target = c;
    }
    out[i] = target;
    heights[target] += masonryWeight(aspects[i]);
  }
  return out;
}
