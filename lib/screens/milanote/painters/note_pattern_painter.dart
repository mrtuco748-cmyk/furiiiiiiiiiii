import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/note_style_config.dart';

/// Dibujador de patrones decorativos para las notas del Pizarrón (ajedrez, líneas, ondas, círculos, etc.).
class NotePatternPainter {
  static Paint createPatternPaint(
    NoteStyleConfig config,
    Rect rect, {
    required bool isStroke,
  }) {
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

  static void paintPattern(
    Canvas canvas,
    Size size,
    Rect rect,
    NoteStyleConfig config,
  ) {
    final w = size.width;
    final h = size.height;

    switch (config.patternType) {
      case NotePatternType.none:
        break;

      case NotePatternType.chess:
        final paint = createPatternPaint(config, rect, isStroke: false);
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
        final paint = createPatternPaint(config, rect, isStroke: true);
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
        final paint = createPatternPaint(config, rect, isStroke: true);
        final step = math.max(
          6.0,
          config.patternSpacing + config.patternStrokeWidth,
        );
        for (double y = step / 2; y <= h; y += step) {
          canvas.drawLine(Offset(0, y), Offset(w, y), paint);
        }
        break;

      case NotePatternType.linesVertical:
        final paint = createPatternPaint(config, rect, isStroke: true);
        final step = math.max(
          6.0,
          config.patternSpacing + config.patternStrokeWidth,
        );
        for (double x = step / 2; x <= w; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
        }
        break;

      case NotePatternType.waves:
        final paint = createPatternPaint(config, rect, isStroke: true);
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
        final paint = createPatternPaint(config, rect, isStroke: false);
        final radius = config.patternScale.clamp(3.0, 48.0) * 0.5;
        final step = radius * 2 + config.patternSpacing.clamp(4.0, 80.0);
        for (double y = step / 2; y <= h + radius; y += step) {
          for (double x = step / 2; x <= w + radius; x += step) {
            canvas.drawCircle(Offset(x, y), radius, paint);
          }
        }
        break;

      case NotePatternType.circlesEmpty:
        final paint = createPatternPaint(config, rect, isStroke: true);
        final radius = config.patternScale.clamp(4.0, 48.0) * 0.5;
        final step = radius * 2 + config.patternSpacing.clamp(4.0, 80.0);
        for (double y = step / 2; y <= h + radius; y += step) {
          for (double x = step / 2; x <= w + radius; x += step) {
            canvas.drawCircle(Offset(x, y), radius, paint);
          }
        }
        break;

      case NotePatternType.dots:
        final paint = createPatternPaint(config, rect, isStroke: false);
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
        final paint = createPatternPaint(config, rect, isStroke: true);
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
}
