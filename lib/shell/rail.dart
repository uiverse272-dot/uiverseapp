import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/logo_mark.dart';
import '../widgets/core/ui_icon.dart';
import '../widgets/core/hover_tap.dart';
import 'nav_items.dart';
import 'theme_toggle.dart';

/// Desktop/tablet rail, 88 wide (§9.4). Phones get [BottomNav] instead.
class Rail extends StatelessWidget {
  const Rail({super.key, required this.location});

  /// Current path, for the active item.
  final String location;

  static const double width = 88;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: width,
      decoration: BoxDecoration(color: c.bg, border: Border(right: BorderSide(color: c.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: const HomeLogo(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [for (final d in railMain) RailItem(dest: d, location: location)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                for (final d in railFoot) RailItem(dest: d, location: location),
                const ThemeToggle(rail: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo cell → home. Lifts (−2,−2) on hover (§6).
class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return HoverTap(
      onTap: () => context.go(Routes.home),
      label: 'Uiverse home',
      link: true,
      builder: (context, hovered) => AnimatedSlide(
        duration: motion(context, kTransition),
        offset: hovered ? const Offset(-2 / 34, -2 / 34) : Offset.zero,
        child: const LogoMark(),
      ),
    );
  }
}

/// Icon 21 over label 10.5. Active = accent + a 3px accent bar (non-colour cue, §14).
class RailItem extends StatelessWidget {
  const RailItem({super.key, required this.dest, required this.location});

  final NavDest dest;
  final String location;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = isNavActive(location, dest.path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: HoverTap(
        onTap: () => context.go(dest.path),
        selected: on,
        link: true,
        minSize: const Size(Rail.width - 1, 48),
        builder: (context, hovered) {
          final fg = on || hovered ? c.accent : c.text;
          return Container(
            width: Rail.width - 1,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: on ? c.accent : Colors.transparent, width: 3),
                right: const BorderSide(color: Colors.transparent, width: 3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiIcon(dest.icon, size: 21, color: fg),
                const SizedBox(height: 6),
                Text(dest.label, style: UiText.navLabel.copyWith(color: fg)),
              ],
            ),
          );
        },
      ),
    );
  }
}
