import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/drawing_point.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_tool_type.dart';

/// Detector y extractor de islas (manchas, puntos y trazos interiores)
/// para que el balde de pintura respete los detalles internos sin pintarlos.
abstract final class DrawingFillIslandDetector {
  /// Determina si un trazo contiene un punto dado [point] (considerando su grosor/área).
  static bool strokeContainsPoint(DrawingStroke stroke, Offset point) {
    if (stroke.tool == DrawingToolType.circle && stroke.points.length >= 2) {
      final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
      final rx = r.width / 2;
      final ry = r.height / 2;
      if (rx > 0 && ry > 0) {
        final dx = (point.dx - r.center.dx) / rx;
        final dy = (point.dy - r.center.dy) / ry;
        return (dx * dx + dy * dy) <= 1.0;
      }
    }

    if (stroke.tool == DrawingToolType.rectangle && stroke.points.length >= 2) {
      final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
      return r.contains(point);
    }

    if (stroke.points.length == 1) {
      final radius = math.max(stroke.strokeWidth / 2 + 1.5, 4.0);
      return (stroke.points.first.offset - point).distance <= radius;
    }

    // Trazo a mano alzada / línea: proximidad a segmentos con grosor
    final halfW = stroke.strokeWidth / 2 + 2.0;
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final a = stroke.points[i].offset;
      final b = stroke.points[i + 1].offset;
      if (distanceToSegment(point, a, b) <= halfW) {
        return true;
      }
    }

    // Trazo cerrado a mano alzada
    if (stroke.points.length >= 3) {
      final startDist = (stroke.points.first.offset - stroke.points.last.offset).distance;
      if (startDist <= math.max(45.0, stroke.strokeWidth * 3.5)) {
        final closedPath = Path.from(stroke.path)..close();
        if (closedPath.contains(point)) return true;
      }
    }

    return false;
  }

  /// Distancia euclidiana mínima de un punto [p] a un segmento de recta [a]-[b].
  static double distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq < 1e-6) return (p - a).distance;
    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lenSq).clamp(0.0, 1.0);
    final proj = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - proj).distance;
  }

  /// Verifica si un trazo está geométricamente contenido dentro de [outerPath].
  static bool strokeIsInsidePath(DrawingStroke stroke, Path outerPath) {
    if (stroke.points.isEmpty) return false;

    if (stroke.points.length == 1) {
      return outerPath.contains(stroke.points.first.offset);
    }

    if (stroke.tool == DrawingToolType.circle || stroke.tool == DrawingToolType.rectangle) {
      final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
      return outerPath.contains(r.center) &&
          outerPath.contains(r.topLeft) &&
          outerPath.contains(r.bottomRight);
    }

    int insideCount = 0;
    for (final p in stroke.points) {
      if (outerPath.contains(p.offset)) insideCount++;
    }
    return insideCount >= (stroke.points.length * 0.7);
  }

  /// Estima el área superficial del trazo para priorizar contenedores específicos.
  static double estimateStrokeArea(DrawingStroke stroke) {
    if (stroke.tool == DrawingToolType.circle && stroke.points.length >= 2) {
      final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
      return math.pi * (r.width / 2) * (r.height / 2);
    }
    if (stroke.tool == DrawingToolType.rectangle && stroke.points.length >= 2) {
      final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
      return r.width * r.height;
    }
    if (stroke.points.length == 1) {
      final rad = math.max(stroke.strokeWidth / 2, 4.0);
      return math.pi * rad * rad;
    }
    final b = stroke.path.getBounds();
    return b.width * b.height;
  }

  /// Genera un polígono perimetral cerrado para un trazo interior que actúa como isla.
  static List<Offset> buildIslandPolygon(DrawingStroke stroke) {
    // 1. Punto único (dot / lunar / peca)
    if (stroke.points.length == 1) {
      final center = stroke.points.first.offset;
      final radius = math.max(stroke.strokeWidth / 2 + 1.2, 4.0);
      return List.generate(16, (i) {
        final a = (i * 2 * math.pi) / 16;
        return Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a));
      });
    }

    // 2. Trazo diminuto de 2 puntos
    if (stroke.points.length == 2 &&
        (stroke.points.first.offset - stroke.points.last.offset).distance < stroke.strokeWidth) {
      final p1 = stroke.points.first.offset;
      final p2 = stroke.points.last.offset;
      final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final radius = math.max((p1 - p2).distance / 2 + stroke.strokeWidth / 2 + 1.2, 4.0);
      return List.generate(16, (i) {
        final a = (i * 2 * math.pi) / 16;
        return Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a));
      });
    }

    // 3. Círculo u óvalo interior
    if (stroke.tool == DrawingToolType.circle && stroke.points.length >= 2) {
      final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset);
      final rx = r.width / 2 + stroke.strokeWidth / 2 + 1.2;
      final ry = r.height / 2 + stroke.strokeWidth / 2 + 1.2;
      return List.generate(24, (i) {
        final a = (i * 2 * math.pi) / 24;
        return Offset(r.center.dx + rx * math.cos(a), r.center.dy + ry * math.sin(a));
      });
    }

    // 4. Rectángulo interior
    if (stroke.tool == DrawingToolType.rectangle && stroke.points.length >= 2) {
      final r = Rect.fromPoints(stroke.points.first.offset, stroke.points.last.offset)
          .inflate(stroke.strokeWidth / 2 + 1.2);
      return [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
    }

    // 5. Trazo cerrado a mano alzada
    if (stroke.points.length >= 3) {
      final startDist = (stroke.points.first.offset - stroke.points.last.offset).distance;
      if (startDist <= math.max(45.0, stroke.strokeWidth * 3.5)) {
        return stroke.points.map((p) => p.offset).toList();
      }
    }

    // 6. Trazo a mano alzada abierto / mancha con grosor: envolvente perimetral
    final w = stroke.strokeWidth / 2 + 1.2;
    final leftPoints = <Offset>[];
    final rightPoints = <Offset>[];

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i].offset;
      final p2 = stroke.points[i + 1].offset;
      final d = p2 - p1;
      final dist = d.distance;
      if (dist < 1e-4) continue;
      final normal = Offset(-d.dy / dist, d.dx / dist) * w;
      leftPoints.add(p1 + normal);
      rightPoints.add(p1 - normal);
      if (i == stroke.points.length - 2) {
        leftPoints.add(p2 + normal);
        rightPoints.add(p2 - normal);
      }
    }

    if (leftPoints.isEmpty) {
      final center = stroke.points.first.offset;
      return List.generate(12, (i) {
        final a = (i * 2 * math.pi) / 12;
        return Offset(center.dx + w * math.cos(a), center.dy + w * math.sin(a));
      });
    }

    return [...leftPoints, ...rightPoints.reversed];
  }

  /// Compone la lista final de [DrawingPoint] combinando el contorno exterior con las islas interiores.
  static List<DrawingPoint> composePointsWithIslands(
    List<Offset> outerPolygon,
    List<List<Offset>> islands,
  ) {
    final points = <DrawingPoint>[];

    // Contorno exterior
    for (final pt in outerPolygon) {
      points.add(DrawingPoint(offset: pt, pressure: 1.0));
    }

    // Islas interiores: primer punto con pressure: -1.0 para marcar nuevo sub-path
    for (final island in islands) {
      if (island.isEmpty) continue;
      points.add(DrawingPoint(offset: island.first, pressure: -1.0));
      for (int i = 1; i < island.length; i++) {
        points.add(DrawingPoint(offset: island[i], pressure: 1.0));
      }
    }

    return points;
  }
}
