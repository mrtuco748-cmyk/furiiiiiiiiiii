import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Dibuja la cuadrícula de puntos finita clásica de Milanote de forma ultra-optimizada.
/// Al contar con un lienzo finito, despacha por lotes (drawPoints) los puntos visibles
/// consumiendo prácticamente 0% de CPU y GPU.
class MilanoteGridPainter extends CustomPainter {
  final double width;
  final double height;
  final double gridSpacing;
  final Color dotColor;
  final double dotRadius;

  const MilanoteGridPainter({
    required this.width,
    required this.height,
    this.gridSpacing = 28.0,
    this.dotColor = const Color(0xFF2C2F36),
    this.dotRadius = 1.3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect visible = canvas.getLocalClipBounds();
    if (visible.isEmpty || visible.isInfinite) return;

    final double startX = (math.max(0.0, visible.left) / gridSpacing).floor() * gridSpacing;
    final double endX = math.min(width, visible.right);
    final double startY = (math.max(0.0, visible.top) / gridSpacing).floor() * gridSpacing;
    final double endY = math.min(height, visible.bottom);

    if (startX > endX || startY > endY) return;

    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = dotRadius * 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = false;

    final List<Offset> points = [];
    for (double x = startX; x <= endX; x += gridSpacing) {
      for (double y = startY; y <= endY; y += gridSpacing) {
        points.add(Offset(x, y));
      }
    }

    if (points.isNotEmpty) {
      canvas.drawPoints(PointMode.points, points, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MilanoteGridPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.gridSpacing != gridSpacing ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.dotRadius != dotRadius;
  }
}
