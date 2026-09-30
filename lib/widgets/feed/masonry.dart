import 'package:flutter/widgets.dart';

import '../../data/models.dart';
import 'masonry_layout.dart';
import 'sliver_masonry.dart';

/// Column-balanced masonry of [items] as a lazily built sliver (web
/// `Masonry.tsx`). Columns come from the **window** width ([columnsFor]).
class Masonry extends StatefulWidget {
  const Masonry({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.gap = 16,
    this.maxCols,
  });

  final List<Item> items;
  final Widget Function(BuildContext context, Item item, int index) itemBuilder;
  final double gap;
  final int? maxCols;

  @override
  State<Masonry> createState() => _MasonryState();
}

class _MasonryState extends State<Masonry> {
  // Layout inputs and the delegate are memoised: handing SliverMasonry a new
  // delegate rebuilds every live card, so they only change with the items or
  // the column count.
  List<Item>? _items;
  int _cols = 0;
  late List<int> _columnOf;
  late List<double> _weights;
  late List<Object> _ids;
  late SliverChildBuilderDelegate _delegate;

  bool _sameItems(List<Item> next) {
    final List<Item>? prev = _items;
    if (prev == null || prev.length != next.length) return false;
    for (int i = 0; i < next.length; i++) {
      if (!identical(prev[i], next[i])) return false;
    }
    return true;
  }

  void _compute(List<Item> items, int cols) {
    final List<double> aspects = <double>[for (final Item i in items) i.aspect];
    final Map<String, int> indexOf = <String, int>{
      for (int i = 0; i < items.length; i++) items[i].slug: i,
    };
    _items = items;
    _cols = cols;
    _columnOf = assignColumns(aspects, cols);
    _weights = <double>[for (final double a in aspects) masonryWeight(a)];
    _ids = <Object>[for (final Item i in items) i.slug];
    _delegate = SliverChildBuilderDelegate(
      (BuildContext context, int index) => KeyedSubtree(
        key: ValueKey<String>(items[index].slug),
        child: widget.itemBuilder(context, items[index], index),
      ),
      childCount: items.length,
      findChildIndexCallback: (Key key) =>
          key is ValueKey<String> ? indexOf[key.value] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int cols = columnsFor(MediaQuery.sizeOf(context).width, maxCols: widget.maxCols);
    if (cols != _cols || !_sameItems(widget.items)) _compute(widget.items, cols);
    return SliverMasonry(
      columns: _cols,
      columnOf: _columnOf,
      weights: _weights,
      ids: _ids,
      gap: widget.gap,
      delegate: _delegate,
    );
  }
}
