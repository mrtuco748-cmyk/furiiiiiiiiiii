import 'package:flutter/material.dart';
import '../models/note_style_config.dart';

/// Pintor para la esquina inferior-derecha adaptada matemáticamente a cada forma.
class PizarronAdaptiveResizeCornerPainter extends CustomPainter {
  final Color color;
  final NoteShapeType shape;

  PizarronAdaptiveResizeCornerPainter({
    required this.color,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final p1 = Path()
      ..moveTo(cx + 5, cy - 3)
      ..lineTo(cx + 5, cy + 5)
      ..lineTo(cx - 3, cy + 5);
    canvas.drawPath(p1, paint);

    final p2 = Path()
      ..moveTo(cx + 1, cy - 1)
      ..lineTo(cx + 1, cy + 1)
      ..lineTo(cx - 1, cy + 1);
    canvas.drawPath(p2, paint);
  }

  @override
  bool shouldRepaint(covariant PizarronAdaptiveResizeCornerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shape != shape;
  }
}
