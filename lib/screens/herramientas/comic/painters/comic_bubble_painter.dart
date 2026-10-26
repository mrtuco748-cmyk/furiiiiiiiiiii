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
    canvas.drawPath(path, fillPaint);

    if (bubble.type == ComicBubbleType.whisperDotted) {
      for (final metric in path.computeMetrics()) {
        double dist = 0.0;
        while (dist < metric.length) {
          canvas.drawPath(metric.extractPath(dist, dist + 6.0), borderPaint);
          dist += 10.0;
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
        body = _buildThoughtCloudPath(w, h);
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
        final cx = (w * 0.5 + txOffset * 0.25).clamp(w * 0.25, w * 0.75);
        final baseW = (w * 0.16).clamp(18.0, 30.0);
        final tipX = (cx + txOffset * 0.35).clamp(w * 0.10, w * 0.90);
        tail.moveTo(cx - baseW / 2, h - 4.0);
        tail.quadraticBezierTo(cx - baseW / 4, h + 8.0, tipX, h + 28.0);
        tail.quadraticBezierTo(cx + baseW / 4, h + 8.0, cx + baseW / 2, h - 4.0);
        tail.close();
        break;

      case ComicTailDirection.top:
        final cx = (w * 0.5 + txOffset * 0.25).clamp(w * 0.25, w * 0.75);
        final baseW = (w * 0.16).clamp(18.0, 30.0);
        final tipX = (cx + txOffset * 0.35).clamp(w * 0.10, w * 0.90);
        tail.moveTo(cx - baseW / 2, 4.0);
        tail.quadraticBezierTo(cx - baseW / 4, -8.0, tipX, -28.0);
        tail.quadraticBezierTo(cx + baseW / 4, -8.0, cx + baseW / 2, 4.0);
        tail.close();
        break;

      case ComicTailDirection.left:
        final cy = (h * 0.5 + tyOffset * 0.15).clamp(h * 0.25, h * 0.75);
        final baseH = (h * 0.20).clamp(16.0, 26.0);
        final tipY = (cy + tyOffset * 0.25).clamp(h * 0.12, h * 0.88);
        tail.moveTo(4.0, cy - baseH / 2);
        tail.quadraticBezierTo(-8.0, cy - baseH / 4, -28.0, tipY);
        tail.quadraticBezierTo(-8.0, cy + baseH / 4, 4.0, cy + baseH / 2);
        tail.close();
        break;

      case ComicTailDirection.right:
        final cy = (h * 0.5 + tyOffset * 0.15).clamp(h * 0.25, h * 0.75);
        final baseH = (h * 0.20).clamp(16.0, 26.0);
        final tipY = (cy + tyOffset * 0.25).clamp(h * 0.12, h * 0.88);
        tail.moveTo(w - 4.0, cy - baseH / 2);
        tail.quadraticBezierTo(w + 8.0, cy - baseH / 4, w + 28.0, tipY);
        tail.quadraticBezierTo(w + 8.0, cy + baseH / 4, w - 4.0, cy + baseH / 2);
        tail.close();
        break;

      case ComicTailDirection.none:
        break;
    }
    return tail;
  }

  static Path _buildThoughtCloudPath(double w, double h) {
    final p = Path();
    final nx = (w / 36).clamp(3, 8).round();
    final ny = (h / 30).clamp(2, 6).round();
    final sx = w / nx;
    final sy = h / ny;
    p.moveTo(0, h * 0.5);
    for (int i = ny - 1; i >= 0; i--) {
      p.quadraticBezierTo(-7, (i + 0.5) * sy, 0, i * sy);
    }
    for (int i = 0; i < nx; i++) {
      p.quadraticBezierTo((i + 0.5) * sx, -9, (i + 1) * sx, 0);
    }
    for (int i = 0; i < ny; i++) {
      p.quadraticBezierTo(w + 7, (i + 0.5) * sy, w, (i + 1) * sy);
    }
    for (int i = nx - 1; i >= 0; i--) {
      p.quadraticBezierTo((i + 0.5) * sx, h + 9, i * sx, h);
    }
    p.close();
    return p;
  }

  static Path _buildSpikyPath(double w, double h, int basePoints, double outerFactor, double innerFactor) {
    final p = Path();
    final cx = w / 2;
    final cy = h / 2;
    final rx = w / 2;
    final ry = h / 2;
    final numPoints = math.max(basePoints, ((w + h) / 18).round() * 2);

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
    final nx = (w / 22).clamp(3, 10).round();
    final ny = (h / 22).clamp(2, 8).round();
    final sx = w / nx;
    final sy = h / ny;
    p.moveTo(0, 0);
    for (int i = 0; i < nx; i++) {
      p.lineTo((i + 0.5) * sx, i.isEven ? -7 : 4);
      p.lineTo((i + 1) * sx, 0);
    }
    for (int i = 0; i < ny; i++) {
      p.lineTo(w + (i.isEven ? 7 : -4), (i + 0.5) * sy);
      p.lineTo(w, (i + 1) * sy);
    }
    for (int i = nx - 1; i >= 0; i--) {
      p.lineTo((i + 0.5) * sx, h + (i.isEven ? 7 : -4));
      p.lineTo(i * sx, h);
    }
    for (int i = ny - 1; i >= 0; i--) {
      p.lineTo(i.isEven ? -7 : 4, (i + 0.5) * sy);
      p.lineTo(0, i * sy);
    }
    p.close();
    return p;
  }

  static Path _buildWavyPath(double w, double h) {
    final p = Path();
    final nx = (w / 18).clamp(4, 14).round();
    final ny = (h / 18).clamp(3, 10).round();
    final sx = w / nx;
    final sy = h / ny;
    p.moveTo(0, 0);
    for (int i = 0; i < nx; i++) {
      p.quadraticBezierTo((i + 0.5) * sx, i.isEven ? -4 : 4, (i + 1) * sx, 0);
    }
    for (int i = 0; i < ny; i++) {
      p.quadraticBezierTo(w + (i.isEven ? 4 : -4), (i + 0.5) * sy, w, (i + 1) * sy);
    }
    for (int i = nx - 1; i >= 0; i--) {
      p.quadraticBezierTo((i + 0.5) * sx, h + (i.isEven ? 4 : -4), i * sx, h);
    }
    for (int i = ny - 1; i >= 0; i--) {
      p.quadraticBezierTo(i.isEven ? -4 : 4, (i + 0.5) * sy, 0, i * sy);
    }
    p.close();
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
