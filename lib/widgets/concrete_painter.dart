import 'dart:math';
import 'package:flutter/material.dart';

final _rng = Random(42);

class ConcretePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A), Color(0xFF222222), Color(0xFF151515)],
        stops: [0, 0.3, 0.7, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    final noise = Paint()..color = Colors.white.withValues(alpha: 0.015);
    for (int i = 0; i < 80; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final s = _rng.nextDouble() * 4 + 1;
      canvas.drawRect(Rect.fromLTWH(x, y, s, s), noise);
    }
    final line = Paint()..color = Colors.white.withValues(alpha: 0.04)..strokeWidth = 0.5;
    for (int i = 0; i < 12; i++) {
      final y = _rng.nextDouble() * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
