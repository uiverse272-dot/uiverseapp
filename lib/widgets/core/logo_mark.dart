import 'package:flutter/material.dart';

import '../../theme/uiverse_colors.dart';

/// "The U cradling a planet" (§8). Fill = accent, planet = signal, strokes always ink.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Semantics(
      label: 'Uiverse',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(accent: c.accent, signal: c.signal),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.accent, required this.signal});
  final Color accent;
  final Color signal;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32);
    const ink = UiverseColors.ink;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = ink;
    const tile = Rect.fromLTWH(1, 1, 30, 30);
    canvas.drawRect(tile, Paint()..color = accent);
    canvas.drawRect(tile, stroke..strokeWidth = 2);

    final u = Path()
      ..moveTo(9, 7)
      ..lineTo(9, 18)
      ..arcToPoint(const Offset(23, 18), radius: const Radius.circular(7), clockwise: false)
      ..lineTo(23, 7);
    canvas.drawPath(
      u,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = ink
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.square,
    );

    const planet = Offset(16, 17.5);
    canvas.drawCircle(planet, 3, Paint()..color = signal);
    canvas.drawCircle(planet, 3, stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.accent != accent || old.signal != signal;
}
