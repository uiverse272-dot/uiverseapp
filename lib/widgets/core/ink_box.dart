import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';

/// 1px ink box — the base of almost every surface (§5, §16.4).
class InkBox extends StatelessWidget {
  const InkBox({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.padding,
    this.shadow = 0,
    this.dashed = false,
  });

  final Widget child;

  /// Fill; defaults to `surface`.
  final Color? color;

  /// Border; defaults to `border`.
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  /// Offset-shadow depth: 0, 2, 3, 4, 5 or 6 (see [Lift]).
  final double shadow;

  /// Dashed 1px border for placeholders (layout skeletons, drop zones).
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final line = borderColor ?? c.border;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        border: dashed ? null : Border.all(color: line),
        boxShadow: shadow > 0 ? [hardShadow(shadow, c.border)] : null,
      ),
      child: child,
    );
    if (!dashed) return box;
    return CustomPaint(foregroundPainter: DashedBorderPainter(line), child: box);
  }
}

/// Paints a 1px dashed rectangle around its child (4 on / 3 off).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    void dash(Offset a, Offset b) {
      final len = (b - a).distance;
      final dir = (b - a) / len;
      for (double d = 0; d < len; d += 7) {
        canvas.drawLine(a + dir * d, a + dir * (d + 4 > len ? len : d + 4), p);
      }
    }

    const h = 0.5;
    dash(const Offset(h, h), Offset(size.width - h, h));
    dash(Offset(size.width - h, h), Offset(size.width - h, size.height - h));
    dash(Offset(size.width - h, size.height - h), Offset(h, size.height - h));
    dash(Offset(h, size.height - h), const Offset(h, h));
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color;
}
