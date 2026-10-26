import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/comic_alignment_guide.dart';

/// Tipos de mangos interactivos en la caja de selección.
enum ComicHandleType {
  none,
  rotate,
  cornerTopLeft,
  cornerTopRight,
  cornerBottomLeft,
  cornerBottomRight,
  edgeTop,
  edgeBottom,
  edgeLeft,
  edgeRight,
  body;

  bool get isCorner =>
      this == ComicHandleType.cornerTopLeft ||
      this == ComicHandleType.cornerTopRight ||
      this == ComicHandleType.cornerBottomLeft ||
      this == ComicHandleType.cornerBottomRight;

  bool get isEdge =>
      this == ComicHandleType.edgeTop ||
      this == ComicHandleType.edgeBottom ||
      this == ComicHandleType.edgeLeft ||
      this == ComicHandleType.edgeRight;
}

/// Datos geométricos normalizados para manipulación directa en lienzo
class ComicElementTransform {
  final Offset center;
  final double halfW;
  final double halfH;
  final double rotation;

  const ComicElementTransform({
    required this.center,
    required this.halfW,
    required this.halfH,
    required this.rotation,
  });

  static Offset rotateVector(Offset v, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return Offset(v.dx * cosA - v.dy * sinA, v.dx * sinA + v.dy * cosA);
  }

  Offset get rotationHandlePos => center + rotateVector(Offset(0, -halfH - 36), rotation);

  Offset get bottomRightPos => center + rotateVector(Offset(halfW + 6, halfH + 6), rotation);
  Offset get bottomLeftPos => center + rotateVector(Offset(-halfW - 6, halfH + 6), rotation);
  Offset get topRightPos => center + rotateVector(Offset(halfW + 6, -halfH - 6), rotation);
  Offset get topLeftPos => center + rotateVector(Offset(-halfW - 6, -halfH - 6), rotation);

  Offset get topEdgePos => center + rotateVector(Offset(0, -halfH - 6), rotation);
  Offset get bottomEdgePos => center + rotateVector(Offset(0, halfH + 6), rotation);
  Offset get leftEdgePos => center + rotateVector(Offset(-halfW - 6, 0), rotation);
  Offset get rightEdgePos => center + rotateVector(Offset(halfW + 6, 0), rotation);

  bool containsPoint(Offset point) {
    final diff = point - center;
    final unrotated = rotateVector(diff, -rotation);
    return unrotated.dx.abs() <= halfW + 12 && unrotated.dy.abs() <= halfH + 12;
  }

  /// Identifica con precisión qué mango o área fue tocada por el usuario
  ComicHandleType hitTest(Offset point, {double handleRadius = 24.0}) {
    if ((point - rotationHandlePos).distance <= 18.0) {
      return ComicHandleType.rotate;
    }

    if ((point - topLeftPos).distance <= handleRadius) return ComicHandleType.cornerTopLeft;
    if ((point - topRightPos).distance <= handleRadius) return ComicHandleType.cornerTopRight;
    if ((point - bottomLeftPos).distance <= handleRadius) return ComicHandleType.cornerBottomLeft;
    if ((point - bottomRightPos).distance <= handleRadius) return ComicHandleType.cornerBottomRight;

    if ((point - topEdgePos).distance <= handleRadius) return ComicHandleType.edgeTop;
    if ((point - bottomEdgePos).distance <= handleRadius) return ComicHandleType.edgeBottom;
    if ((point - leftEdgePos).distance <= handleRadius) return ComicHandleType.edgeLeft;
    if ((point - rightEdgePos).distance <= handleRadius) return ComicHandleType.edgeRight;

    if (containsPoint(point)) return ComicHandleType.body;

    return ComicHandleType.none;
  }
}

/// Painter que dibuja la caja de selección con 8 mangos (4 esquinas, 4 bordes)
/// y el mango superior de rotación (lollipop), además de guías inteligentes de alineación (Canva).
class ComicSelectionBoxPainter extends CustomPainter {
  final ComicElementTransform transform;
  final List<ComicAlignmentGuide> guides;
  final Color accentColor;

