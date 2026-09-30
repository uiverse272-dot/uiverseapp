import 'package:flutter/widgets.dart';

/// Equal-width column grid laid out as rows, so cards in a row top-align and
/// each row is as tall as its tallest card (CSS `grid-cols-N`).
///
/// [RowGrid] builds every row (use inside a non-lazy parent such as the detail
/// page); [SliverRowGrid] builds rows lazily inside a [CustomScrollView].
class RowGrid extends StatelessWidget {
  const RowGrid({
    super.key,
    required this.count,
    required this.columns,
    required this.itemBuilder,
    this.gap = 16,
    this.rowGap = 16,
  });

  final int count;
  final int columns;
  final IndexedWidgetBuilder itemBuilder;

  /// Space between columns.
  final double gap;

  /// Space between rows.
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final int rows = rowCount(count, columns);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int r = 0; r < rows; r++) ...[
          if (r > 0) SizedBox(height: rowGap),
          gridRow(context, r, count: count, columns: columns, gap: gap, itemBuilder: itemBuilder),
        ],
      ],
    );
  }
}

/// Lazy [RowGrid]: a sliver that only builds the rows near the viewport.
class SliverRowGrid extends StatelessWidget {
  const SliverRowGrid({
    super.key,
    required this.count,
    required this.columns,
    required this.itemBuilder,
    this.gap = 16,
    this.rowGap = 16,
  });

  final int count;
  final int columns;
  final IndexedWidgetBuilder itemBuilder;
  final double gap;
  final double rowGap;

  @override
  Widget build(BuildContext context) => SliverList.separated(
        itemCount: rowCount(count, columns),
        separatorBuilder: (context, _) => SizedBox(height: rowGap),
        itemBuilder: (context, r) =>
            gridRow(context, r, count: count, columns: columns, gap: gap, itemBuilder: itemBuilder),
      );
}

/// Rows needed for [count] items in [columns] columns.
int rowCount(int count, int columns) => count == 0 ? 0 : (count + columns - 1) ~/ columns;

/// Row [row] of the grid; short last rows are padded with empty cells.
Widget gridRow(
  BuildContext context,
  int row, {
  required int count,
  required int columns,
  required double gap,
  required IndexedWidgetBuilder itemBuilder,
}) =>
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int c = 0; c < columns; c++) ...[
          if (c > 0) SizedBox(width: gap),
          Expanded(
            child: row * columns + c < count
                ? itemBuilder(context, row * columns + c)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
