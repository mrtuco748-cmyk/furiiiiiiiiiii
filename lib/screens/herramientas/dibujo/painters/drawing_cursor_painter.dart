import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/drawing_tool_type.dart';

/// Pintor de la guía visual / retícula circular de pincel y borrador (Brush Cursor).
/// Muestra un círculo en tiempo real con el diámetro idéntico al grosor del trazo (strokeWidth),
/// con doble contorno de alto contraste (oscuro y blanco) y soporte de simetría especular.
class DrawingCursorPainter extends CustomPainter {
  final Offset? cursorPosition;
  final List<Offset> mirroredPositions;
  final double strokeWidth;
  final DrawingToolType tool;
  final Color color;
  final bool visible;
  final double pressure;

  const DrawingCursorPainter({
    required this.cursorPosition,
    this.mirroredPositions = const [],
    required this.strokeWidth,
    required this.tool,
    required this.color,
    required this.visible,
    this.pressure = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible || cursorPosition == null) return;

    final allPositions = [cursorPosition!, ...mirroredPositions];
    final isEraser = tool == DrawingToolType.eraser;

    // Calcular radio exacto: diámetro = grosor del lápiz / goma
    double radius;
    if (tool == DrawingToolType.gPen && pressure > 0) {
      radius = (strokeWidth * (0.6 + pressure * 0.8)).clamp(1.0, 50.0) / 2.0;
    } else {
      radius = strokeWidth / 2.0;
    }
    final effectiveRadius = math.max(1.5, radius);

    for (final pos in allPositions) {
      _drawCursorRing(canvas, pos, effectiveRadius, isEraser);
    }
  }

  void _drawCursorRing(Canvas canvas, Offset center, double radius, bool isEraser) {
    if (isEraser) {
      // 1. Relleno tenue de borrador
      final fillPaint = Paint()
        ..color = const Color(0x26FF5252)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);

      // 2. Anillo exterior oscuro para contrastar en fondos claros
      final darkRing = Paint()
        ..color = const Color(0x99000000)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, darkRing);

      // 3. Anillo interior blanco brillante
      final whiteRing = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, whiteRing);

      // 4. Punto central de precisión milimétrica
      final centerDot = Paint()
        ..color = const Color(0xFFFF5252)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 1.2, centerDot);
    } else {
      // 1. Relleno tenue con el color actual de la tinta
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);

      // 2. Anillo exterior oscuro para contraste en lienzo blanco
      final darkRing = Paint()
        ..color = const Color(0x88000000)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, darkRing);

      // 3. Anillo interior blanco brillante para contraste en trazos oscuros
      final whiteRing = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, whiteRing);

      // 4. Punto central de precisión
      final centerDot = Paint()
        ..color = const Color(0xFF00D4FF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 1.0, centerDot);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingCursorPainter oldDelegate) {
    return oldDelegate.cursorPosition != cursorPosition ||
        oldDelegate.visible != visible ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.tool != tool ||
        oldDelegate.color != color ||
        oldDelegate.pressure != pressure ||
        oldDelegate.mirroredPositions.length != mirroredPositions.length;
  }
}
