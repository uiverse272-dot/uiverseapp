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
import '../../widgets/core/row_grid.dart';

// The catalog is immutable, so the home lists are computed once and reused
// across rebuilds (the router rebuilds Home under every detail overlay).
final List<Item> _trending =
    sortItems(kItems.where((Item i) => i.kind == Kind.screen).toList(), 'trending');
final List<Item> _popular = List<Item>.unmodifiable(_trending.take(6));
final Item _pick =
    _trending.firstWhere((Item i) => i.device == Device.desktop, orElse: () => _trending.first);
final Map<String?, List<Item>> _chipFeeds = <String?, List<Item>>{};

List<Item> _chipFeed(HomeChip chip) {
  final List<Item> filtered = filterCatalog(chip.filters);
  return chip.value == 'components' ? filtered : List<Item>.unmodifiable(mixFeed(filtered));
}

/// `/` — discovery feed (§12): Categories + chip rail, "Popular this week"
/// (For You only), the chip's feed, and Pick of the week floating
/// bottom-right. [chip] is the `?chip=` query value.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.chip});

  final String? chip;

  @override
  Widget build(BuildContext context) {
    final HomeChip active = homeChipFor(chip);
    final List<Item> items = _chipFeeds[active.value] ??= _chipFeed(active);
    final List<Item> popular = _popular;
    final Item pick = _pick;
    final bool browsing = active.value == null;
    final double gutter = pageGutter(context);
    final bool wide = context.isWide;

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
                    ],
                  ],
                ),
              ),
            ),
            if (browsing)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: PopularGrid(items: popular),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 36, gutter, 0),
              sliver: SliverToBoxAdapter(
                child: SectionHead(
                  title: browsing ? 'Recommended for you' : '${active.label} · ${items.length} results',
                  moreLabel: browsing ? 'more' : 'clear',
                  onMore: () => context.go(browsing ? Routes.explore : Routes.home),
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
/// column gap 16, row gap 24. A sliver: rows below the fold are built lazily.
class PopularGrid extends StatelessWidget {
  const PopularGrid({super.key, required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) => SliverRowGrid(
        count: items.length,
        columns: bpColumns(MediaQuery.sizeOf(context).width, base: 2, sm: 3, xl: 6),
        rowGap: 24,
        itemBuilder: (context, i) => FeedCard(items[i], crop: 3 / 4),
      );
}
