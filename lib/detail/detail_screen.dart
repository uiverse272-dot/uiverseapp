import 'package:flutter/material.dart' hide Viewport;

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/query.dart';
import '../mock/mock_screen.dart';
import '../router/detail.dart';
import '../router/routes.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/hover_tap.dart';
import 'breakdown.dart';
import 'detail_tabs.dart';
import 'parts.dart';
import 'prompt_dialog.dart';
import 'detail_media.dart';
import 'detail_rail.dart';

export 'detail_tabs.dart' show DetailCardBuilder;

/// Screen/component detail (§10.9) for `/screen/:slug` and `/component/:slug`.
///
/// Does not scroll itself: both detail presentations wrap it in a scroll view.
/// [cardBuilder] renders the "Similar" cards; defaults to [MiniCard].
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.slug, this.cardBuilder});

  final String slug;
  final DetailCardBuilder? cardBuilder;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final GlobalKey _frameKey = GlobalKey(debugLabel: 'detail-frame');
  final GlobalKey _tabsKey = GlobalKey(debugLabel: 'detail-tabs');
  DetailTab _tab = DetailTab.overview;
  Viewport? _device;

  // The sibling strip and the similar grid are up to 12 more mock previews.
  // They are built one frame after the page itself, so opening a detail
  // (a 240ms transition) doesn't pay for them in its first frame.
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _settled = true);
    });
  }

  void _reveal(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (!mounted || ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(ctx, duration: motion(context, kReveal), curve: kEase)
          .ignore();
    });
  }

  void _showTab(DetailTab t, {bool reveal = false}) {
    setState(() => _tab = t);
    if (reveal) _reveal(_tabsKey);
  }

  void _showDevice(Viewport vp) {
    setState(() => _device = vp);
    _reveal(_frameKey);
  }

  // similarTo scores the whole catalog; cache it per slug so tab and device
  // switches don't redo it.
  String? _similarSlug;
  List<Item> _similar = const <Item>[];

  List<Item> _similarFor(Item item) {
    if (_similarSlug != item.slug) {
      _similarSlug = item.slug;
      _similar = similarTo(item, 12);
    }
    return _similar;
  }

  @override
  void didUpdateWidget(DetailScreen old) {
    super.didUpdateWidget(old);
    if (old.slug != widget.slug) {
      _tab = DetailTab.overview;
      _device = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = bySlug(widget.slug);
    if (item == null) return const _NotFound();

    final device = _device ?? MockScreen.nativeViewport(item);
    final similar = _similarFor(item);
    final width = MediaQuery.sizeOf(context).width;
    final overlay = DetailPresentation.of(context) == DetailPresentation.overlay;
    final pad = width >= Bp.md ? 20.0 : 16.0;
    final twoCol = width >= Bp.lg;
    // Leave room for the overlay's top-right close button.
    final closeGap = overlay ? 48.0 : 0.0;

    final media = DetailMedia(
      key: _frameKey,
      item: item,
      device: device,
      onDevice: (vp) => setState(() => _device = vp),
      topRightGap: twoCol ? 0 : closeGap,
      showSiblings: _settled,
    );
    final rail = DetailRail(
      item: item,
      topRightGap: twoCol ? closeGap : 0,
      onPrompt: () => showPromptDialog(context, item),
      onTab: (t) => _showTab(t, reveal: true),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1700),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 20, pad, overlay ? 24 : 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The rail can't be sticky inside the presentation's scroll view; it sits beside the media.
              if (twoCol)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: media),
                    const SizedBox(width: 24),
                    SizedBox(width: 340, child: rail),
                  ],
                )
              else ...[
                media,
                const SizedBox(height: 24),
                rail,
              ],
              const SizedBox(height: 32),
              DetailTabBar(key: _tabsKey, selected: _tab, onSelect: _showTab),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: switch (_tab) {
                  DetailTab.overview => OverviewTab(item: item),
                  DetailTab.breakdown => Breakdown(item: item),
                  DetailTab.responsive => ResponsiveTab(item: item, onPick: _showDevice),
                  DetailTab.code => CodeTab(item: item, onPrompt: () => showPromptDialog(context, item)),
                  DetailTab.similar => CardGrid(items: similar, cardBuilder: widget.cardBuilder),
                },
              ),
              if (_settled && _tab != DetailTab.similar)
                _SimilarSection(item: item, similar: similar, cardBuilder: widget.cardBuilder),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        children: [
          Text('Not found', style: UiText.mono(22, bold: true, track: -0.02, color: c.text)),
          const SizedBox(height: 8),
          Text(
            "That design isn't in the index.",
            textAlign: TextAlign.center,
            style: UiText.body.copyWith(color: c.text2),
          ),
          const SizedBox(height: 20),
          HoverTap(
            onTap: () => goTo(context, Routes.home),
            link: true,
            builder: (context, hovered) => Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hovered ? c.bgSubtle : c.surface,
                border: Border.all(color: c.border),
              ),
              child: Text('Back to the feed', style: UiText.body.copyWith(color: c.text)),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------ media */

class _SimilarSection extends StatelessWidget {
  const _SimilarSection({required this.item, required this.similar, this.cardBuilder});

  final Item item;
  final List<Item> similar;
  final DetailCardBuilder? cardBuilder;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Semantics(
              header: true,
              child: Text(
                item.kind == Kind.component ? 'Related components' : 'Similar designs',
                style: UiText.mono(15, bold: true, track: -0.02, color: c.text),
              ),
            ),
          ),
          CardGrid(items: similar.take(6).toList(), cardBuilder: cardBuilder),
        ],
      ),
    );
  }
}
