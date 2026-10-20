import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/note_style_config.dart';
import 'note_shape_utils.dart';

/// CustomPainter multicapa que dibuja la tarjeta del Pizarrón:
/// 1. Capa Base: Color sólido o Degradado de 3 partes (inicial, medio, final)
/// 2. Capa de Patrones: Ajedrez, Líneas oblicuas/horizontales/verticales, Ondas,
///    Círculos rellenos/vacíos, Puntos, Cuadrícula, o Emojis/Texto en patrón
/// 3. Capa de Brillo animado (opcional)
/// 4. Capa de Borde adaptativo que sigue el `Path` exacto de cualquiera de las 11 formas
///    (Sólido, Punteado, Rayas, Doble línea, Ondulado)
class NoteCardPainter extends CustomPainter {
  final NoteStyleConfig config;
  final double shineProgress;
  final bool isEditing;

  NoteCardPainter({
    required this.config,
    this.shineProgress = 0.0,
    this.isEditing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final shapePath = NoteShapeUtils.buildShapePath(config.shapeType, size);

    // 1. Recortar todo el interior a la forma exacta de la tarjeta
    canvas.save();
    canvas.clipPath(shapePath);

    // --- CAPA 1: FONDO BASE ---
    _paintBaseLayer(canvas, rect);

    // --- CAPA 2: PATRÓN ---
    if (config.patternType != NotePatternType.none &&
        config.patternOpacity > 0.01) {
      _paintPatternLayer(canvas, size, rect);
    }

    // --- PLIEGUE DE ESQUINA (para forma 'note') ---
    final foldPath =
        NoteShapeUtils.buildNoteFoldOverlayPath(config.shapeType, size);
    if (foldPath != null) {
      final foldPaint = Paint()
        ..color = const Color(0x38FFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawPath(foldPath, foldPaint);
    }

    // --- CAPA 3: EFECTO BRILLO ANIMADO OPCIONAL ---
    if (config.hasShine) {
      _paintShineLayer(canvas, size);
    }

    canvas.restore();

    // --- CAPA 4: BORDES ADAPTADOS A LA FORMA ---
    if (config.borderType != NoteBorderType.none && config.borderWidth > 0) {
      _paintBorderLayer(canvas, size, shapePath);
    }
  }

  void _paintBaseLayer(Canvas canvas, Rect rect) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (config.baseMode == 'gradient') {
      final c1 = PizarronPalette.parseHex(config.gradientStartColor);
      final c2 = PizarronPalette.parseHex(config.gradientMidColor);
      final c3 = PizarronPalette.parseHex(config.gradientEndColor);
      final rad = config.gradientAngle * math.pi / 180.0;
      final begin = Alignment(-math.cos(rad), -math.sin(rad));
      final end = Alignment(math.cos(rad), math.sin(rad));

      paint.shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [c1, c2, c3],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    } else {
      paint.color = PizarronPalette.parseHex(config.solidColor);
    }

    canvas.drawRect(rect, paint);
  }

  Paint _createPatternPaint(Rect rect, {required bool isStroke}) {
    final opacity = config.patternOpacity.clamp(0.02, 1.0);
    final c1 = PizarronPalette.parseHex(config.patternColor1)
        .withValues(alpha: opacity);
    final paint = Paint()
      ..style = isStroke ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = config.patternStrokeWidth.clamp(0.8, 18.0)
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    if (config.patternUseGradient) {
      final c2 = PizarronPalette.parseHex(config.patternColor2)
          .withValues(alpha: opacity);
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c1, c2],
      ).createShader(rect);
    } else {
      paint.color = c1;
    }
    return paint;
  }

  void _paintPatternLayer(Canvas canvas, Size size, Rect rect) {
    final w = size.width;
    final h = size.height;

    switch (config.patternType) {
      case NotePatternType.none:
        break;

      case NotePatternType.chess:
        // Ajedrez: bloques contiguos sin espaciado
        final paint = _createPatternPaint(rect, isStroke: false);
        final cell = config.patternScale.clamp(10.0, 80.0);
        final cols = (w / cell).ceil() + 1;
        final rows = (h / cell).ceil() + 1;
        final path = Path();
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            if ((r + c).isEven) {
              path.addRect(Rect.fromLTWH(c * cell, r * cell, cell, cell));
            }
          }
        }
        canvas.drawPath(path, paint);
        break;

      case NotePatternType.linesOblique:
        final paint = _createPatternPaint(rect, isStroke: true);
        final step = math.max(
          6.0,
          config.patternSpacing + config.patternStrokeWidth,
        );
        final maxDim = w + h;
        for (double d = -h; d <= maxDim; d += step) {
          canvas.drawLine(
            Offset(d, 0),
            Offset(d - h, h),
            paint,
          );
        }
        break;

      case NotePatternType.linesHorizontal:
        final paint = _createPatternPaint(rect, isStroke: true);
        final step = math.max(
          6.0,
          config.patternSpacing + config.patternStrokeWidth,
        );
        for (double y = step / 2; y <= h; y += step) {
          canvas.drawLine(Offset(0, y), Offset(w, y), paint);
        }
        break;

      case NotePatternType.linesVertical:
        final paint = _createPatternPaint(rect, isStroke: true);
        final step = math.max(
          6.0,
          config.patternSpacing + config.patternStrokeWidth,
        );
        for (double x = step / 2; x <= w; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
        }
        break;

      case NotePatternType.waves:
        final paint = _createPatternPaint(rect, isStroke: true);
        final rowStep = math.max(
          10.0,
          config.patternSpacing + config.patternStrokeWidth,
        );
        final waveLen = math.max(16.0, config.patternScale * 1.9);
        final amp = math.max(3.0, config.patternScale * 0.34);

        for (double baseY = rowStep / 2; baseY <= h + amp; baseY += rowStep) {
          final path = Path()..moveTo(0, baseY);
          for (double x = 0; x <= w + waveLen; x += waveLen) {
            path.quadraticBezierTo(
              x + waveLen * 0.25,
              baseY - amp,
              x + waveLen * 0.5,
              baseY,
            );
            path.quadraticBezierTo(
              x + waveLen * 0.75,
              baseY + amp,
              x + waveLen,
              baseY,
            );
          }
          canvas.drawPath(path, paint);
        }
        break;

      case NotePatternType.circlesFilled:
        final paint = _createPatternPaint(rect, isStroke: false);
        final radius = config.patternScale.clamp(3.0, 48.0) * 0.5;
        final step = radius * 2 + config.patternSpacing.clamp(4.0, 80.0);
        for (double y = step / 2; y <= h + radius; y += step) {
          for (double x = step / 2; x <= w + radius; x += step) {
            canvas.drawCircle(Offset(x, y), radius, paint);
          }
        }
        break;

      case NotePatternType.circlesEmpty:
        final paint = _createPatternPaint(rect, isStroke: true);
        final radius = config.patternScale.clamp(4.0, 48.0) * 0.5;
        final step = radius * 2 + config.patternSpacing.clamp(4.0, 80.0);
        for (double y = step / 2; y <= h + radius; y += step) {
          for (double x = step / 2; x <= w + radius; x += step) {
            canvas.drawCircle(Offset(x, y), radius, paint);
          }
        }
        break;

      case NotePatternType.dots:
        final paint = _createPatternPaint(rect, isStroke: false);
        final radius = config.patternScale.clamp(2.0, 24.0) * 0.32;
        final step = radius * 2 + config.patternSpacing.clamp(6.0, 70.0);
        int row = 0;
        for (double y = step / 2; y <= h + radius; y += step) {
          final offsetX = row.isOdd ? step / 2 : 0.0;
          for (double x = step / 2 - offsetX; x <= w + radius; x += step) {
            canvas.drawCircle(Offset(x, y), radius, paint);
          }
          row++;
        }
        break;

      case NotePatternType.grid:
        final paint = _createPatternPaint(rect, isStroke: true);
        final step = math.max(
          10.0,
          config.patternSpacing + config.patternStrokeWidth,
        );
        for (double x = step; x < w; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
        }
        for (double y = step; y < h; y += step) {
          canvas.drawLine(Offset(0, y), Offset(w, y), paint);
        }
        break;

      case NotePatternType.emoji:
        final text = config.patternEmojiText.trim().isEmpty
            ? '✨'
            : config.patternEmojiText.trim();
        final fontSize = config.patternScale.clamp(10.0, 46.0);
        final spacing = config.patternSpacing.clamp(8.0, 80.0);
        final step = fontSize + spacing;
        final opacity = config.patternOpacity.clamp(0.05, 1.0);
        final color = PizarronPalette.parseHex(config.patternColor1)
            .withValues(alpha: opacity);

        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        int row = 0;
        for (double y = 6; y < h; y += step) {
          final shift = row.isOdd ? step * 0.5 : 0.0;
          for (double x = 6 - shift; x < w; x += step) {
            tp.paint(canvas, Offset(x, y));
          }
          row++;
        }
        break;
    }
  }

  void _paintShineLayer(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pos = (shineProgress * 2.2) - 0.6;
    final rect = Offset.zero & size;

    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(pos - 0.45, -1.0),
        end: Alignment(pos + 0.45, 1.0),
        colors: [
          const Color(0x00FFFFFF),
          const Color(0x2EFFFFFF),
          const Color(0x00FFFFFF),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), shinePaint);
  }

  void _paintBorderLayer(Canvas canvas, Size size, Path outerPath) {
    final borderColor = PizarronPalette.parseHex(config.borderColor);
    final bw = config.borderWidth.clamp(1.0, 14.0);
    final spacing = config.borderSpacing.clamp(2.0, 30.0);

    // Inset para que el borde quede completamente dentro del perímetro de la forma
    final path = NoteShapeUtils.buildShapePath(
      config.shapeType,
      size,
      inset: bw * 0.5,
    );

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = bw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (config.borderType) {
      case NoteBorderType.none:
        break;

      case NoteBorderType.solid:
        canvas.drawPath(path, paint);
        break;

      case NoteBorderType.dotted:
        final dotPaint = Paint()
          ..color = borderColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        final step = bw * 1.4 + spacing;
        for (final metric in path.computeMetrics()) {
          for (double d = 0; d < metric.length; d += step) {
            final tangent = metric.getTangentForOffset(d);
            if (tangent != null) {
              canvas.drawCircle(tangent.position, bw * 0.62, dotPaint);
            }
          }
        }
        break;

      case NoteBorderType.dashed:
        final dashLen = math.max(6.0, bw * 2.6);
        final gapLen = math.max(4.0, spacing);
        final dashPath = Path();
        for (final metric in path.computeMetrics()) {
          double d = 0.0;
          while (d < metric.length) {
            final end = math.min(d + dashLen, metric.length);
            dashPath.addPath(metric.extractPath(d, end), Offset.zero);
            d += dashLen + gapLen;
          }
        }
        canvas.drawPath(dashPath, paint);
        break;

      case NoteBorderType.doubleLine:
        final outer = NoteShapeUtils.buildShapePath(
          config.shapeType,
          size,
          inset: bw * 0.6,
        );
        final innerInset = bw * 2.0 + math.max(3.0, spacing * 0.45);
        final inner = NoteShapeUtils.buildShapePath(
          config.shapeType,
          size,
          inset: innerInset,
        );
        canvas.drawPath(outer, paint);
        canvas.drawPath(inner, paint);
        break;

      case NoteBorderType.wavy:
        final wavyPath = Path();
        final step = 3.5;
        final waveLen = math.max(10.0, spacing * 1.8);
        final amp = math.max(2.0, bw * 0.75);

        for (final metric in path.computeMetrics()) {
          bool first = true;
          for (double d = 0; d <= metric.length; d += step) {
            final tangent = metric.getTangentForOffset(d);
            if (tangent == null) continue;
            final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
            final waveOffset =
                math.sin((d / waveLen) * 2 * math.pi) * amp;
            final pt = tangent.position + normal * waveOffset;
            if (first) {
              wavyPath.moveTo(pt.dx, pt.dy);
              first = false;
            } else {
              wavyPath.lineTo(pt.dx, pt.dy);
            }
          }
          wavyPath.close();
        }
        canvas.drawPath(wavyPath, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant NoteCardPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.shineProgress != shineProgress ||
        oldDelegate.isEditing != isEditing;
  }
}
