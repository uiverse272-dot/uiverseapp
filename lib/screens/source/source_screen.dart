import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/format.dart';
import '../../data/palettes.dart';
import '../../data/taxonomy.dart';
import '../../router/not_found_page.dart';
import '../../router/routes.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/copy_value.dart';
import '../../widgets/core/hover_tap.dart';
import '../../widgets/feed/feed.dart';
import '../../widgets/feed/url_query.dart';
import '../../widgets/section/section.dart';
import '../search/segment_tab.dart';
import 'source_data.dart';

/// `/source/[slug]?tab=` — one product's whole system (§12): 56 swatch +
/// header, domain / industry / tech chips and totals, then pinned tabs
/// Screens / Components / Palette & type. Unknown slug → [NotFoundPage].
class SourceScreen extends StatelessWidget {
  const SourceScreen({super.key, required this.slug, this.query = const <String, String>{}});

  final String slug;

  /// URL query params: `tab` (`screens` | `components` | `system`).
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final SourceView? v = sourceView(slug);
    if (v == null) return const NotFoundPage();
    final String tab = query['tab'] ?? 'screens';

    return CustomScrollView(
      slivers: [
        SliverShell(sliver: SliverToBoxAdapter(child: _Header(view: v))),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        StickyBar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (String id, String label, int n) in sourceTabs(v)) ...[
                  if (id != 'screens') const SizedBox(width: 4),
                  SegmentTab(
                    label: label,
                    count: n > 0 ? n : null,
                    selected: tab == id,
                    onTap: () => context.go(withQuery(Routes.source(slug), <String, String>{'tab': id})),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverShell(
          sliver: SliverPadding(
            padding: const EdgeInsets.only(top: 20),
            sliver: switch (tab) {
              'screens' => Feed(items: v.screens),
              'components' => Feed(items: v.components),
              'system' when v.palette != null => SliverToBoxAdapter(child: SystemPanels(view: v)),
              _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.view});

  final SourceView view;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final s = view.source;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 56, height: 56, color: view.palette?.accent),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PageHeader brings its own top 28; the web keeps it too.
                PageHeader(title: s.name, sub: s.about),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Tag(s.domain),
                      _Tag(
                        taxName(kIndustries, s.industry),
                        onTap: () => context.go(withQuery(Routes.web, <String, String>{'industry': s.industry})),
                      ),
                      for (final String t in s.tech)
                        _Tag(
                          taxName(kTechnologies, t),
                          onTap: () => context.go(withQuery(Routes.web, <String, String>{'tech': t})),
                        ),
                      Text(
                        '· ${compact(view.totalSaves)} saves across ${view.all.length} items',
                        style: UiText.chip.copyWith(color: c.text3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered 12.5 text-2 chip, 8×4; a link (hover bg-subtle) when [onTap] is set.
class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget box(bool hovered) => AnimatedContainer(
          duration: motion(context, kTransition),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hovered ? c.bgSubtle : null,
            border: Border.all(color: c.border),
          ),
          child: Text(text, style: UiText.chip.copyWith(color: c.text2)),
        );
    if (onTap == null) return box(false);
    return HoverTap(
      onTap: onTap,
      link: true,
      label: text,
      builder: (context, hovered) => box(hovered),
    );
  }
}

/// "Palette & type" tab: "Inferred palette" and "Recurring structure"
/// panels, side by side at ≥1024.
class SystemPanels extends StatelessWidget {
  const SystemPanels({super.key, required this.view});

  final SourceView view;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= Bp.lg;
    const Widget gap = SizedBox(width: 16, height: 16);
    final Widget palette = _Panel(title: 'Inferred palette', child: _PaletteRows(view: view));
    final Widget structure = _Panel(title: 'Recurring structure', child: _Structure(view: view));
    return Padding(
      padding: const EdgeInsets.only(bottom: 56),
      child: wide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: palette), gap, Expanded(child: structure)],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [palette, gap, structure],
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Semantics(
              header: true,
              child: Text(title, style: UiText.panelTitle.copyWith(color: c.text)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PaletteRows extends StatelessWidget {
  const _PaletteRows({required this.view});

  final SourceView view;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      children: [
        for (final (String label, Color color) in view.paletteRows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: color, border: Border.all(color: c.border)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: UiText.chip.copyWith(color: c.text))),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: CopyValue(hexOf(color)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Structure extends StatelessWidget {
  const _Structure({required this.view});

  final SourceView view;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Across ${view.screens.length} captures, these blocks appear most often. '
            'This is what a design system looks like from the outside.',
            style: UiText.mono(13.5, height: 1.625, color: c.text2),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final String b in view.recurringBlocks)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: c.border)),
                child: Text(b, style: UiText.small.copyWith(color: c.text2)),
              ),
          ],
        ),
      ],
    );
  }
}
