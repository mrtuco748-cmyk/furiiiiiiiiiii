import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/note_style_config.dart';
import 'note_shape_utils.dart';

/// Dibujador de bordes adaptativos a cualquier forma para las notas del Pizarrón.
class NoteBorderPainter {
  static void paintBorder(Canvas canvas, Size size, NoteStyleConfig config) {
    final borderColor = PizarronPalette.parseHex(config.borderColor);
    final bw = config.borderWidth.clamp(1.0, 14.0);
    final spacing = config.borderSpacing.clamp(2.0, 30.0);

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
        const step = 3.5;
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
}
