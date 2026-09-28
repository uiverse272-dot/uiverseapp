import 'package:flutter/widgets.dart';

import '../../data/models.dart';
import 'masonry_layout.dart';
import 'sliver_masonry.dart';

/// Column-balanced masonry of [items] as a lazily built sliver (web
/// `Masonry.tsx`). Columns come from the **window** width ([columnsFor]).
class Masonry extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final int cols = columnsFor(MediaQuery.sizeOf(context).width, maxCols: maxCols);
    final List<double> aspects = <double>[for (final Item i in items) i.aspect];
    final Map<String, int> indexOf = <String, int>{
      for (int i = 0; i < items.length; i++) items[i].slug: i,
    };
    return SliverMasonry(
      columns: cols,
      columnOf: assignColumns(aspects, cols),
      weights: <double>[for (final double a in aspects) masonryWeight(a)],
      ids: <Object>[for (final Item i in items) i.slug],
      gap: gap,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => KeyedSubtree(
          key: ValueKey<String>(items[index].slug),
          child: itemBuilder(context, items[index], index),
        ),
        childCount: items.length,
        findChildIndexCallback: (Key key) =>
            key is ValueKey<String> ? indexOf[key.value] : null,
      ),
    );
  }
}
