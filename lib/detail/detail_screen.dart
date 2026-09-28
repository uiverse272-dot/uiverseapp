import 'package:flutter/material.dart' hide Viewport;

import '../data/catalog.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/query.dart';
import '../data/taxonomy.dart';
import '../mock/mock_screen.dart';
import '../router/detail.dart';
import '../router/routes.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/hover_tap.dart';
import '../widgets/core/ui_icon.dart';
import '../widgets/save/save_button.dart';
import 'breakdown.dart';
import 'detail_tabs.dart';
import 'parts.dart';
import 'prompt_dialog.dart';

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

  void _reveal(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(ctx, duration: motion(context, const Duration(milliseconds: 300)), curve: kEase)
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
    final similar = similarTo(item, 12);
    final width = MediaQuery.sizeOf(context).width;
    final overlay = DetailPresentation.of(context) == DetailPresentation.overlay;
    final pad = width >= Bp.md ? 20.0 : 16.0;
    final twoCol = width >= Bp.lg;
    // Leave room for the overlay's top-right close button.
    final closeGap = overlay ? 48.0 : 0.0;

    final media = _Media(
      key: _frameKey,
      item: item,
      device: device,
      onDevice: (vp) => setState(() => _device = vp),
      topRightGap: twoCol ? 0 : closeGap,
    );
    final rail = _Rail(
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
              if (_tab != DetailTab.similar)
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

class _Media extends StatelessWidget {
  const _Media({
    super.key,
    required this.item,
    required this.device,
    required this.onDevice,
    required this.topRightGap,
  });

  final Item item;
  final Viewport device;
  final ValueChanged<Viewport> onDevice;
  final double topRightGap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final size = MediaQuery.sizeOf(context);
    final native = MockScreen.nativeViewport(item);
    final siblings = item.kind == Kind.component
        ? const <Item>[]
        : kItems
            .where((i) => i.source.slug == item.source.slug && i.kind == Kind.screen)
            .take(6)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12, right: topRightGap),
          child: Row(
            children: [
              _DeviceToggle(device: device, onChanged: onDevice),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Captured ${timeAgo(item.daysAgo)} · ${compact(item.views)} views',
                  textAlign: TextAlign.right,
                  style: UiText.small.copyWith(color: c.text3),
                ),
              ),
            ],
          ),
        ),
        // Long captures scroll inside the frame rather than making the page enormous.
        Container(
          padding: EdgeInsets.all(size.width >= Bp.md ? 20 : 12),
          decoration: BoxDecoration(color: c.bgSubtle, border: Border.all(color: c.border)),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = device == Viewport.desktop ? box.maxWidth : device.w.clamp(0, box.maxWidth).toDouble();
              return Center(
                child: AnimatedContainer(
                  duration: motion(context, const Duration(milliseconds: 200)),
                  curve: kEase,
                  width: w,
                  constraints: BoxConstraints(maxHeight: size.height * 0.76),
                  decoration: BoxDecoration(border: Border.all(color: c.border)),
                  child: Semantics(
                    label: '${item.title} preview, ${device.label}',
                    child: SingleChildScrollView(
                      child: MockScreen(key: ValueKey(device), item: item, viewport: device),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${device.label} · ${device.w.toInt()} × ${device.h.toInt()} · '
            '${device == native ? 'original design' : 'adapted from the ${native.label.toLowerCase()} design'}'
            ' · scroll inside the frame',
            textAlign: TextAlign.center,
            style: UiText.caption.copyWith(color: c.text3),
          ),
        ),
        if (siblings.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in siblings) ...[
                  if (s != siblings.first) const SizedBox(width: 8),
                  _SiblingTile(item: s, current: s.slug == item.slug),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DeviceToggle extends StatelessWidget {
  const _DeviceToggle({required this.device, required this.onChanged});

  final Viewport device;
  final ValueChanged<Viewport> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Semantics(
      container: true,
      label: 'Device',
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(border: Border.all(color: c.border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final vp in Viewport.values) ...[
              if (vp != Viewport.values.first) const SizedBox(width: 4),
              HoverTap(
                onTap: () => onChanged(vp),
                toggled: vp == device,
                label: vp.label,
                // Segments stay compact visually (§14 notes ~24dp on web); 48 wide, 28 tall.
                minSize: const Size(48, 28),
                builder: (context, hovered) {
                  final on = vp == device;
                  return AnimatedContainer(
                    duration: motion(context, kTransition),
                    height: 28,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    color: on ? c.accent : null,
                    child: Text(
                      vp.label,
                      style: UiText.small.copyWith(
                        color: on ? c.accentFg : (hovered ? c.text : c.text2),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SiblingTile extends StatelessWidget {
  const _SiblingTile({required this.item, required this.current});

  final Item item;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: current ? () {} : () => openDetail(context, item),
      link: true,
      label: item.title,
      selected: current,
      builder: (context, hovered) => Container(
        width: 112,
        decoration: BoxDecoration(
          border: Border.all(color: current ? c.text : (hovered ? c.borderStrong : c.border)),
        ),
        child: AspectRatio(
          aspectRatio: 1.5,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: MockScreen(item: item, full: true),
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------- rail */

class _Rail extends StatelessWidget {
  const _Rail({
    required this.item,
    required this.topRightGap,
    required this.onPrompt,
    required this.onTab,
  });

  final Item item;
  final double topRightGap;
  final VoidCallback onPrompt;
  final ValueChanged<DetailTab> onTab;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final tags = <String>[item.category, item.industry, item.style, ...item.tech];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(right: topRightGap),
          child: Semantics(
            header: true,
            child: Text(item.title, style: UiText.detailTitle.copyWith(color: c.text)),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: HoverTap(
            onTap: () => goTo(context, Routes.source(item.source.slug)),
            link: true,
            label: 'By: ${item.source.name}',
            minSize: const Size(48, 40),
            builder: (context, hovered) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.palette.accent,
                    border: Border.all(color: c.border),
                  ),
                ),
                const SizedBox(width: 8),
                Text('By: ', style: UiText.chip.copyWith(color: c.text)),
                Text(
                  item.source.name,
                  style: UiText.chip.copyWith(
                    color: hovered ? c.accent : c.text,
                    decoration: TextDecoration.underline,
                    decorationColor: hovered ? c.accent : c.text,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'This would open ${item.source.domain}',
          child: HoverTap(
            // Deliberately inert: captures are indexed, not linked out, in this demo.
            onTap: () {},
            label: 'Open live site',
            minSize: const Size(48, 44),
            builder: (context, hovered) => Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: hovered ? c.bgSubtle : c.surface,
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiIcon(Ui.external, size: 15, color: c.text),
                  const SizedBox(width: 8),
                  Text('Open live site', style: UiText.button.copyWith(color: c.text)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SaveButton(item.slug, variant: SaveButtonVariant.solid),
        const SizedBox(height: 12),
        _ActionTrio(
          onPrompt: onPrompt,
          onCode: () => onTab(DetailTab.code),
          onBreakdown: () => onTab(DetailTab.breakdown),
        ),
        const SizedBox(height: 24),
        _MetaList(item: item),
        const SizedBox(height: 16),
        Text(item.source.about, style: UiText.mono(12.5, height: 1.625, color: c.text)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (final t in tags)
              HoverTap(
                onTap: () => goTo(context, Routes.searchFor(t)),
                link: true,
                minSize: const Size(32, 40),
                builder: (context, hovered) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hovered ? c.bgSubtle : null,
                    border: Border.all(color: c.border),
                  ),
                  child: Text(t, style: UiText.caption.copyWith(color: hovered ? c.text : c.text2)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
          child: InlineLinkText(
            before: 'Preview rendered from the capture. Attribution links to the source; ',
            link: 'attribution policy',
            after: '.',
            onTap: () => goTo(context, Routes.legal('attribution')),
            style: UiText.mono(11.5, height: 1.625, color: c.text3),
          ),
        ),
      ],
    );
  }
}

class _ActionTrio extends StatelessWidget {
  const _ActionTrio({required this.onPrompt, required this.onCode, required this.onBreakdown});

  final VoidCallback onPrompt;
  final VoidCallback onCode;
  final VoidCallback onBreakdown;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final actions = <(String, Ui, VoidCallback)>[
      ('Prompt', Ui.sparkle, onPrompt),
      ('Code', Ui.code, onCode),
      ('Breakdown', Ui.layers, onBreakdown),
    ];
    return Container(
      decoration: BoxDecoration(border: Border.all(color: c.border)),
      child: Row(
        children: [
          for (final (i, (label, icon, run)) in actions.indexed)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(left: BorderSide(color: c.border)),
                ),
                child: HoverTap(
                  onTap: run,
                  label: label,
                  builder: (context, hovered) => AnimatedContainer(
                    duration: motion(context, kTransition),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: hovered ? c.bgSubtle : null,
                    child: Column(
                      children: [
                        UiIcon(icon, size: 19, color: c.text),
                        const SizedBox(height: 6),
                        Text(label, style: UiText.meta.copyWith(color: c.text)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaList extends StatelessWidget {
  const _MetaList({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    String web(String param, String value) =>
        Uri(path: Routes.web, queryParameters: {param: value}).toString();
    final rows = <(String, String, String?)>[
      ('Type', taxName(kCategories, item.category), web('category', item.category)),
      ('Industry', taxName(kIndustries, item.industry), web('industry', item.industry)),
      ('Style', taxName(kStyles, item.style), web('style', item.style)),
      ('Platform', item.platform == 'web' ? 'Web' : item.platform.toUpperCase(), null),
      (
        'Stack',
        item.tech.map((t) => taxName(kTechnologies, t)).join(', '),
        item.tech.isEmpty ? null : web('tech', item.tech.first),
      ),
      ('Saves', compact(item.saves), null),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border), bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value, href) in rows)
            _MetaRow(label: label, value: value, onTap: href == null ? null : () => goTo(context, href)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget row(bool hovered) => Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 32),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              SizedBox(width: 88, child: Text(label, style: UiText.small.copyWith(color: c.text2))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.small.copyWith(color: hovered ? c.accent : c.text),
                ),
              ),
            ],
          ),
        );
    if (onTap == null) return row(false);
    return HoverTap(
      onTap: onTap,
      link: true,
      label: '$label: $value',
      minSize: const Size(48, 32),
      builder: (context, hovered) => row(hovered),
    );
  }
}

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
