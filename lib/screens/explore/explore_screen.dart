import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_screen.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/hover_tap.dart';
import '../../widgets/feed/item_aspect.dart';
import '../../widgets/section/section.dart';
import 'explore_groups.dart';

/// Gap between Explore tiles, both axes (§4.1).
const double kExploreGap = 12;

/// Tile columns: 2 / 3 (≥640) / 4 (≥1024) / 6 (≥1280).
int exploreColumns(double width) => width >= Bp.xl
    ? 6
    : width >= Bp.lg
        ? 4
        : width >= Bp.sm
            ? 3
            : 2;

/// `/explore` — a directory, not a second feed (§12): PageHeader, then one
/// grid of tiles per group. Every tile opens a filtered feed.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ExploreGroup> groups = kExploreGroups;
    return CustomScrollView(
      slivers: [
        const SliverShell(
          sliver: SliverToBoxAdapter(
            child: PageHeader(
              title: 'Explore',
              sub: 'Start from a category, an industry, a style or a stack. '
                  'Every tile is a filtered feed with a real URL you can share.',
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        for (final ExploreGroup g in groups)
          SliverShell(
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: _GroupHead(group: g)),
                _TileGrid(tiles: g.tiles),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Group title (17 bold) + optional note (12.5 text-3), baseline aligned.
class _GroupHead extends StatelessWidget {
  const _GroupHead({required this.group});

  final ExploreGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Semantics(
            header: true,
            child: Text(group.title, style: UiText.groupTitle.copyWith(color: c.text)),
          ),
          if (group.note != null) Text(group.note!, style: UiText.chip.copyWith(color: c.text3)),
        ],
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<ExploreTile> tiles;

  @override
  Widget build(BuildContext context) {
    final int cols = exploreColumns(MediaQuery.sizeOf(context).width);
    // Label row: 8 + 13×1.5 (scaled) + 8, plus the 1px top and bottom borders.
    final double labelRow = 16 + MediaQuery.textScalerOf(context).scale(13) * 1.5;
    return SliverGrid.builder(
      gridDelegate: _TileGridDelegate(cols: cols, labelRow: labelRow),
      itemCount: tiles.length,
      itemBuilder: (context, i) => ExploreTileCard(tile: tiles[i]),
    );
  }
}

/// Fixed-column grid whose tile height follows the tile width (4:3 preview +
/// label row). Deriving it in [getLayout] avoids a `SliverLayoutBuilder`, which
/// would rebuild every visible tile on each scroll frame.
class _TileGridDelegate extends SliverGridDelegate {
  const _TileGridDelegate({required this.cols, required this.labelRow});

  final int cols;
  final double labelRow;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double w = (constraints.crossAxisExtent - kExploreGap * (cols - 1)) / cols;
    final double h = (w - 2) * 3 / 4 + labelRow + 2;
    return SliverGridRegularTileLayout(
      crossAxisCount: cols,
      mainAxisStride: h + kExploreGap,
      crossAxisStride: w + kExploreGap,
      childMainAxisExtent: h,
      childCrossAxisExtent: w,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_TileGridDelegate oldDelegate) =>
      oldDelegate.cols != cols || oldDelegate.labelRow != labelRow;
}

/// Explore tile: 4:3 preview on bg-subtle under a bottom black scrim, then
/// label (13) + count (11.5 tabular). Border, surface; hover border-strong.
class ExploreTileCard extends StatelessWidget {
  const ExploreTileCard({super.key, required this.tile});

  final ExploreTile tile;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    // Built outside the hover builder so hover/focus never rebuilds the mock.
    final preview = _Preview(tile: tile);
    return HoverTap(
      onTap: () => context.go(tile.href),
      link: true,
      label: '${tile.label}, ${tile.count}',
      minSize: Size.zero,
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: hovered ? c.borderStrong : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: preview),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tile.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${tile.count}',
                    style: UiText.caption.copyWith(color: c.text3, fontFeatures: UiText.tabular),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatefulWidget {
  const _Preview({required this.tile});

  final ExploreTile tile;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  // One MockScreen per cover: a new instance would rebuild the whole mock.
  late Widget? _mock = _buildMock();

  Widget? _buildMock() {
    final cover = widget.tile.cover;
    return cover == null ? null : MockScreen(item: withAspect(cover, 4 / 3));
  }

  @override
  void didUpdateWidget(_Preview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.tile.cover, widget.tile.cover)) _mock = _buildMock();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.bgSubtle),
          if (_mock != null)
            Transform.scale(
              scale: 1.02,
              alignment: Alignment.topLeft,
              child: Align(alignment: Alignment.topLeft, child: _mock),
            ),
          // bg-gradient-to-t from-black/45 to-transparent, opacity 80%.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0x5C000000), Color(0x00000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
