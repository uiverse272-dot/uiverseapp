import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/ui_icon.dart';
import 'hover_tap.dart';
import 'nav_items.dart';

/// Phone tab bar (§9.5): 56 + safe area, five cells split by `rule` lines.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.location});

  final String location;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.border))),
      padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < bottomTabs.length; i++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: i < bottomTabs.length - 1
                        ? Border(right: BorderSide(color: c.rule))
                        : null,
                  ),
                  child: _Tab(dest: bottomTabs[i], on: isNavActive(location, bottomTabs[i].path)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.dest, required this.on});

  final NavDest dest;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final fg = on ? c.accent : c.text;
    return HoverTap(
      onTap: () => context.go(dest.path),
      selected: on,
      link: true,
      minSize: const Size(double.infinity, BottomNav.height),
      builder: (context, _) => Container(
        // 3px accent bar on top of the active tab: a non-colour cue (§14).
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: on ? c.accent : Colors.transparent, width: 3)),
        ),
        padding: const EdgeInsets.only(bottom: 3),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UiIcon(dest.icon, size: 19, color: fg),
            const SizedBox(height: 4),
            Text(dest.label, style: UiText.tabLabel.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
