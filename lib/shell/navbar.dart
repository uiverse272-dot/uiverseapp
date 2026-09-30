import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';
import '../state/saves.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/ui_icon.dart';
import '../widgets/core/back_dismiss.dart';
import '../widgets/core/hover_tap.dart';
import 'nav_items.dart';
import 'rail.dart';
import 'search_field.dart';
import 'theme_toggle.dart';
import '../widgets/core/entrance.dart';

/// Top bar of ruled cells, 64 tall (§9.3).
///
/// Phone: logo · yellow search · theme. ≥768: search · profile · saved.
/// ≥1024 adds "More ▾" before the profile cell.
class Navbar extends StatelessWidget {
  const Navbar({super.key, this.readingAs, this.location = ''});

  /// Forwarded to the navbar [SearchField] for its "Reading as" chips.
  final ReadingAsBuilder? readingAs;

  /// Current path, for the active "More" entry.
  final String location;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final w = MediaQuery.sizeOf(context).width;
    final wide = w >= Bp.md;
    final lg = w >= Bp.lg;
    final rule = BorderSide(color: c.border);

    return Container(
      height: height,
      decoration: BoxDecoration(color: c.bg, border: Border(bottom: rule)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!wide)
            Container(
              width: 64,
              decoration: BoxDecoration(border: Border(right: rule)),
              child: const HomeLogo(),
            ),
          Expanded(
            child: Container(
              color: c.signal,
              padding: EdgeInsets.symmetric(horizontal: wide ? 20 : 12),
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SearchField.compact(readingAs: readingAs),
              ),
            ),
          ),
          if (lg) _Cell(child: _MoreMenu(location: location)),
          if (wide) const _Cell(child: _ProfileCell()),
          if (wide) const _Cell(child: _SavedCell()),
          if (!wide) const _Cell(width: 56, child: ThemeToggle()),
        ],
      ),
    );
  }
}

/// A navbar cell with the left ink rule.
class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.width});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(border: Border(left: BorderSide(color: context.ui.border))),
      child: child,
    );
  }
}

class _ProfileCell extends ConsumerWidget {
  const _ProfileCell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ui;
    final count = ref.watch(savesProvider.select((s) => s.count));
    return HoverTap(
      onTap: () => context.go(Routes.me),
      link: true,
      builder: (context, hovered) => Container(
        width: 220,
        color: hovered ? c.bgSubtle : null,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          children: [
            Container(
              width: 64,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(right: BorderSide(color: c.border)),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.signal, border: Border.all(color: c.border)),
                alignment: Alignment.center,
                child: UiIcon(Ui.user, size: 20, color: c.onSignal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.mono(13.5, bold: true, height: 1.25, color: c.text),
                  ),
                  Text(
                    count > 0 ? '$count saved' : 'Interface seeker',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.mono(11, height: 1.25, color: c.text2),
                  ),
                ],
              ),
            ),
            UiIcon(Ui.chevron, size: 15, color: c.text),
          ],
        ),
      ),
    );
  }
}

class _SavedCell extends ConsumerWidget {
  const _SavedCell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ui;
    final count = ref.watch(savesProvider.select((s) => s.count));
    return HoverTap(
      onTap: () => context.go(Routes.saved),
      label: count > 0 ? 'Saved, $count' : 'Saved',
      link: true,
      builder: (context, hovered) => Container(
        width: 64,
        color: hovered ? c.bgSubtle : null,
        child: Stack(
          children: [
            Center(child: UiIcon(Ui.bookmark, size: 20, color: c.text)),
            if (count > 0)
              Positioned(
                top: 14,
                right: 12,
                child: Container(
                  height: 16,
                  constraints: const BoxConstraints(minWidth: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: c.accent, border: Border.all(color: c.border)),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: UiText.mono(9.5, bold: true, height: 1, track: 0, color: c.accentFg)
                        .copyWith(fontFeatures: UiText.tabular),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "More ▾" (≥1024): 192-wide menu under the cell's right edge, closes on outside tap.
class _MoreMenu extends StatefulWidget {
  const _MoreMenu({required this.location});

  final String location;

  @override
  State<_MoreMenu> createState() => _MoreMenuState();
}

class _MoreMenuState extends State<_MoreMenu> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final Object _group = Object();

  void _toggle() => setState(_portal.toggle);

  void _close() {
    if (_portal.isShowing) setState(_portal.hide);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return BackDismiss(
      active: _portal.isShowing,
      onDismiss: _close,
      child: TapRegion(
        groupId: _group,
        child: CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _portal,
            overlayChildBuilder: _menu,
            child: HoverTap(
              onTap: _toggle,
              expanded: _portal.isShowing,
              builder: (context, hovered) => Container(
                color: hovered ? c.bgSubtle : null,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('More', style: UiText.body.copyWith(color: c.text)),
                    const SizedBox(width: 8),
                    UiIcon(Ui.chevron, size: 14, color: c.text),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    final c = context.ui;
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 1),
        child: TapRegion(
          groupId: _group,
          onTapOutside: (_) => _close(),
          child: FadeIn(
            child: Container(
              width: 192,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                boxShadow: [hardShadow(Lift.l3, c.border)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < moreMenu.length; i++)
                    _MoreItem(
                      dest: moreMenu[i],
                      on: isNavActive(widget.location, moreMenu[i].path),
                      last: i == moreMenu.length - 1,
                      onTap: () {
                        _close();
                        context.go(moreMenu[i].path);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A "More" menu row. Active = accent label + a 3px accent bar (non-colour cue, §14).
class _MoreItem extends StatelessWidget {
  const _MoreItem({required this.dest, required this.on, required this.last, required this.onTap});

  final NavDest dest;
  final bool on;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      link: true,
      selected: on,
      minSize: const Size(double.infinity, 48),
      builder: (context, hovered) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.fromLTRB(11, 10, 14, 10),
        decoration: BoxDecoration(
          color: hovered ? c.bgSubtle : null,
          border: Border(
            left: BorderSide(color: on ? c.accent : Colors.transparent, width: 3),
            bottom: last ? BorderSide.none : BorderSide(color: c.rule),
          ),
        ),
        child: Text(dest.label, style: UiText.body.copyWith(color: on ? c.accent : c.text)),
      ),
    );
  }
}
