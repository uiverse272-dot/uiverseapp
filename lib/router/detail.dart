import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../shell/app_shell.dart';
import '../widgets/core/hover_tap.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../widgets/core/ui_icon.dart';
import 'routes.dart';
import '../widgets/core/entrance.dart';

/// How a detail route is shown (§10.12).
///
/// Pass [DetailPresentation.overlay] as go_router `extra` to open a detail
/// over the current screen (what [openDetail] does). Anything else — a deep
/// link, `context.go(...)`, a restored route — renders the plain page inside
/// the app shell.
enum DetailPresentation {
  page,
  overlay;

  /// The presentation of the enclosing detail route ([page] if none).
  static DetailPresentation of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PresentationScope>()?.value ?? page;
}

class _PresentationScope extends InheritedWidget {
  const _PresentationScope({required this.value, required super.child});

  final DetailPresentation value;

  @override
  bool updateShouldNotify(_PresentationScope old) => old.value != value;
}

/// Opens [item]'s detail as an overlay over the current screen.
Future<void> openDetail(BuildContext context, Item item) =>
    openDetailSlug(context, item.kind, item.slug);

/// Opens `/component/{slug}` for [Kind.component], else `/screen/{slug}`, as an overlay.
Future<void> openDetailSlug(BuildContext context, Kind kind, String slug) {
  final path = kind == Kind.component ? Routes.component(slug) : Routes.screen(slug);
  return context.push<void>(path, extra: DetailPresentation.overlay);
}

/// Page for a detail route: overlay sheet when pushed with the overlay flag,
/// otherwise the standalone page in the app shell.
Page<void> buildDetailPage(BuildContext context, GoRouterState state, Widget body) {
  if (state.extra != DetailPresentation.overlay) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: AppShell(
        location: state.uri.path,
        child: _PresentationScope(
          value: DetailPresentation.page,
          child: SingleChildScrollView(child: body),
        ),
      ),
    );
  }
  final d = motion(context, kSheet);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierColor: context.ui.overlay,
    transitionDuration: d,
    reverseTransitionDuration: d,
    transitionsBuilder: (context, animation, _, child) {
      return sheetTransition(animation, child);
    },
    child: DetailOverlay(
      child: _PresentationScope(value: DetailPresentation.overlay, child: body),
    ),
  );
}

/// The overlay chrome: full-screen sheet on phones; ≥768 a square sheet
/// (max 1700, 24 margin, L5 shadow) over the scrim. Tapping the scrim, the
/// close button, Esc or back closes it (Esc/back pop the route).
class DetailOverlay extends StatelessWidget {
  const DetailOverlay({super.key, required this.child});

  final Widget child;

  void _close(BuildContext context) => Navigator.of(context).maybePop().ignore();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final wide = context.isWide;
    final close = Positioned(
      top: 0,
      right: 0,
      child: _CloseButton(onTap: () => _close(context)),
    );

    final Widget sheet;
    if (!wide) {
      sheet = ColoredBox(
        color: c.bg,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [SingleChildScrollView(child: child), close],
          ),
        ),
      );
    } else {
      sheet = Stack(
        children: [
          // Scrim: tapping outside the sheet closes.
          Positioned.fill(
            child: Semantics(
              label: 'Close',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _close(context),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1700),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.bg,
                      border: Border.all(color: c.border),
                      boxShadow: [hardShadow(Lift.l5, c.border)],
                    ),
                    child: Stack(children: [SingleChildScrollView(child: child), close]),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Esc and Android back pop this route via BackDismissRoot (app.dart).
    return Focus(
      autofocus: true,
      child: Material(type: MaterialType.transparency, child: sheet),
    );
  }
}

/// 36×36 bordered close button; hover fills accent (§10.12).
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      label: 'Close',
      builder: (context, hovered) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: hovered ? c.accent : c.surface,
          border: Border.all(color: c.border),
        ),
        alignment: Alignment.center,
        child: UiIcon(Ui.close, size: 16, color: hovered ? c.accentFg : c.text),
      ),
    );
  }
}
