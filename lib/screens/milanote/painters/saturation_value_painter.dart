import 'package:flutter/material.dart';

/// Painter que dibuja el plano bidimensional HSV (Saturación horizontal, Brillo vertical).
class SaturationValuePainter extends CustomPainter {
  final double hue;

  const SaturationValuePainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    // 1. Color base según el tono
    canvas.drawRect(rect, Paint()..color = baseColor);

    // 2. Gradiente horizontal blanco a transparente (Saturación)
    final whiteShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, Color(0x00FFFFFF)],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = whiteShader);

    // 3. Gradiente vertical transparente a negro (Brillo/Valor)
    final blackShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Colors.black],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = blackShader);
  }

  @override
  bool shouldRepaint(covariant SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}
