import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/hover_tap.dart';
import 'feed_card.dart';
import 'masonry.dart';

/// Items per page (§10.7).
const int kFeedPageSize = 28;

/// Pages loaded automatically before "Load more" takes over.
const int kFeedAutoPages = 5;

/// Auto-load when the end of the feed is this close below the viewport.
const double kFeedSentinelMargin = 1200;

/// Paginated masonry feed of [FeedCard]s, as a sliver (§10.7).
///
/// Shows [kFeedPageSize] items, auto-loads up to [kFeedAutoPages] pages as the
/// end comes within [kFeedSentinelMargin] of the viewport, then offers
/// "Load more"; ends with "{n} results · end of feed". A new [items] list
/// resets to the first page. Place inside a [CustomScrollView].
class Feed extends StatefulWidget {
  const Feed({super.key, required this.items, this.maxCols});

  final List<Item> items;
  final int? maxCols;

  @override
  State<Feed> createState() => FeedState();
}

class FeedState extends State<Feed> {
  int _pages = 1;
  ScrollPosition? _position;

  /// Number of items currently rendered.
  @visibleForTesting
  int get shown => (_pages * kFeedPageSize).clamp(0, widget.items.length);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_check);
      _position = next?..addListener(_check);
    }
  }

  @override
  void didUpdateWidget(Feed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items)) _pages = 1;
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    final ScrollPosition? p = _position;
    if (!mounted || p == null || !p.hasContentDimensions) return;
    if (_pages >= kFeedAutoPages || shown >= widget.items.length) return;
    if (p.extentAfter < kFeedSentinelMargin) setState(() => _pages++);
  }

  void _loadMore() => setState(() => _pages++);

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SliverToBoxAdapter(child: FeedEmpty());
    // Like the web IntersectionObserver: re-check once laid out, so a short
    // page keeps filling until the sentinel is out of range.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    final List<Item> items = widget.items.sublist(0, shown);
    final bool more = shown < widget.items.length;
    return SliverMainAxisGroup(
      slivers: [
        Masonry(
          items: items,
          maxCols: widget.maxCols,
          itemBuilder: (context, item, _) => FeedCard(item),
        ),
        SliverToBoxAdapter(
          child: more
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: _LoadMore(onTap: _loadMore)),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    '${widget.items.length} results · end of feed',
                    textAlign: TextAlign.center,
                    style: UiText.chip.copyWith(color: context.ui.text3),
                  ),
                ),
        ),
      ],
    );
  }
}

/// "Load more": bordered surface button, hover lifts −2 with an L2 shadow.
class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        curve: kTransitionEase,
        transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          boxShadow: [hardShadow(hovered ? Lift.l2 : 0, c.border)],
        ),
        child: Text('Load more', style: UiText.body.copyWith(color: c.text)),
      ),
    );
  }
}

/// Empty feed (§10.7): centred in 46% of the viewport height.
class FeedEmpty extends StatelessWidget {
  const FeedEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.46),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing matches those filters',
              textAlign: TextAlign.center,
              style: UiText.mono(15, bold: true).copyWith(color: c.text),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Text(
                'Try removing a filter, or browse Explore to start from a category instead.',
                textAlign: TextAlign.center,
                style: UiText.body.copyWith(color: c.text2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
