import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../router/routes.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/hover_tap.dart';
import '../../widgets/section/section.dart';
import '../directory/directory_page.dart';

/// Where `/u/:handle` should go instead: `/source/<handle>` when [handle] is
/// a known source slug (web `redirect`), otherwise null. Use it in the
/// route's `redirect`.
String? profileRedirect(String handle) =>
    kSources.any((Source s) => s.slug == handle) ? Routes.source(handle) : null;

/// Profile hub link cards: label, destination, note.
const List<(String, String, String)> kProfileLinks = [
  ('Saved', Routes.saved, 'Everything you kept, plus collections.'),
  ('Upload', Routes.upload, 'Paste a URL — we capture and tag it.'),
  ('Collections', Routes.saved, 'Boards, sections, private notes.'),
  ('Settings', Routes.pricing, 'Plan, profile, notifications.'),
];

/// `/u/:handle` (§12). Every handle that is not a source (see
/// [profileRedirect]) shows the same "Your profile" hub, as on the web.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    final bool twoCol = MediaQuery.sizeOf(context).width >= Bp.sm;
    final List<Widget> cards = [
      for (final (String label, String href, String note) in kProfileLinks)
        _LinkCard(label: label, note: note, onTap: () => context.go(href)),
    ];
    return NarrowPage(
      children: [
        const PageHeader(
          title: 'Your profile',
          sub: 'User and creator are one identity. Sign-in, uploads and creator analytics sit behind '
              'this page in the real build — this prototype ships the discovery half.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < cards.length; i += twoCol ? 2 : 1) ...[
                if (i > 0) const SizedBox(height: 16),
                if (twoCol)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[i]),
                      const SizedBox(width: 16),
                      Expanded(child: i + 1 < cards.length ? cards[i + 1] : const SizedBox.shrink()),
                    ],
                  )
                else
                  cards[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Bordered surface link card: 14 bold label + 13 text-2 note; hover
/// border-strong.
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.label, required this.note, required this.onTap});

  final String label;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      link: true,
      minSize: Size.zero,
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: hovered ? c.borderStrong : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: UiText.mono(14, bold: true, color: c.text)),
            const SizedBox(height: 6),
            Text(note, style: UiText.body.copyWith(color: c.text2)),
          ],
        ),
      ),
    );
  }
}
