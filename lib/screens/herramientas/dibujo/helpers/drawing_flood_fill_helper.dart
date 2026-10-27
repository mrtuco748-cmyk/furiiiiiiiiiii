import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/drawing_point.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_tool_type.dart';
import 'drawing_fill_island_detector.dart';

class _Segment {
  final Offset a;
  final Offset b;
  const _Segment(this.a, this.b);
}

/// Helper para detección de regiones cerradas y relleno inteligente con balde de pintura.
/// Soporta recorte de islas interiores (manchas, puntos y detalles) para que no sean pintadas.
abstract final class DrawingFloodFillHelper {
  /// Encuentra los puntos del polígono exterior cerrado que encierra el punto [seed].
  static List<Offset> findEnclosedRegion({
    required Offset seed,
    required List<DrawingStroke> strokes,
    required Size canvasSize,
  }) {
    return _findEnclosedContainer(seed: seed, strokes: strokes, canvasSize: canvasSize).$1;
  }

  /// Encuentra el contenedor más específico que encierra a [seed] y el trazo correspondiente.
  static (List<Offset>, DrawingStroke?) _findEnclosedContainer({
    required Offset seed,
    required List<DrawingStroke> strokes,
    required Size canvasSize,
  }) {
    final candidates = <(DrawingStroke, List<Offset>, double)>[];

    for (final stroke in strokes) {
      if (stroke.tool == DrawingToolType.bucketFill || stroke.tool.isEraser) continue;

      // Círculo / Óvalo
      if (stroke.tool == DrawingToolType.circle && stroke.points.length >= 2) {
        final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
        final rx = r.width / 2;
        final ry = r.height / 2;
        if (rx > 0 && ry > 0) {
          final dx = (seed.dx - r.center.dx) / rx;
          final dy = (seed.dy - r.center.dy) / ry;
          if (dx * dx + dy * dy <= 1.0) {
            final poly = List.generate(48, (i) {
              final a = (i * 2 * math.pi) / 48;
              return Offset(r.center.dx + rx * math.cos(a), r.center.dy + ry * math.sin(a));
            });
            candidates.add((stroke, poly, math.pi * rx * ry));
          }
        }
      }

      // Rectángulo
      else if (stroke.tool == DrawingToolType.rectangle && stroke.points.length >= 2) {
        final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
        if (r.contains(seed)) {
          final poly = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
          candidates.add((stroke, poly, r.width * r.height));
        }
      }

      // Trazo a mano alzada cerrado (loop)
      else if (stroke.points.length >= 3) {
        final startDist = (stroke.points.first.offset - stroke.points.last.offset).distance;
        final isClosedLoop = startDist <= math.max(45.0, stroke.strokeWidth * 3.5);
        if (isClosedLoop) {
          final closedPath = Path.from(stroke.path)..close();
          if (closedPath.contains(seed)) {
            final b = closedPath.getBounds();
            candidates.add((stroke, stroke.points.map((p) => p.offset).toList(), b.width * b.height));
          }
        }
      }
    }

    if (candidates.isNotEmpty) {
      // Priorizar el contenedor más específico / más pequeño que contiene al toque
      candidates.sort((a, b) => a.$3.compareTo(b.$3));
      return (candidates.first.$2, candidates.first.$1);
    }

    // Re-coloreo de un relleno cerrado existente
    for (final stroke in strokes.reversed) {
      if (stroke.tool == DrawingToolType.bucketFill && stroke.points.length >= 3) {
        final pts = stroke.points.map((p) => p.offset).toList();
        if (!_isCanvasBoundary(pts, canvasSize) && stroke.path.contains(seed)) {
          return (pts, stroke);
        }
      }
    }

    // Trazado radial contra segmentos continuos
    final radialPoly = _traceRadialEnclosure(seed: seed, strokes: strokes, canvasSize: canvasSize);
    return (radialPoly, null);
  }

  static List<Offset> _traceRadialEnclosure({
    required Offset seed,
    required List<DrawingStroke> strokes,
    required Size canvasSize,
  }) {
    final segments = _collectSegments(strokes);
    if (segments.isEmpty) {
      return _canvasBoundary(canvasSize);
    }

    const int rayCount = 48;
    final maxDist = math.sqrt(canvasSize.width * canvasSize.width + canvasSize.height * canvasSize.height);
    final hits = List<Offset?>.filled(rayCount, null);

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount;
      final dir = Offset(math.cos(angle), math.sin(angle));
      double minT = double.infinity;

      for (final seg in segments) {
        final v1 = seg.a - seed;
        final v2 = seg.b - seg.a;
        final det = dir.dx * v2.dy - dir.dy * v2.dx;
        if (det.abs() < 1e-9) continue;

        final t = (v1.dx * v2.dy - v1.dy * v2.dx) / det;
        final s = (v1.dx * dir.dy - v1.dy * dir.dx) / det;

        if (t > 1.8 && t < minT && s >= -0.02 && s <= 1.02) {
          minT = t;
        }
      }

      if (minT < maxDist) {
        hits[i] = seed + dir * (minT + 1.5);
      }
    }

