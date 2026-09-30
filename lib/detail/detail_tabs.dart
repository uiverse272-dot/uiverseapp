import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;

import '../data/models.dart';
import '../data/palettes.dart';
import '../data/spec.dart';
import '../mock/mock_screen.dart';
import '../router/detail.dart';
import '../router/routes.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/copy_value.dart';
import '../widgets/core/hover_tap.dart';
import '../widgets/core/lift_on_press.dart';
import '../widgets/core/ui_icon.dart';
import 'parts.dart';
import '../widgets/core/links.dart';
import '../widgets/core/row_grid.dart';

/// The detail tabs, in order (§10.9).
enum DetailTab {
  overview('Overview'),
  breakdown('Breakdown'),
  responsive('Responsive'),
  code('Code'),
  similar('Similar');

  const DetailTab(this.label);
  final String label;
}

/// Builds a feed card for [Item]; the orchestrator passes the real `FeedCard`.
typedef DetailCardBuilder = Widget Function(BuildContext context, Item item);

/// The native viewport of [item] (what "original design" refers to).
Viewport nativeViewportOf(Item item) => MockScreen.nativeViewport(item);

/// The tab strip: 13.5 labels, 3px accent underline on the selected one,
/// scrolls sideways on phones.
class DetailTabBar extends StatelessWidget {
  const DetailTabBar({super.key, required this.selected, required this.onSelect});

  final DetailTab selected;
  final ValueChanged<DetailTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in DetailTab.values) ...[
              if (t != DetailTab.values.first) const SizedBox(width: 4),
              HoverTap(
                onTap: () => onSelect(t),
                selected: t == selected,
                builder: (context, hovered) {
                  final on = t == selected;
                  return SizedBox(
                    height: 48,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              t.label,
                              style: UiText.button.copyWith(
                                color: on || hovered ? c.text : c.text2,
                              ),
                            ),
                          ),
                        ),
                        if (on)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(height: 3, color: c.accent),
                          ),
                      ],
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

