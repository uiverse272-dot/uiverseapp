import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import 'hover_tap.dart';

/// Square text button: 1px border with `bg-subtle` hover, or an [accent]
/// fill (primary CTA). Fills the width it is given; lays out at least 48
/// tall with the box centred.
class BoxButton extends StatelessWidget {
  const BoxButton(
    this.label, {
    super.key,
    required this.onTap,
    this.accent = false,
    this.height = 40,
    this.style,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;
  final double height;

  /// Text style without colour; defaults to [UiText.button] (13.5).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      label: label,
      // The box keeps [height]; the hit area is at least 48 (§14).
      minSize: Size(0, math.max(48, height)),
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent ? c.accent : (hovered ? c.bgSubtle : null),
          border: accent ? null : Border.all(color: c.border),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (style ?? UiText.button).copyWith(color: accent ? c.accentFg : c.text),
        ),
      ),
    );
  }
}
