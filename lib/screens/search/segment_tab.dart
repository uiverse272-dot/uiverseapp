import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/hover_tap.dart';

/// Segmented tab as a link (§10.14): 13px, padding 10×6; selected = accent
/// fill, others text-2 (hover text); optional [count] suffix at 60% opacity,
/// tabular. Used by the Search kind tabs and the Source tabs.
class SegmentTab extends StatelessWidget {
  const SegmentTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Shown after the label when non-null.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      link: true,
      selected: selected,
      label: count == null ? label : '$label $count',
      builder: (context, hovered) {
        final Color fg = selected ? c.accentFg : (hovered ? c.text : c.text2);
        return AnimatedContainer(
          duration: motion(context, kTransition),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: selected ? c.accent : null,
          child: Text.rich(
            TextSpan(
              text: label,
              children: [
                if (count != null)
                  TextSpan(
                    text: ' $count',
                    style: TextStyle(color: fg.withValues(alpha: fg.a * 0.6), fontFeatures: UiText.tabular),
                  ),
              ],
            ),
            style: UiText.body.copyWith(color: fg),
          ),
        );
      },
    );
  }
}
