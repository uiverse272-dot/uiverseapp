import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/query.dart';
import '../../router/routes.dart';
import '../../theme/motion.dart';
import '../../widgets/feed/feed.dart';
import '../../widgets/feed/feed_card.dart';
import '../../widgets/feed/filter_bar.dart';
import '../../widgets/feed/pick_of_the_week.dart';
import '../../widgets/feed/url_query.dart';
import '../../widgets/section/section.dart';
import 'home_chips.dart';

/// `/` — discovery feed (§12): Categories + chip rail, "Popular this week"
/// (For You only), the chip's feed, and Pick of the week floating
/// bottom-right. [chip] is the `?chip=` query value.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.chip});

  final String? chip;

  @override
  Widget build(BuildContext context) {
    final HomeChip active = homeChipFor(chip);
    final List<Item> filtered = applyFilters(kItems, active.filters);
    final List<Item> items = active.value == 'components' ? filtered : mixFeed(filtered);
    final List<Item> trending =
        sortItems(kItems.where((Item i) => i.kind == Kind.screen).toList(), 'trending');
    final List<Item> popular = trending.take(6).toList();
    final Item pick = trending.firstWhere((Item i) => i.device == Device.desktop, orElse: () => trending.first);
    final bool browsing = active.value == null;
    final double gutter = pageGutter(context);
    final bool wide = MediaQuery.sizeOf(context).width >= Bp.md;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      label: 'Uiverse — discover interfaces worth building',
                      child: const SizedBox.shrink(),
                    ),
                    const SectionHead(title: 'Categories'),
                    ChipRail(
                      chips: [for (final HomeChip c in kHomeChips) c.def],
                      selected: active.value,
                      onSelect: (v) => goWithQuery(context, v == null ? const {} : {'chip': v}),
                    ),
                    if (browsing) ...[
                      const SizedBox(height: 36),
                      SectionHead(
                        title: 'Popular this week',
                        onMore: () => context.go(withQuery(Routes.web, const {'sort': 'trending'})),
                      ),
                      PopularGrid(items: popular),
                    ],
                    const SizedBox(height: 36),
                    SectionHead(
                      title: browsing ? 'Recommended for you' : '${active.label} · ${items.length} results',
                      moreLabel: browsing ? 'more' : 'clear',
                      onMore: () => context.go(browsing ? Routes.explore : Routes.home),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 24),
              sliver: Feed(items: items),
            ),
          ],
        ),
        Positioned(
          right: wide ? 24 : 16,
          bottom: 24,
          child: PickOfTheWeek(item: pick),
        ),
      ],
    );
  }
}

/// "Popular this week": fixed 3:4 cards in 2 / 3 (≥640) / 6 (≥1280) columns,
/// column gap 16, row gap 24.
class PopularGrid extends StatelessWidget {
  const PopularGrid({super.key, required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    final int cols = w >= Bp.xl ? 6 : (w >= Bp.sm ? 3 : 2);
    final rows = <Widget>[];
    for (int r = 0; r * cols < items.length; r++) {
      if (r > 0) rows.add(const SizedBox(height: 24));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int c = 0; c < cols; c++) ...[
            if (c > 0) const SizedBox(width: 16),
            Expanded(
              child: r * cols + c < items.length
                  ? FeedCard(items[r * cols + c], crop: 3 / 4)
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}