    for (int i = 0; i < rayCount; i++) {
      if (hits[i] == null) {
        final prev = hits[(i - 1 + rayCount) % rayCount];
        final next = hits[(i + 1) % rayCount];
        if (prev != null && next != null && (prev - next).distance < 45.0) {
          hits[i] = Offset((prev.dx + next.dx) / 2, (prev.dy + next.dy) / 2);
        }
      }
    }

    final validHits = <Offset>[];
    bool hasMissingRay = false;
    for (int i = 0; i < rayCount; i++) {
      if (hits[i] != null) {
        validHits.add(hits[i]!);
      } else {
        hasMissingRay = true;
      }
    }

    if (!hasMissingRay && validHits.length >= 8) {
      return validHits;
    }

    return _canvasBoundary(canvasSize);
  }

  static List<_Segment> _collectSegments(List<DrawingStroke> strokes) {
    final segments = <_Segment>[];
    for (final stroke in strokes) {
      if (stroke.tool == DrawingToolType.bucketFill || stroke.tool.isEraser) continue;

      if (stroke.tool == DrawingToolType.line || stroke.tool == DrawingToolType.trajectory) {
        if (stroke.points.length >= 2) {
          segments.add(_Segment(stroke.points.first.offset, stroke.points.last.offset));
        }
      } else if (stroke.tool == DrawingToolType.rectangle) {
        if (stroke.points.length >= 2) {
          final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
          segments.add(_Segment(r.topLeft, r.topRight));
          segments.add(_Segment(r.topRight, r.bottomRight));
          segments.add(_Segment(r.bottomRight, r.bottomLeft));
          segments.add(_Segment(r.bottomLeft, r.topLeft));
        }
      } else if (stroke.tool == DrawingToolType.circle) {
        if (stroke.points.length >= 2) {
          final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
          final rx = r.width / 2;
          final ry = r.height / 2;
          for (int i = 0; i < 32; i++) {
            final a1 = (i * 2 * math.pi) / 32;
            final a2 = ((i + 1) * 2 * math.pi) / 32;
            segments.add(_Segment(
              Offset(r.center.dx + rx * math.cos(a1), r.center.dy + ry * math.sin(a1)),
              Offset(r.center.dx + rx * math.cos(a2), r.center.dy + ry * math.sin(a2)),
            ));
          }
        }
      } else {
        for (int i = 0; i < stroke.points.length - 1; i++) {
          segments.add(_Segment(stroke.points[i].offset, stroke.points[i + 1].offset));
        }
      }
    }
    return segments;
  }

  static bool _isCanvasBoundary(List<Offset> pts, Size size) {
    if (pts.length != 4) return false;
    return pts[0] == Offset.zero &&
        pts[1] == Offset(size.width, 0) &&
        pts[2] == Offset(size.width, size.height) &&
        pts[3] == Offset(0, size.height);
  }

  static List<Offset> _canvasBoundary(Size size) {
    return [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
  }

  /// Crea un trazo de relleno de balde cerrado en [seed], excluyendo automáticamente manchas interiores.
  static DrawingStroke createFillStroke({
    required Offset seed,
    required Color color,
    required double opacity,
    required List<DrawingStroke> existingStrokes,
    required Size canvasSize,
    List<Offset>? selectionPolygon,
  }) {
    List<Offset> outerPolygon;
    DrawingStroke? containerStroke;

    if (selectionPolygon != null && selectionPolygon.length >= 3) {
      outerPolygon = selectionPolygon;
    } else {
      final res = _findEnclosedContainer(seed: seed, strokes: existingStrokes, canvasSize: canvasSize);
      outerPolygon = res.$1;
      containerStroke = res.$2;
    }

    final isBoundary = _isCanvasBoundary(outerPolygon, canvasSize);
    List<DrawingPoint> finalPoints;

    if (!isBoundary && outerPolygon.length >= 3) {
      final outerPath = Path();
      outerPath.moveTo(outerPolygon.first.dx, outerPolygon.first.dy);
      for (int i = 1; i < outerPolygon.length; i++) {
        outerPath.lineTo(outerPolygon[i].dx, outerPolygon[i].dy);
      }
      outerPath.close();

      final islands = <List<Offset>>[];
      for (final stroke in existingStrokes) {
        if (stroke.id == containerStroke?.id) continue;
        if (stroke.tool == DrawingToolType.bucketFill || stroke.tool.isEraser) continue;

        if (DrawingFillIslandDetector.strokeIsInsidePath(stroke, outerPath) &&
            !DrawingFillIslandDetector.strokeContainsPoint(stroke, seed)) {
          final islandPoly = DrawingFillIslandDetector.buildIslandPolygon(stroke);
          if (islandPoly.length >= 3) {
            islands.add(islandPoly);
          }
        }
      }

      finalPoints = DrawingFillIslandDetector.composePointsWithIslands(outerPolygon, islands);
    } else {
      finalPoints = outerPolygon.map((pt) => DrawingPoint(offset: pt, pressure: 1.0)).toList();
    }

    return DrawingStroke(
      id: 'fill_${DateTime.now().microsecondsSinceEpoch}',
      tool: DrawingToolType.bucketFill,
      color: color,
      strokeWidth: 1.0,
      opacity: opacity,
      points: finalPoints,
    );
  }
}
