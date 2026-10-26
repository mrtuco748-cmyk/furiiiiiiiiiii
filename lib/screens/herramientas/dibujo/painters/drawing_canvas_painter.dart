import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/canvas_background_type.dart';
import '../models/drawing_lasso_selection.dart';
import '../models/drawing_layer.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_symmetry_mode.dart';
import 'stroke_renderer.dart';

/// Painter de alto rendimiento para el lienzo multicapa de dibujo,
/// con renderizado de simetría en tiempo real y guías discretas.
class DrawingCanvasPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final int activeLayerIndex;
  final DrawingStroke? activeStroke;
  final List<DrawingStroke> activeMirroredStrokes;
  final CanvasBackgroundType backgroundType;
  final DrawingSymmetryMode symmetryMode;
  final DrawingLassoSelection? activeSelection;

  DrawingCanvasPainter({
    required this.layers,
    required this.activeLayerIndex,
    required this.activeStroke,
    this.activeMirroredStrokes = const [],
    this.backgroundType = CanvasBackgroundType.blank,
    this.symmetryMode = DrawingSymmetryMode.none,
    this.activeSelection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundType.color,
    );

    // 2. Trama o cuadrícula si aplica
    if (backgroundType == CanvasBackgroundType.grid) {
      _drawGrid(canvas, size);
    } else if (backgroundType == CanvasBackgroundType.dots) {
      _drawDots(canvas, size);
    }

    // 3. Renderizado secuencial de capas
    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      if (!layer.isVisible) continue;

      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: layer.opacity),
      );

      for (final stroke in layer.strokes) {
        StrokeRenderer.renderStroke(canvas, stroke);
      }

      if (i == activeLayerIndex) {
        if (activeStroke != null) {
          StrokeRenderer.renderStroke(canvas, activeStroke!);
        }
        for (final m in activeMirroredStrokes) {
          StrokeRenderer.renderStroke(canvas, m);
        }
      }

      canvas.restore();
    }

    // 4. Guías sutiles de simetría
    if (symmetryMode != DrawingSymmetryMode.none) {
      _drawSymmetryGuides(canvas, size);
    }

    // 5. Selección de Lazo activa
    if (activeSelection != null) {
      _drawLassoSelection(canvas, activeSelection!);
    }
  }

  void _drawLassoSelection(Canvas canvas, DrawingLassoSelection sel) {
    if (sel.polygonPoints.length < 3) return;

    final path = Path()..moveTo(sel.polygonPoints.first.dx, sel.polygonPoints.first.dy);
    for (int i = 1; i < sel.polygonPoints.length; i++) {
      path.lineTo(sel.polygonPoints[i].dx, sel.polygonPoints[i].dy);
    }
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    final boundsPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(sel.bounds.inflate(4), boundsPaint);
  }

  void _drawSymmetryGuides(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final guidePaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    void drawDashedLine(Offset p1, Offset p2) {
      const dashLength = 6.0;
      const dashSpace = 4.0;
      final distance = (p2 - p1).distance;
      final direction = (p2 - p1) / distance;
      double current = 0.0;

      while (current < distance) {
        final start = p1 + direction * current;
        final endLen = (current + dashLength < distance) ? dashLength : distance - current;
        final end = start + direction * endLen;
        canvas.drawLine(start, end, guidePaint);
        current += dashLength + dashSpace;
      }
    }

    if (symmetryMode == DrawingSymmetryMode.vertical ||
        symmetryMode == DrawingSymmetryMode.radial4 ||
        symmetryMode == DrawingSymmetryMode.kaleidoscope) {
      drawDashedLine(Offset(cx, 0), Offset(cx, size.height));
    }
    if (symmetryMode == DrawingSymmetryMode.horizontal ||
        symmetryMode == DrawingSymmetryMode.radial4 ||
        symmetryMode == DrawingSymmetryMode.kaleidoscope) {
      drawDashedLine(Offset(0, cy), Offset(size.width, cy));
    }
    if (symmetryMode == DrawingSymmetryMode.kaleidoscope) {
      drawDashedLine(Offset(0, 0), Offset(size.width, size.height));
      drawDashedLine(Offset(size.width, 0), Offset(0, size.height));
    }

    // Punto central sutil
    final centerPaint = Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx, cy), 3.0, centerPaint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDots(Canvas canvas, Size size) {
    final points = <Offset>[];
    const step = 30.0;
    for (double x = 15; x < size.width; x += step) {
      for (double y = 15; y < size.height; y += step) {
        points.add(Offset(x, y));
      }
    }
    final paint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) => true;
}
