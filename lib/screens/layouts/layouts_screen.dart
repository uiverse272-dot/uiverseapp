import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart' hide Block;

import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../mock/mock_screen.dart';
import '../../router/routes.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/hover_tap.dart';
import '../../widgets/core/ink_box.dart';
import '../../widgets/feed/item_aspect.dart';
import '../../widgets/core/box_button.dart';
import '../directory/directory_page.dart';

/// `/layouts` (§12): section skeletons derived from real captures.
class LayoutsScreen extends StatelessWidget {
  const LayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return DirectoryPage(
      title: 'Layouts',
      sub: 'The structure behind a page, separated from its styling. Every layout here was derived '
          'from the section order of a real capture — plan the shape first, choose components after.',
      itemCount: kLayouts.length,
      itemBuilder: (context, i) => LayoutCard(entry: kLayouts[i]),
      footer: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: Text(
          'The drag-and-drop builder is Phase 3. It plans structure — it never outputs a website.',
          style: UiText.chip.copyWith(color: c.text3),
        ),
      ),
    );
  }
}

/// `/components?component=<type>` — the component feed for one section type.
String componentFeedFor(String type) =>
    Uri(path: Routes.components, queryParameters: {'component': type}).toString();

/// Skeleton bar height for a section type (hero 26, footer 14, else 11).
double skeletonHeight(String type) => switch (type) {
      'hero' => 26,
      'footer' => 14,
      _ => 11,
    };

/// One layout: name + uses, dashed skeleton beside a 0.8-aspect preview,
/// numbered section links, Duplicate / Open in builder (UI only).
class LayoutCard extends StatelessWidget {
  const LayoutCard({super.key, required this.entry});

  final LayoutEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return InkBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.panelTitle.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.uses} uses',
                  style: UiText.caption.copyWith(color: c.text3, fontFeatures: UiText.tabular),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Column(
                  children: [
                    for (int i = 0; i < entry.sections.length; i++) ...[
                      if (i > 0) const SizedBox(height: 4),
                      InkBox(
                        dashed: true,
                        color: const Color(0x00000000),
                        child: SizedBox(width: double.infinity, height: skeletonHeight(entry.sections[i].type)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(border: Border.all(color: c.border)),
                    child: MockScreen(item: withAspect(entry.example, 0.8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < entry.sections.length; i++) _SectionLink(index: i, block: entry.sections[i]),
                ],
              ),
            ),
          ),
          // 32-tall buttons sit in 48 hit areas; 4 + 8 keeps the 12 gap.
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: BoxButton('Duplicate', onTap: () {}, height: 32, style: UiText.chip)),
              const SizedBox(width: 8),
              Expanded(child: BoxButton('Open in builder', onTap: () {}, height: 32, style: UiText.chip)),
            ],
          ),
        ],
      ),
    );
  }
}

/// "1  Navbar" — number + link to that component's feed.
class _SectionLink extends StatelessWidget {
  const _SectionLink({required this.index, required this.block});

  final int index;
  final Block block;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            '${index + 1}',
            style: UiText.navLabel.copyWith(color: c.text3, fontFeatures: UiText.tabular),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: HoverTap(
            onTap: () => context.go(componentFeedFor(block.type)),
            link: true,
            minSize: const Size(0, 24),
            builder: (context, hovered) => Text(
              block.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.small.copyWith(
                color: hovered ? c.text : c.text2,
                decoration: hovered ? TextDecoration.underline : null,
                decorationColor: c.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
