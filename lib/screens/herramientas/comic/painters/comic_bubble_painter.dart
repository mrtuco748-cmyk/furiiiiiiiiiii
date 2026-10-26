import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/comic_bubble.dart';

/// Painter vectorial de alta precisión para los 12 estilos de globos de diálogo cómic y manga
/// con soporte de orientación multidireccional de cola (abajo, arriba, izquierda, derecha, sin cola).
abstract final class ComicBubblePainter {
  static void paintBubble(Canvas canvas, Size size, ComicBubble bubble) {
    final fillPaint = Paint()
      ..color = bubble.backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = bubble.borderColor
      ..strokeWidth = bubble.borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = getBubblePath(size, bubble);

    // Relleno
    canvas.drawPath(path, fillPaint);

    // Borde
    if (bubble.type == ComicBubbleType.whisperDotted) {
      // Línea punteada para susurro
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        double distance = 0.0;
        const dashLength = 6.0;
        const dashSpace = 4.0;
        while (distance < metric.length) {
          final extractPath = metric.extractPath(distance, distance + dashLength);
          canvas.drawPath(extractPath, borderPaint);
          distance += dashLength + dashSpace;
        }
      }
    } else {
      canvas.drawPath(path, borderPaint);
    }

    // Si es pensamiento, dibujar bolitas de pensamiento hacia la cola
    if (bubble.type == ComicBubbleType.thoughtCloud && bubble.tailDirection != ComicTailDirection.none) {
      _drawThoughtDots(canvas, size, bubble, fillPaint, borderPaint);
    }
  }

  static Path getBubblePath(Size size, ComicBubble bubble) {
    final w = size.width;
    final h = size.height;

    Path body;
    switch (bubble.type) {
      case ComicBubbleType.mangaOval:
      case ComicBubbleType.whisperDotted:
        body = Path()..addOval(Rect.fromLTWH(0, 0, w, h));
        break;
      case ComicBubbleType.screamSpiky:
        body = _buildSpikyPath(w, h, 16, 1.10, 0.82);
        break;
      case ComicBubbleType.thoughtCloud:
        body = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(h / 2)));
        break;
      case ComicBubbleType.narratorBox:
        body = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
        break;
      case ComicBubbleType.furiChat:
        body = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(16)));
        break;
      case ComicBubbleType.electricShonen:
        body = _buildElectricPath(w, h);
        break;
      case ComicBubbleType.dizzyWavy:
        body = _buildWavyPath(w, h);
        break;
      case ComicBubbleType.shoujoHeart:
        body = _buildHeartPath(w, h);
        break;
      case ComicBubbleType.impactExplosion:
        body = _buildSpikyPath(w, h, 24, 1.22, 0.76);
        break;
      case ComicBubbleType.cyberHexagon:
        body = _buildHexagonPath(w, h);
        break;
      case ComicBubbleType.wideWebtoon:
        body = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(22)));
        break;
    }

    if (bubble.tailDirection == ComicTailDirection.none ||
        bubble.type == ComicBubbleType.thoughtCloud ||
        bubble.type == ComicBubbleType.narratorBox) {
      return body;
    }

    final tail = _buildTailPath(w, h, bubble.tailDirection, bubble.tailX, bubble.tailY);
    return Path.combine(PathOperation.union, body, tail);
  }

  static Path _buildTailPath(double w, double h, ComicTailDirection dir, double txOffset, double tyOffset) {
    final tail = Path();
    switch (dir) {
      case ComicTailDirection.bottom:
        final baseCx = (w * 0.5 + txOffset * 0.25).clamp(w * 0.25, w * 0.75);
        final baseW = (w * 0.18).clamp(18.0, 34.0);
        final rootY = h - (h * 0.22).clamp(10.0, 24.0);
        final r1 = Offset(baseCx - baseW * 0.5, rootY);
        final r2 = Offset(baseCx + baseW * 0.5, rootY);
        const tipLen = 28.0;
        final tipY = h + tipLen;
        final tipX = (baseCx + txOffset * 0.35).clamp(w * 0.10, w * 0.90);
        final cp1 = Offset(r1.dx + (tipX - r1.dx) * 0.35, h + 4.0);
        final cp2 = Offset(r2.dx + (tipX - r2.dx) * 0.35, h + 4.0);

        tail.moveTo(r1.dx, r1.dy);
        tail.quadraticBezierTo(cp1.dx, cp1.dy, tipX, tipY);
        tail.quadraticBezierTo(cp2.dx, cp2.dy, r2.dx, r2.dy);
        tail.close();
        break;

      case ComicTailDirection.top:
        final baseCx = (w * 0.5 + txOffset * 0.25).clamp(w * 0.25, w * 0.75);
        final baseW = (w * 0.18).clamp(18.0, 34.0);
        final rootY = (h * 0.22).clamp(10.0, 24.0);
        final r1 = Offset(baseCx - baseW * 0.5, rootY);
        final r2 = Offset(baseCx + baseW * 0.5, rootY);
        const tipLen = 28.0;
        final tipY = -tipLen;
        final tipX = (baseCx + txOffset * 0.35).clamp(w * 0.10, w * 0.90);
        final cp1 = Offset(r1.dx + (tipX - r1.dx) * 0.35, -4.0);
        final cp2 = Offset(r2.dx + (tipX - r2.dx) * 0.35, -4.0);

        tail.moveTo(r1.dx, r1.dy);
        tail.quadraticBezierTo(cp1.dx, cp1.dy, tipX, tipY);
        tail.quadraticBezierTo(cp2.dx, cp2.dy, r2.dx, r2.dy);
        tail.close();
        break;

      case ComicTailDirection.left:
        final baseCy = (h * 0.5 + tyOffset * 0.15).clamp(h * 0.25, h * 0.75);
        final baseH = (h * 0.22).clamp(16.0, 30.0);
        final rootX = (w * 0.22).clamp(12.0, 26.0);
        final r1 = Offset(rootX, baseCy - baseH * 0.5);
        final r2 = Offset(rootX, baseCy + baseH * 0.5);
        const tipLen = 28.0;
        final tipX = -tipLen;
        final tipY = (baseCy + tyOffset * 0.25).clamp(h * 0.12, h * 0.88);
        final cp1 = Offset(-4.0, r1.dy + (tipY - r1.dy) * 0.35);
        final cp2 = Offset(-4.0, r2.dy + (tipY - r2.dy) * 0.35);

        tail.moveTo(r1.dx, r1.dy);
        tail.quadraticBezierTo(cp1.dx, cp1.dy, tipX, tipY);
        tail.quadraticBezierTo(cp2.dx, cp2.dy, r2.dx, r2.dy);
        tail.close();
        break;

      case ComicTailDirection.right:
        final baseCy = (h * 0.5 + tyOffset * 0.15).clamp(h * 0.25, h * 0.75);
        final baseH = (h * 0.22).clamp(16.0, 30.0);
        final rootX = w - (w * 0.22).clamp(12.0, 26.0);
        final r1 = Offset(rootX, baseCy - baseH * 0.5);
        final r2 = Offset(rootX, baseCy + baseH * 0.5);
        const tipLen = 28.0;
        final tipX = w + tipLen;
        final tipY = (baseCy + tyOffset * 0.25).clamp(h * 0.12, h * 0.88);
        final cp1 = Offset(w + 4.0, r1.dy + (tipY - r1.dy) * 0.35);
        final cp2 = Offset(w + 4.0, r2.dy + (tipY - r2.dy) * 0.35);

        tail.moveTo(r1.dx, r1.dy);
        tail.quadraticBezierTo(cp1.dx, cp1.dy, tipX, tipY);
        tail.quadraticBezierTo(cp2.dx, cp2.dy, r2.dx, r2.dy);
        tail.close();
        break;

      case ComicTailDirection.none:
        break;
    }
    return tail;
  }

  static Path _buildSpikyPath(double w, double h, int numPoints, double outerFactor, double innerFactor) {
    final p = Path();
    final cx = w / 2;
    final cy = h / 2;
    final rx = w / 2;
    final ry = h / 2;

    for (int i = 0; i < numPoints; i++) {
      final angle = (i * 2 * math.pi) / numPoints;
      final isOuter = i.isEven;
      final radX = isOuter ? rx * outerFactor : rx * innerFactor;
      final radY = isOuter ? ry * outerFactor : ry * innerFactor;
      final px = cx + radX * math.cos(angle);
      final py = cy + radY * math.sin(angle);
      if (i == 0) {
        p.moveTo(px, py);
      } else {
        p.lineTo(px, py);
      }
    }
    p.close();
    return p;
  }

  static Path _buildElectricPath(double w, double h) {
    final p = Path();
    p.moveTo(12, 0);
    p.lineTo(w - 20, 6);
    p.lineTo(w, 18);
    p.lineTo(w - 6, h * 0.45);
    p.lineTo(w + 8, h * 0.65);
    p.lineTo(w - 12, h);
    p.lineTo(w * 0.6, h - 4);
    p.lineTo(w * 0.4, h + 6);
    p.lineTo(20, h - 2);
    p.lineTo(0, h * 0.75);
    p.lineTo(8, h * 0.35);
    p.lineTo(0, 16);
    p.close();
    return p;
  }

  static Path _buildWavyPath(double w, double h) {
    final p = Path();
    final rect = Rect.fromLTWH(4, 4, w - 8, h - 8);
    p.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(h / 3)));
    return p;
  }

  static Path _buildHeartPath(double w, double h) {
    final p = Path();
    p.moveTo(w / 2, h * 0.85);
    p.cubicTo(w * 0.15, h * 0.60, 0, h * 0.30, w * 0.25, h * 0.05);
    p.cubicTo(w * 0.42, 0, w / 2, h * 0.20, w / 2, h * 0.20);
    p.cubicTo(w / 2, h * 0.20, w * 0.58, 0, w * 0.75, h * 0.05);
    p.cubicTo(w, h * 0.30, w * 0.85, h * 0.60, w / 2, h * 0.85);
    p.close();
    return p;
  }

  static Path _buildHexagonPath(double w, double h) {
    final p = Path();
    final cut = math.min(w, h) * 0.22;
    p.moveTo(cut, 0);
    p.lineTo(w - cut, 0);
    p.lineTo(w, h / 2);
    p.lineTo(w - cut, h);
    p.lineTo(cut, h);
    p.lineTo(0, h / 2);
    p.close();
    return p;
  }

  static void _drawThoughtDots(Canvas canvas, Size size, ComicBubble bubble, Paint fill, Paint stroke) {
    final w = size.width;
    final h = size.height;
    Offset start;
    Offset target;

    switch (bubble.tailDirection) {
      case ComicTailDirection.top:
        start = Offset(w * 0.5, 0);
        target = Offset((w * 0.5 + bubble.tailX * 0.35).clamp(w * 0.15, w * 0.85), -32.0);
        break;
      case ComicTailDirection.left:
        start = Offset(0, h * 0.5);
        target = Offset(-32.0, (h * 0.5 + bubble.tailY * 0.2).clamp(h * 0.15, h * 0.85));
        break;
      case ComicTailDirection.right:
        start = Offset(w, h * 0.5);
        target = Offset(w + 32.0, (h * 0.5 + bubble.tailY * 0.2).clamp(h * 0.15, h * 0.85));
        break;
      case ComicTailDirection.bottom:
      case ComicTailDirection.none:
        start = Offset(w * 0.5, h);
        target = Offset((w * 0.5 + bubble.tailX * 0.35).clamp(w * 0.15, w * 0.85), h + 32.0);
        break;
    }

    for (int i = 1; i <= 3; i++) {
      final t = i / 3.0;
      final dotPos = Offset.lerp(start, target, t)!;
      final radius = 8.5 - (i * 2.0);

      canvas.drawCircle(dotPos, radius, fill);
      canvas.drawCircle(dotPos, radius, stroke);
    }
  }
}
