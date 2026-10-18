import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../mock/scroll_aware_mock.dart';
import '../../router/routes.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/hover_tap.dart';
import '../../widgets/feed/item_aspect.dart';
import '../directory/directory_page.dart';

/// `/creators` (§12): creator directory; each card links to its source page.
class CreatorsScreen extends StatelessWidget {
  const CreatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DirectoryPage(
      title: 'Creators',
      sub: 'A user and a creator are the same identity — a creator is simply a user with a filled '
          'profile. One object, one page, no merge problem later.',
      itemCount: kCreators.length,
      itemBuilder: (context, i) => CreatorCard(creator: kCreators[i]),
    );
  }
}

/// A creator's first three screens (web: `ITEMS` filtered by source, kind screen).
List<Item> creatorWork(Creator creator) =>
    screens().where((Item i) => i.source.slug == creator.source.slug).take(3).toList();

/// One creator: swatch, name, role, optional "Available" tag, three 1.1-aspect
/// previews and "N screens · N followers". Hover → border-strong.
class CreatorCard extends StatelessWidget {
  const CreatorCard({super.key, required this.creator});

  final Creator creator;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final List<Item> work = creatorWork(creator);
    return HoverTap(
      onTap: () => context.go(Routes.source(creator.handle)),
      link: true,
      minSize: Size.zero,
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: hovered ? c.borderStrong : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(width: 36, height: 36, color: work.isEmpty ? c.bgSubtle : work.first.palette.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.mono(14, bold: true, color: c.text),
                      ),
                      Text(
                        creator.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.small.copyWith(color: c.text3),
                      ),
                    ],
                  ),
                ),
                if (creator.available) ...[
                  const SizedBox(width: 8),
                  const AvailableTag(),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < work.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(border: Border.all(color: c.border)),
                        child: ScrollAwareMock(item: withAspect(work[i], 1.1)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            DefaultTextStyle(
              style: UiText.caption.copyWith(color: c.text3, fontFeatures: UiText.tabular),
              child: Row(
                children: [
                  Expanded(child: Text('${creator.screens} screens')),
                  Text('${compact(creator.followers)} followers'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Available" tag (§10.14): 1px border, 10.5px text-2.
class AvailableTag extends StatelessWidget {
  const AvailableTag({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: c.border)),
      child: Text('Available', style: UiText.mono(10.5, height: 1.2, color: c.text2)),
    );
  }
}
