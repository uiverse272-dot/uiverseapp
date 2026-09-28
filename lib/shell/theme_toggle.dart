import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/theme.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/ui_icon.dart';
import 'hover_tap.dart';

/// Light/dark switch. Shows the *destination* icon: Moon in light, Sun in dark (§15).
///
/// [rail] = icon 21 over "Dark"/"Light" label; otherwise a full-cell icon 19.
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key, this.rail = false});

  final bool rail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ui;
    final shown = Theme.of(context).brightness;
    final dark = shown == Brightness.dark;
    final icon = dark ? Ui.sun : Ui.moon;
    void flip() => ref.read(themeModeProvider.notifier).toggle(shown).ignore();
    final label = 'Switch to ${dark ? 'light' : 'dark'} theme';

    if (rail) {
      return HoverTap(
        onTap: flip,
        label: label,
        builder: (context, hovered) {
          final fg = hovered ? c.accent : c.text;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiIcon(icon, size: 21, color: fg),
                const SizedBox(height: 6),
                Text(dark ? 'Light' : 'Dark', style: UiText.navLabel.copyWith(color: fg)),
              ],
            ),
          );
        },
      );
    }

    return HoverTap(
      onTap: flip,
      label: label,
      builder: (context, hovered) => Container(
        color: hovered ? c.bgSubtle : null,
        alignment: Alignment.center,
        child: UiIcon(icon, size: 19, color: c.text),
      ),
    );
  }
}
