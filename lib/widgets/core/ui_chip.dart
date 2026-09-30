import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import 'hover_tap.dart';
import 'ui_icon.dart';

/// Square bordered chip / small button (§10.5, §10.14): 1px ink border,
/// `bg-subtle` on hover, accent fill when [on].
///
/// With a [height] the chip is a fixed-height control (filters, toggles: 32);
/// with `height: null` it hugs its text plus [vPad] (suggestions, "Move to…").
class UiChip extends StatelessWidget {
  const UiChip(
    this.label, {
    super.key,
    required this.onTap,
    this.on = false,
    this.height = 32,
    this.hPad = 10,
    this.vPad = 0,
    this.restFill,
    this.style,
    this.muted = false,
    this.trailing,
    this.semanticLabel,
    this.selected,
    this.toggled,
    this.expanded,
    this.link = false,
    this.minSize = const Size(0, 48),
  });

  final String label;
  final VoidCallback? onTap;

  /// Accent fill with `accent-fg` text.
  final bool on;
  final double? height;
  final double hPad;
  final double vPad;

  /// Fill at rest (e.g. `surface` for home category chips); none by default.
  final Color? restFill;

  /// Text style without colour; defaults to [UiText.chip] (12.5).
  final TextStyle? style;

  /// Text is `text-2` at rest and `text` on hover (instead of always `text`).
  final bool muted;

  /// Icon after the label (e.g. the chevron on a popover trigger), 13px.
  final Ui? trailing;

  /// Accessible name; when null the label text is read as is.
  final String? semanticLabel;
  final bool? selected;
  final bool? toggled;
  final bool? expanded;
  final bool link;

  /// Minimum hit area (§14); the visual box keeps its own size.
  final Size minSize;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      label: semanticLabel,
      selected: selected,
      toggled: toggled,
      expanded: expanded,
      link: link,
      minSize: minSize,
      builder: (context, hovered) {
        final Color fg = on ? c.accentFg : (muted && !hovered ? c.text2 : c.text);
        Widget child = Text(label, style: (style ?? UiText.chip).copyWith(color: fg));
        if (trailing != null) {
          child = Row(
            mainAxisSize: MainAxisSize.min,
            children: [child, const SizedBox(width: 6), UiIcon(trailing!, size: 13, color: fg)],
          );
        }
        return AnimatedContainer(
          duration: motion(context, kTransition),
          height: height,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: on ? c.accent : (hovered ? c.bgSubtle : restFill),
            border: Border.all(color: c.border),
          ),
          // widthFactor keeps a fixed-height chip as wide as its content even
          // when the parent's width is bounded.
          child: height == null ? child : Align(widthFactor: 1, child: child),
        );
      },
    );
  }
}

/// Chip with a trailing ✕ that removes it (§10.14): border, `bg-subtle`, 8×4,
/// 12px; hover → `border-strong`.
class RemovableChip extends StatelessWidget {
  const RemovableChip(this.label, {super.key, required this.onRemove, this.gap = 4, this.mutedIcon = false});

  final String label;
  final VoidCallback onRemove;

  /// Space between the label and the ✕.
  final double gap;

  /// Draw the ✕ in `text-2` instead of `text`.
  final bool mutedIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onRemove,
      label: 'Remove $label',
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.bgSubtle,
          border: Border.all(color: hovered ? c.borderStrong : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: UiText.small.copyWith(color: c.text)),
            SizedBox(width: gap),
            UiIcon(Ui.close, size: 11, color: mutedIcon ? c.text2 : c.text),
          ],
        ),
      ),
    );
  }
}
