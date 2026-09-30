import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ui_icon_paths.dart';

/// Icon set (24 grid, stroke 1.8, round caps/joins — §7).
///
/// Geometry lives in `ui_icon_paths.dart`, generated from `assets/icons/*.svg`
/// by `tool/gen_icons.mjs`; add an SVG there and a value here, then regenerate.
enum Ui {
  bookmark,
  bookmarkFilled,
  check,
  chevron,
  close,
  code,
  compass,
  copy,
  external,
  filter,
  grid,
  home,
  layers,
  layout,
  monitor,
  moon,
  palette,
  phone,
  plus,
  search,
  sparkle,
  sun,
  upload,
  user,
}

/// Paints a [Ui] icon in [color] (defaults to the ambient text colour).
class UiIcon extends StatelessWidget {
  const UiIcon(this.icon, {super.key, this.size = 16, this.color, this.semanticLabel, this.turns = 0});

  final Ui icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  /// Rotation in full turns (0.5 = 180°, used for "expand" chevrons).
  final double turns;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? DefaultTextStyle.of(context).style.color ?? IconTheme.of(context).color!;
    final paint = CustomPaint(
      size: Size.square(size),
      painter: _UiIconPainter(icon, tint, turns),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: paint);
    return Semantics(label: semanticLabel, image: true, child: paint);
  }
}

class _UiIconPainter extends CustomPainter {
  const _UiIconPainter(this.icon, this.color, this.turns);

  final Ui icon;
  final Color color;
  final double turns;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = kUiIconShapes[icon]!;
    if (turns != 0) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(turns * 2 * math.pi);
      canvas.translate(-size.width / 2, -size.height / 2);
    }
    canvas.scale(size.width / 24);
    final fill = shape.fill;
    if (fill != null) canvas.drawPath(fill, Paint()..color = color);
    canvas.drawPath(
      shape.stroke,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_UiIconPainter old) => old.icon != icon || old.color != color || old.turns != turns;
}
