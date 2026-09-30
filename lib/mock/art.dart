/// Decorative paint layers drawn inside a box: gradients, glows and blobs.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' hide Viewport;


/// A decorative paint layer drawn inside a [B]'s rounded rect (gradients,
/// glows, blobs) — the web's absolutely positioned decoration `div`s.
sealed class ArtLayer {
  const ArtLayer();
  void paint(Canvas canvas, Rect r);
}

/// `radial-gradient(rx ry at fx fy, color, transparent stop)`.
class Radial extends ArtLayer {
  const Radial({
    required this.fx,
    required this.fy,
    required this.rx,
    required this.ry,
    required this.color,
    this.stop = 0.7,
  });

  final double fx, fy, rx, ry, stop;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is Radial &&
      other.fx == fx &&
      other.fy == fy &&
      other.rx == rx &&
      other.ry == ry &&
      other.stop == stop &&
      other.color == color;

  @override
  int get hashCode => Object.hash(fx, fy, rx, ry, stop, color);

  @override
  void paint(Canvas canvas, Rect r) {
    if (rx <= 0 || ry <= 0) return;
    final cx = r.left + r.width * fx;
    final cy = r.top + r.height * fy;
    final sy = ry / rx;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1, sy);
    final paint = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, rx, [color, color.withAlpha(0)], [0, stop]);
    canvas.drawRect(
      Rect.fromLTRB(r.left - cx, (r.top - cy) / sy, r.right - cx, (r.bottom - cy) / sy),
      paint,
    );
    canvas.restore();
  }
}

/// `linear-gradient(<angle>deg, colors…)`; a null colour is `transparent`.
class Linear extends ArtLayer {
  const Linear(this.angle, this.colors, this.stops);

  final double angle;
  final List<Color?> colors;
  final List<double> stops;

  @override
  bool operator ==(Object other) =>
      other is Linear &&
      other.angle == angle &&
      listEquals(other.colors, colors) &&
      listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hash(angle, Object.hashAll(colors), Object.hashAll(stops));

  @override
  void paint(Canvas canvas, Rect r) {
    final a = angle * math.pi / 180;
    final dir = Offset(math.sin(a), -math.cos(a));
    final half = (r.width * math.sin(a).abs() + r.height * math.cos(a).abs()) / 2;
    final c = r.center;
    final resolved = <Color>[];
    for (var i = 0; i < colors.length; i++) {
      final col = colors[i];
      resolved.add(col ?? (i > 0 ? resolved[i - 1].withAlpha(0) : const Color(0x00000000)));
    }
    final paint = Paint()
      ..shader = ui.Gradient.linear(c - dir * half, c + dir * half, resolved, stops);
    canvas.drawRect(r, paint);
  }
}

/// An absolutely positioned (rounded) rect or ellipse. Position is
/// `fraction of the frame + pixel offset` on each axis.
class Disc extends ArtLayer {
  const Disc({
    this.fx = 0,
    this.dx = 0,
    this.fy = 0,
    this.dy = 0,
    required this.w,
    required this.h,
    this.r,
    this.fill,
    this.stroke,
    this.strokeW = 1,
  });

  final double fx, dx, fy, dy, w, h, strokeW;

  /// Corner radius; null = ellipse.
  final double? r;
  final Color? fill;
  final Color? stroke;

  @override
  bool operator ==(Object other) =>
      other is Disc &&
      other.fx == fx &&
      other.dx == dx &&
      other.fy == fy &&
      other.dy == dy &&
      other.w == w &&
      other.h == h &&
      other.strokeW == strokeW &&
      other.r == r &&
      other.fill == fill &&
      other.stroke == stroke;

  @override
  int get hashCode => Object.hash(fx, dx, fy, dy, w, h, strokeW, r, fill, stroke);

  @override
  void paint(Canvas canvas, Rect frame) {
    final rect = Rect.fromLTWH(frame.left + frame.width * fx + dx, frame.top + frame.height * fy + dy, w, h);
    if (fill != null) {
      final p = Paint()..color = fill!;
      if (r == null) {
        canvas.drawOval(rect, p);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r!)), p);
      }
    }
    if (stroke != null) {
      final p = Paint()
        ..color = stroke!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW;
      final inner = rect.deflate(strokeW / 2);
      if (r == null) {
        canvas.drawOval(inner, p);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(math.max(0, r! - strokeW / 2))), p);
      }
    }
  }
}
