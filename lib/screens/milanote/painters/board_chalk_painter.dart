import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/board_element.dart';
import '../models/note_style_config.dart';

/// Dibuja el fondo del Pizarrón Infinito (en el espacio de pantalla transformado por la matriz
/// de cámara del mundo) y los trazos de tiza ("chalk_stroke") que caen en el chunk activo (2x viewport).
///
/// Como se pinta en la capa de fondo (debajo de todas las notas), jamás bloquea ni
/// bugea el movimiento de las notas ni la navegación por el pizarrón.
class BoardChalkBackgroundPainter extends CustomPainter {
  final Matrix4 worldToScreenMatrix;
  final Rect activeWorldChunkRect;
  final Color boardBackgroundColor;
  final List<BoardElement> activeChalkStrokes;
  final List<Offset> currentLiveStroke;
  final String currentChalkColorHex;
  final double currentChalkWidth;

  BoardChalkBackgroundPainter({
    required this.worldToScreenMatrix,
    required this.activeWorldChunkRect,
    required this.boardBackgroundColor,
    required this.activeChalkStrokes,
    this.currentLiveStroke = const [],
    this.currentChalkColorHex = '#FFFFFF',
    this.currentChalkWidth = 7.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo sólido personalizable del pizarrón
    final bgPaint = Paint()..color = boardBackgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    canvas.save();
    canvas.transform(worldToScreenMatrix.storage);

    // 2. Puntos de referencia espaciales sutiles dentro del chunk activo (2x viewport)
    _paintInfiniteChunkDots(canvas);

    // 3. Trazos de tiza guardados dentro del chunk activo
    for (final strokeEl in activeChalkStrokes) {
      final rawPts = strokeEl.data['points'];
      if (rawPts is! List || rawPts.isEmpty) continue;
      final pts = <Offset>[];
      for (final p in rawPts) {
        if (p is List && p.length >= 2) {
          pts.add(
            Offset(
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ),
          );
        }
      }
      if (pts.isEmpty) continue;
      final sw =
          (strokeEl.data['strokeWidth'] as num?)?.toDouble() ?? 7.0;
      final color = PizarronPalette.parseHex(
        strokeEl.color,
        fallback: Colors.white,
      );
      _paintChalkStroke(canvas, pts, color, sw);
    }

    // 4. Trazo de tiza en vivo mientras el dedo/mouse está dibujando
    if (currentLiveStroke.isNotEmpty) {
      final liveColor = PizarronPalette.parseHex(
        currentChalkColorHex,
        fallback: Colors.white,
      );
      _paintChalkStroke(
        canvas,
        currentLiveStroke,
        liveColor,
        currentChalkWidth,
      );
    }

    canvas.restore();
  }

  void _paintInfiniteChunkDots(Canvas canvas) {
    final isLightBg = boardBackgroundColor.computeLuminance() > 0.5;
    final dotColor = isLightBg
        ? const Color(0x18141820)
        : const Color(0x16FFFFFF);
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const double gridStep = 64.0;
    final startX =
        (activeWorldChunkRect.left / gridStep).floorToDouble() * gridStep;
    final endX =
        (activeWorldChunkRect.right / gridStep).ceilToDouble() * gridStep;
    final startY =
        (activeWorldChunkRect.top / gridStep).floorToDouble() * gridStep;
    final endY =
        (activeWorldChunkRect.bottom / gridStep).ceilToDouble() * gridStep;

    // Limitar cantidad máxima de puntos cuando se hace mucho zoom out
    final cols = ((endX - startX) / gridStep).round();
    final rows = ((endY - startY) / gridStep).round();
    final stride = math.max(1, ((cols * rows) / 1400).ceil());
    final step = gridStep * stride;

    for (double y = startY; y <= endY; y += step) {
      for (double x = startX; x <= endX; x += step) {
        canvas.drawCircle(Offset(x, y), 1.3, dotPaint);
      }
    }
  }

  /// Renderiza un trazo con textura auténtica de tiza porosa:
  /// - Núcleo difuso seco
  /// - Hebras paralelas irregulares
  /// - Granulado determinístico de polvo de tiza a lo largo del trazo
  void _paintChalkStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.length == 1) {
      final dotPaint = Paint()
        ..color = color.withValues(alpha: 0.80)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points.first, width * 0.5, dotPaint);
      return;
    }

    final basePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      basePath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    basePath.lineTo(points.last.dx, points.last.dy);

    // Pasada 1: Núcleo poroso de la tiza
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1);
    canvas.drawPath(basePath, corePaint);

    // Pasada 2: Fibra central seca
    final dryPaint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(basePath, dryPaint);

    // Pasada 3: Granulado de tiza determinístico a lo largo de los segmentos
    final grainPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final dustPaint = Paint()
      ..color = color.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;

    final spread = width * 0.58;
    final stepDist = math.max(2.5, width * 0.38);

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final segLen = math.sqrt(dx * dx + dy * dy);
      if (segLen < 0.5) continue;

      final steps = (segLen / stepDist).ceil();
      for (int s = 0; s < steps; s++) {
        final t = s / steps;
        final px = a.dx + dx * t;
        final py = a.dy + dy * t;

        // Hash determinístico para que los granos de tiza sean estáticos en el mundo
        int seed = ((px * 173).round() * 73856093) ^
            ((py * 173).round() * 19349663) ^
            (s * 83492791);

        // 3 partículas por paso
        for (int g = 0; g < 3; g++) {
          seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
          final angle = (seed % 360) * math.pi / 180.0;
          seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
          final dist = ((seed % 100) / 100.0) * spread;
          seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
          final grainRadius =
              (0.5 + ((seed % 100) / 100.0) * (width * 0.16)).clamp(0.5, 2.6);

          final gx = px + math.cos(angle) * dist;
          final gy = py + math.sin(angle) * dist;
          canvas.drawCircle(
            Offset(gx, gy),
            grainRadius,
            g == 0 ? grainPaint : dustPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardChalkBackgroundPainter oldDelegate) {
    return oldDelegate.worldToScreenMatrix != worldToScreenMatrix ||
        oldDelegate.activeWorldChunkRect != activeWorldChunkRect ||
        oldDelegate.boardBackgroundColor != boardBackgroundColor ||
        oldDelegate.activeChalkStrokes != activeChalkStrokes ||
        oldDelegate.currentLiveStroke != currentLiveStroke ||
        oldDelegate.currentChalkColorHex != currentChalkColorHex ||
        oldDelegate.currentChalkWidth != currentChalkWidth;
  }
}