  const ComicSelectionBoxPainter({
    required this.transform,
    this.guides = const [],
    this.accentColor = const Color(0xFF00D4FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dibujar guías magnéticas inteligentes estilo Canva/Figma en coordenadas de página
    if (guides.isNotEmpty) {
      _paintSmartGuides(canvas, size);
    }

    // 2. Dibujar caja de selección y mangos en coordenadas locales rotadas
    canvas.save();
    canvas.translate(transform.center.dx, transform.center.dy);
    canvas.rotate(transform.rotation);

    final boxRect = Rect.fromCenter(
      center: Offset.zero,
      width: transform.halfW * 2 + 12,
      height: transform.halfH * 2 + 12,
    );

    // Caja delimitadora con borde sólido nítido
    final boxPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(6)), boxPaint);

    // Tallo vertical hacia el mango de rotación
    final stemPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, -transform.halfH - 6), Offset(0, -transform.halfH - 36), stemPaint);

    // Mango de rotación (Lollipop handle)
    final rotCenter = Offset(0, -transform.halfH - 36);
    final handlePaint = Paint()..color = accentColor;
    canvas.drawCircle(rotCenter, 10, handlePaint);
    canvas.drawCircle(rotCenter, 5, Paint()..color = Colors.white);

    // 4 Mangos de escala en las esquinas
    final cornerOffsets = [
      Offset(transform.halfW + 6, transform.halfH + 6),
      Offset(-transform.halfW - 6, transform.halfH + 6),
      Offset(transform.halfW + 6, -transform.halfH - 6),
      Offset(-transform.halfW - 6, -transform.halfH - 6),
    ];

    for (final offset in cornerOffsets) {
      canvas.drawCircle(offset, 7, Paint()..color = Colors.white);
      canvas.drawCircle(offset, 5, Paint()..color = accentColor);
    }

    // 4 Mangos de borde independiente (midpoints)
    final edgeOffsets = [
      Offset(0, -transform.halfH - 6), // top
      Offset(0, transform.halfH + 6),  // bottom
      Offset(-transform.halfW - 6, 0), // left
      Offset(transform.halfW + 6, 0),  // right
    ];

    for (final offset in edgeOffsets) {
      final rect = Rect.fromCenter(center: offset, width: 12, height: 12);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = Colors.white);
      final inner = Rect.fromCenter(center: offset, width: 8, height: 8);
      canvas.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(2)), Paint()..color = accentColor);
    }

    canvas.restore();
  }

  void _paintSmartGuides(Canvas canvas, Size size) {
    for (final guide in guides) {
      final color = guide.isPageCenter
          ? const Color(0xFF00D4FF) // Cian eléctrico para centro de hoja
          : guide.type == ComicGuideType.pageMargin
              ? const Color(0xFFFFDE59) // Amarillo cálido para margen
              : const Color(0xFFFF2A85); // Magenta neón Canva para otros elementos

      final shadowPaint = Paint()
        ..color = const Color(0x66141414)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke;

      final guidePaint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      if (guide.isVertical) {
        final p1 = Offset(guide.position, 0);
        final p2 = Offset(guide.position, size.height);
        canvas.drawLine(p1, p2, shadowPaint);
        _drawDashedLine(canvas, p1, p2, guidePaint);

        if (guide.label != null) {
          _drawGuidePill(canvas, Offset(guide.position, 16), guide.label!, color);
        }
      } else {
        final p1 = Offset(0, guide.position);
        final p2 = Offset(size.width, guide.position);
        canvas.drawLine(p1, p2, shadowPaint);
        _drawDashedLine(canvas, p1, p2, guidePaint);

        if (guide.label != null) {
          _drawGuidePill(canvas, Offset(24, guide.position), guide.label!, color);
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLength = 7.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final count = (dist / (dashLength + dashSpace)).floor();
    for (int i = 0; i < count; i++) {
      final t1 = i / count;
      final t2 = (i + 0.62) / count;
      canvas.drawLine(
        Offset(p1.dx + dx * t1, p1.dy + dy * t1),
        Offset(p1.dx + dx * t2, p1.dy + dy * t2),
        paint,
      );
    }
  }

  void _drawGuidePill(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = Rect.fromCenter(
      center: pos,
      width: tp.width + 12,
      height: tp.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF1E1E1E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
      Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2,
    );
    tp.paint(canvas, Offset(pillRect.left + 6, pillRect.top + 3));
  }

  @override
  bool shouldRepaint(covariant ComicSelectionBoxPainter oldDelegate) {
    return oldDelegate.transform.center != transform.center ||
        oldDelegate.transform.halfW != transform.halfW ||
        oldDelegate.transform.halfH != transform.halfH ||
        oldDelegate.transform.rotation != transform.rotation ||
        oldDelegate.guides != guides;
  }
}
