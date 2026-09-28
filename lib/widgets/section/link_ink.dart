import 'package:flutter/material.dart';

import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/hover_tap.dart';

/// `link-ink` text link (§10.6): 1px underline ~3px below the text, colour
/// → accent on hover. Announced as a link.
class LinkInk extends StatelessWidget {
  const LinkInk(
    this.label, {
    super.key,
    required this.onTap,
    this.size = 12,
    this.leading,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;

  /// Font size (12 in section heads, 11.5 in Pick of the week).
  final double size;

  /// Optional icon builder shown before the label (e.g. Close on "Clear");
  /// receives the current colour.
  final Widget Function(Color color)? leading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      link: true,
      label: semanticLabel ?? label,
      minSize: const Size(0, 32),
      builder: (context, hovered) {
        final color = hovered ? c.accent : c.text;
        final text = DecoratedBox(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color))),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(label, style: UiText.mono(size, height: 1.2).copyWith(color: color)),
          ),
        );
        if (leading == null) return text;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [leading!(color), const SizedBox(width: 4), text],
        );
      },
    );
  }
}