/// Overview: "What this screen does" + palette (§10.9).
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final first = item.blocks.isEmpty ? '' : item.blocks.first.label.toLowerCase();
    final hasCta = item.blocks.any((b) => b.type == 'cta');
    final bullets = <String>[
      'Accent used sparingly, on ${hasCta ? 'CTAs and one metric band' : 'primary actions only'}.',
      'Type hierarchy carried by size and weight rather than colour.',
      item.device == Device.mobile
          ? 'Designed for phones; adapted up to tablet and laptop — switch device above.'
          : 'Designed for laptop; adapted down to tablet and mobile — switch device above.',
    ];
    return SplitRow(
      a: 14,
      b: 10,
      first: Panel(
        title: 'What this screen does',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${item.source.name} uses a ${item.style} treatment for a '
              '${item.industry.replaceFirst('-', ' ')} audience. The ${item.title.toLowerCase()} '
              'leads with $first and resolves in ${item.blocks.length} distinct sections — a '
              'structure you can reuse directly from the Breakdown tab.',
              style: UiText.bodyLg.copyWith(color: c.text2),
            ),
            const SizedBox(height: 16),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('· $b', style: UiText.mono(13.5, color: c.text2)),
              ),
          ],
        ),
      ),
      second: Panel(
        title: 'Palette',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 66,
              decoration: BoxDecoration(border: Border.all(color: c.border)),
              child: Row(
                children: [
                  for (final col in item.colors) Expanded(child: ColoredBox(color: col)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              children: [
                for (final col in item.colors) CopyValue(hexOf(col), mono: true, bordered: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive: one tile per viewport + "How it adapts" (§10.9).
class ResponsiveTab extends StatelessWidget {
  const ResponsiveTab({super.key, required this.item, required this.onPick});

  final Item item;
  final ValueChanged<Viewport> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final native = nativeViewportOf(item);
    final wide = context.isWide;
    const flex = <Viewport, int>{Viewport.desktop: 190, Viewport.tablet: 125, Viewport.mobile: 75};
    final tiles = <Widget>[
      for (final vp in Viewport.values) _ViewportTile(item: item, vp: vp, native: native, onPick: onPick),
    ];
    final rowWide = MediaQuery.sizeOf(context).width >= Bp.sm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(flex: flex[Viewport.values[i]]!, child: tiles[i]),
              ],
            ],
          )
        else
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            tiles[i],
          ],
        const SizedBox(height: 16),
        Panel(
          title: 'How it adapts',
          subtitle: 'Laptop → tablet → mobile',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (k, v)) in responsiveRules(item).indexed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: i == responsiveRules(item).length - 1
                        ? null
                        : Border(bottom: BorderSide(color: c.rule)),
                  ),
                  child: rowWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 160,
                              child: Text(k, style: UiText.body.copyWith(color: c.text3)),
                            ),
                            const SizedBox(width: 24),
                            Expanded(child: Text(v, style: UiText.body.copyWith(color: c.text))),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(k, style: UiText.body.copyWith(color: c.text3)),
                            const SizedBox(height: 4),
                            Text(v, style: UiText.body.copyWith(color: c.text)),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewportTile extends StatelessWidget {
  const _ViewportTile({required this.item, required this.vp, required this.native, required this.onPick});

  final Item item;
  final Viewport vp;
  final Viewport native;
  final ValueChanged<Viewport> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return LiftOnPress(
      onTap: () => onPick(vp),
      semanticLabel: 'Show ${vp.label} preview',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(vp.label, style: UiText.body.copyWith(color: c.text, fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Text(
                  '${vp.w.toInt()}px${vp == native ? ' · original' : ''}',
                  style: UiText.meta.copyWith(color: c.text3),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(border: Border.all(color: c.border)),
              child: AspectRatio(
                aspectRatio: vp.w / vp.h,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: double.infinity,
                    child: MockScreen(item: item, viewport: vp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Code: the contributed snippet, or an explanation plus the prompt shortcut.
class CodeTab extends StatelessWidget {
  const CodeTab({super.key, required this.item, required this.onPrompt});

  final Item item;
  final VoidCallback onPrompt;

  @override
  Widget build(BuildContext context) => item.hasCode ? _snippetBox(context) : _none(context);

  Widget _none(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: UiIcon(Ui.code, size: 18, color: c.text3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No code for this capture', style: UiText.panelTitle.copyWith(color: c.text)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672),
                  child: InlineLinkText(
                    before: 'Code is only ever shown when it was contributed by its author, published '
                        'under a licence, or generated as a clearly-labelled re-implementation. '
                        'Screenshots of a live site are indexed with attribution; its markup and CSS '
                        'are not redistributed. See ',
                    link: 'the attribution policy',
                    after: '.',
                    onTap: () => goTo(context, Routes.legal('attribution')),
                    style: UiText.mono(13.5, height: 1.625, color: c.text2),
                  ),
                ),
                const SizedBox(height: 8),
                HoverTap(
                  onTap: onPrompt,
                  builder: (context, hovered) => Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: hovered ? c.bgSubtle : null,
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UiIcon(Ui.sparkle, size: 14, color: c.text),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Generate an implementation prompt instead',
                            overflow: TextOverflow.ellipsis,
                            style: UiText.body.copyWith(color: c.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _snippetBox(BuildContext context) {
    final c = context.ui;
    final code = codeSnippet(item);
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, t) in const ['React', 'HTML', 'Tailwind'].indexed)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: i == 0 ? c.bgSubtle : null,
                        child: Text(t, style: UiText.small.copyWith(color: i == 0 ? c.text : c.text3)),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(border: Border.all(color: c.border)),
                      child: Text('MIT · contributed', style: UiText.mono(10.5, color: c.text3)),
                    ),
                    const SizedBox(width: 12),
                    CopyValue(code, label: 'Copy', bordered: true),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Text(code, softWrap: false, style: UiText.mono(12, height: 1.625, color: c.text2)),
          ),
        ],
      ),
    );
  }
}

/// Web `cap`: `stat-card` → `StatCard`.
String pascal(String s) {
  if (s.isEmpty) return s;
  final rest = s.substring(1).replaceAllMapped(RegExp(r'-(\w)'), (m) => m[1]!.toUpperCase());
  return s[0].toUpperCase() + rest;
}

/// The illustrative contributed snippet shown on the Code tab.
String codeSnippet(Item item) {
  final name = item.componentType != null ? pascal(item.componentType!) : 'Section';
  return '''export function $name() {
  return (
    <section className="mx-auto max-w-[1440px] px-6 py-24">
      <h2 className="text-[48px] font-bold tracking-[-0.03em]">
        ${item.source.tagline}
      </h2>
      <p className="mt-4 max-w-xl text-[15px] leading-relaxed text-neutral-500">
        Contributed by ${item.source.name} under MIT.
      </p>
    </section>
  );
}''';
}

/// A 2 / 3 / 6-column grid (<640 / <1024 / ≥1024) of cards, 16 apart.
class CardGrid extends StatelessWidget {
  const CardGrid({super.key, required this.items, this.cardBuilder});

  final List<Item> items;
  final DetailCardBuilder? cardBuilder;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = bpColumns(w, base: 2, sm: 3, lg: 6);
    final build = cardBuilder ?? (BuildContext ctx, Item i) => MiniCard(item: i);
    return RowGrid(
      count: items.length,
      columns: cols,
      itemBuilder: (context, i) => build(context, items[i]),
    );
  }
}

/// Minimal stand-in for the feed card: bordered preview + title + source.
class MiniCard extends StatelessWidget {
  const MiniCard({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return LiftOnPress(
      onTap: () => openDetail(context, item),
      semanticLabel: '${item.title}, ${item.source.name}',
      child: ColoredBox(
        color: c.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: c.border)),
              child: AspectRatio(
                aspectRatio: math.max(item.aspect, 0.8),
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: double.infinity,
                    child: MockScreen(item: item),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.cardTitle.copyWith(color: c.text),
            ),
            Text(
              item.source.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.meta.copyWith(color: c.text2),
            ),
          ],
        ),
      ),
    );
  }
}
