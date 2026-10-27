import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_tool_type.dart';

/// Motor especializado de dibujo para cada herramienta:
/// Birome, Pluma G Manga, Lápiz grafito, Marcador, Aerógrafo,
/// Resaltador, Formas geométricas y Borrador.
abstract final class StrokeRenderer {
  static void renderStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    switch (stroke.tool) {
      case DrawingToolType.pen:
        _renderPen(canvas, stroke);
        break;
      case DrawingToolType.gPen:
        _renderGPen(canvas, stroke);
        break;
      case DrawingToolType.pencil:
        _renderPencil(canvas, stroke);
        break;
      case DrawingToolType.marker:
        _renderMarker(canvas, stroke);
        break;
      case DrawingToolType.airbrush:
        _renderAirbrush(canvas, stroke);
        break;
      case DrawingToolType.highlighter:
        _renderHighlighter(canvas, stroke);
        break;
      case DrawingToolType.lasso:
        _renderLassoPreview(canvas, stroke);
        break;
      case DrawingToolType.line:
      case DrawingToolType.rectangle:
      case DrawingToolType.circle:
      case DrawingToolType.trajectory:
        _renderShape(canvas, stroke);
        break;
      case DrawingToolType.bucketFill:
        _renderBucketFill(canvas, stroke);
        break;
      case DrawingToolType.gradient:
        _renderGradient(canvas, stroke);
        break;
      case DrawingToolType.screentone:
        _renderScreentone(canvas, stroke);
        break;
      case DrawingToolType.eraser:
        _renderEraser(canvas, stroke);
        break;
      case DrawingToolType.smudge:
        _renderSmudge(canvas, stroke);
        break;
    }
  }

  /// Difuminar / Dedo: Mezcla suave con desenfoque gaussiano suave.
  static void _renderSmudge(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: (stroke.opacity * 0.35).clamp(0.02, 0.6))
      ..strokeWidth = stroke.strokeWidth * 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
      ..isAntiAlias = true;

    canvas.drawPath(stroke.path, paint);
  }

  /// Birome: Tinta líquida uniforme de alta fidelidad.
  static void _renderPen(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(stroke.path, paint);
  }

  /// Pluma G Manga: Entintado clásico con modulación dinámica de presión/velocidad.
  static void _renderGPen(Canvas canvas, DrawingStroke stroke) {
    final avgPressure = stroke.points.fold<double>(0, (sum, p) => sum + p.pressure) / stroke.points.length;
    final dynamicWidth = (stroke.strokeWidth * (0.6 + avgPressure * 0.8)).clamp(1.0, 50.0);

    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..strokeWidth = dynamicWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(stroke.path, paint);
  }

  /// Lápiz: Grafito texturado con microporosidad y doble pasada.
  static void _renderPencil(Canvas canvas, DrawingStroke stroke) {
    final baseOpacity = (stroke.opacity * 0.85).clamp(0.05, 1.0);

    final basePaint = Paint()
      ..color = stroke.color.withValues(alpha: baseOpacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(stroke.path, basePaint);

    if (stroke.strokeWidth > 1.5) {
      final corePaint = Paint()
        ..color = stroke.color.withValues(alpha: (baseOpacity * 0.7).clamp(0.0, 1.0))
        ..strokeWidth = (stroke.strokeWidth * 0.55).clamp(0.8, 10.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawPath(stroke.path, corePaint);
    }
  }

  /// Marcador: Trazo firme, saturado y uniforme.
  static void _renderMarker(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(stroke.path, paint);
  }

  /// Aerógrafo: Difuminado suave concéntrico para sombreados profesionales.
  static void _renderAirbrush(Canvas canvas, DrawingStroke stroke) {
    final layers = 3;
    for (int i = 0; i < layers; i++) {
      final factor = (i + 1) / layers;
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: (stroke.opacity * 0.35 / factor).clamp(0.01, 1.0))
        ..strokeWidth = stroke.strokeWidth * factor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawPath(stroke.path, paint);
    }
  }

  /// Resaltador: Ancho translúcido con solapamiento suave.
  static void _renderHighlighter(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity.clamp(0.05, 0.45))
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.bevel
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(stroke.path, paint);
  }

  /// Formas geométricas: Líneas, Rectángulos y Círculos.
  static void _renderShape(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(stroke.path, paint);
  }

  /// Borrador: Modo corte con BlendMode.clear en la capa.
  static void _renderEraser(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(stroke.path, paint);
  }

  /// Relleno de balde: Si tiene >= 3 puntos, rellena el polígono cerrado; de lo contrario, la capa activa.
  static void _renderBucketFill(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (stroke.points.length >= 3) {
      final path = Path();
      path.moveTo(stroke.points.first.offset.dx, stroke.points.first.offset.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].offset.dx, stroke.points[i].offset.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    } else {
      canvas.drawPaint(paint);
    }
  }

  /// Degradado lineal: Proyecta un degradado desde el primer punto al último del trazo.
  static void _renderGradient(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;
    final first = stroke.points.first.offset;
    final last = stroke.points.length > 1
        ? stroke.points.last.offset
        : first + const Offset(100, 100);

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        first,
        last,
        [
          stroke.color.withValues(alpha: stroke.opacity),
          stroke.color.withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPaint(paint);
  }

  /// Lazo: Trazo libre de selección con contorno cian y sombreado translúcido.
  static void _renderLassoPreview(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.length < 2) return;
    final path = Path()..moveTo(stroke.points.first.offset.dx, stroke.points.first.offset.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].offset.dx, stroke.points[i].offset.dy);
    }
    final fillPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  /// Trama Manga (Screentone): Puntos de semitono auténticos recortados al trazo.
  static void _renderScreentone(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;
    final bounds = stroke.path.getBounds();
    if (bounds.isEmpty) return;

    canvas.save();
    canvas.clipPath(stroke.path);

    final dotPaint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..style = PaintingStyle.fill;

    const double spacing = 12.0;
    final double dotRadius = (stroke.strokeWidth * 0.12).clamp(1.5, 5.0);
    final startX = (bounds.left ~/ spacing) * spacing;
    final startY = (bounds.top ~/ spacing) * spacing;

    for (double y = startY; y <= bounds.bottom + spacing; y += spacing) {
      final isOddRow = ((y / spacing).round() % 2) != 0;
      final xOffset = isOddRow ? spacing / 2 : 0.0;
      for (double x = startX - spacing; x <= bounds.right + spacing; x += spacing) {
        canvas.drawCircle(Offset(x + xOffset, y), dotRadius, dotPaint);
      }
    }

    canvas.restore();
  }
}
