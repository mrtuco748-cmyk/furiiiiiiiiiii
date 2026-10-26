import 'package:flutter/material.dart';
import '../models/drawing_point.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_symmetry_mode.dart';
import '../models/drawing_tool_type.dart';

/// Operaciones puras para creación y proyección de trazos, rellenos y degradados.
abstract final class DrawingStrokeOperations {
  static DrawingStroke createFloodFill(Offset point, Color color, double opacity) {
    return DrawingStroke(
      id: 'stroke_${DateTime.now().microsecondsSinceEpoch}',
      tool: DrawingToolType.bucketFill,
      color: color,
      strokeWidth: 1.0,
      opacity: opacity,
      points: [DrawingPoint(offset: point, pressure: 1.0)],
    );
  }

  static DrawingStroke createGradient(Offset start, Offset end, Color color, double opacity) {
    return DrawingStroke(
      id: 'stroke_${DateTime.now().microsecondsSinceEpoch}',
      tool: DrawingToolType.gradient,
      color: color,
      strokeWidth: 1.0,
      opacity: opacity,
      points: [DrawingPoint(offset: start, pressure: 1.0), DrawingPoint(offset: end, pressure: 1.0)],
    );
  }

  static List<DrawingStroke> buildMirroredStrokes({
    required DrawingToolType tool,
    required Color color,
    required double width,
    required double opacity,
    required DrawingSymmetryMode mode,
    required Offset point,
    required double pressure,
    required Size canvasSize,
    required int timestamp,
  }) {
    if (mode == DrawingSymmetryMode.none) return const [];
    final projected = mode.projectPoints([point], canvasSize);
    return List.generate(projected.length, (i) {
      return DrawingStroke(
        id: 'stroke_${timestamp}_sym_$i',
        tool: tool,
        color: color,
        strokeWidth: width,
        opacity: opacity,
        points: [DrawingPoint(offset: projected[i].first, pressure: pressure)],
      );
    });
  }
}
