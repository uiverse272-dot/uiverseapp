import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import 'link_ink.dart';

export 'link_ink.dart';

/// Content max width for wide feeds (§4.2).
const double kShellWide = 2100;

/// Content max width for narrow pages (§4.2).
const double kShellNarrow = 1100;

/// Page horizontal gutter: 16 on phones, 24 ≥768 (`px-4 md:px-6`).
double pageGutter(BuildContext context) => context.isWide ? 24 : 16;

/// Horizontal padding that centres a [maxWidth] container (gutter included)
/// inside [extent].
double shellInset(double extent, double gutter, double maxWidth) =>
    gutter + math.max(0, (extent - maxWidth) / 2);

/// Centred container, padding-x 16/24, max 2100 ([wide]) or 1100 (§10.6).
class Shell extends StatelessWidget {
  const Shell({super.key, required this.child, this.wide = true});

  final Widget child;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(context);
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? kShellWide : kShellNarrow),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: child,
        ),
      ),
    );
  }
}

/// [Shell] for slivers: pads [sliver] so its content is centred with the
/// shell's max width and gutter.
class SliverShell extends StatelessWidget {
  const SliverShell({super.key, required this.sliver, this.wide = true});

  final Widget sliver;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(context);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final inset = shellInset(constraints.crossAxisExtent, gutter, wide ? kShellWide : kShellNarrow);
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          sliver: sliver,
        );
      },
    );
  }
}

/// Page title, optional sub line and optional right slot (§10.6).
/// Padding top 28, bottom 4; the right slot wraps under the title when narrow.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.sub, this.trailing});

  final String title;
  final String? sub;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 4),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: UiText.pageTitle.copyWith(color: c.text)),
                ),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 576),
                      child: Text(sub!, style: UiText.pageSub.copyWith(color: c.text2)),
                    ),
                  ),
              ],
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// "**Title** ............ more" — bold label, `link-ink` on the right,
/// baseline aligned, 12 below (§10.6).
class SectionHead extends StatelessWidget {
  const SectionHead({super.key, required this.title, this.moreLabel = 'more', this.onMore});

  final String title;
  final String moreLabel;

  /// The link is shown only when this is set.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: UiText.sectionHead.copyWith(color: c.text)),
            ),
          ),
          if (onMore != null) ...[
            const SizedBox(width: 16),
            LinkInk(moreLabel, onTap: onMore),
          ],
        ],
      ),
    );
  }
}

/// A bar pinned under the navbar while the page scrolls (§10.6): `bg`,
/// bottom border, content inside the wide shell. [height] excludes the border.
class StickyBar extends StatelessWidget {
  const StickyBar({super.key, required this.child, this.height = 52});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyBarDelegate(child: child, extent: height + 1),
    );
  }
}

class _StickyBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyBarDelegate({required this.child, required this.extent});

  final Widget child;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.ui;
    // Container (not DecoratedBox) insets the child by the border, so the
    // painted height matches [extent].
    return Container(
      height: extent,
      decoration: BoxDecoration(color: c.bg, border: Border(bottom: BorderSide(color: c.border))),
      child: Shell(child: child),
    );
  }

  @override
  bool shouldRebuild(_StickyBarDelegate old) => old.child != child || old.extent != extent;
}
