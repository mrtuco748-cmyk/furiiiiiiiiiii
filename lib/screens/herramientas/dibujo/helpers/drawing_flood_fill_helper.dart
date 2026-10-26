import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/drawing_point.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_tool_type.dart';

/// Helper para detección de regiones cerradas y relleno inteligente con balde de pintura.
abstract final class DrawingFloodFillHelper {
  /// Encuentra los puntos del polígono cerrado que encierra el punto [seed].
  static List<Offset> findEnclosedRegion({
    required Offset seed,
    required List<DrawingStroke> strokes,
    required Size canvasSize,
  }) {
    // 1. Verificar si el punto cae dentro de alguna forma cerrada preexistente
    for (final stroke in strokes.reversed) {
      if (stroke.points.length >= 3) {
        final path = stroke.path;
        if (path.contains(seed)) {
          return stroke.points.map((p) => p.offset).toList();
        }
      }
    }

    // 2. Trazado radial en 24 direcciones para detectar contornos cerrados dibujados a mano
    const int rayCount = 24;
    const double maxRadius = 900.0;
    const double step = 6.0;
    final List<Offset> boundaryHits = [];

    // Recolectar todos los puntos de trazos relevantes para búsqueda de proximidad
    final allPoints = <Offset>[];
    for (final stroke in strokes) {
      if (!stroke.tool.isEraser) {
        allPoints.addAll(stroke.points.map((p) => p.offset));
      }
    }

    if (allPoints.isEmpty) {
      return _canvasBoundary(canvasSize);
    }

    bool allRaysHit = true;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount;
      final dir = Offset(math.cos(angle), math.sin(angle));
      Offset? hit;

      for (double r = 4.0; r <= maxRadius; r += step) {
        final sample = seed + dir * r;
        if (sample.dx < 0 || sample.dx > canvasSize.width || sample.dy < 0 || sample.dy > canvasSize.height) {
          hit = Offset(
            sample.dx.clamp(0.0, canvasSize.width),
            sample.dy.clamp(0.0, canvasSize.height),
          );
          break;
        }

        // Detectar si el rayo choca con un trazo existente
        bool collided = false;
        for (final pt in allPoints) {
          if ((pt - sample).distanceSquared <= 36.0) { // dentro de 6px
            collided = true;
            hit = sample;
            break;
          }
        }
        if (collided) break;
      }

      if (hit != null) {
        boundaryHits.add(hit);
      } else {
        allRaysHit = false;
        break;
      }
    }

    if (allRaysHit && boundaryHits.length >= 8) {
      return boundaryHits;
    }

    return _canvasBoundary(canvasSize);
  }

  static List<Offset> _canvasBoundary(Size size) {
    return [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
  }

  /// Crea un trazo de relleno de balde cerrado en el punto [seed].
  static DrawingStroke createFillStroke({
    required Offset seed,
    required Color color,
    required double opacity,
    required List<DrawingStroke> existingStrokes,
    required Size canvasSize,
    List<Offset>? selectionPolygon,
  }) {
    final List<Offset> polygon = (selectionPolygon != null && selectionPolygon.length >= 3)
        ? selectionPolygon
        : findEnclosedRegion(seed: seed, strokes: existingStrokes, canvasSize: canvasSize);

    return DrawingStroke(
      id: 'fill_${DateTime.now().microsecondsSinceEpoch}',
      tool: DrawingToolType.bucketFill,
      color: color,
      strokeWidth: 1.0,
      opacity: opacity,
      points: polygon.map((pt) => DrawingPoint(offset: pt, pressure: 1.0)).toList(),
    );
  }
}
