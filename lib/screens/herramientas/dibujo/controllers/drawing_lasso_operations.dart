import 'package:flutter/material.dart';
import '../models/drawing_lasso_selection.dart';
import '../models/drawing_point.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_tool_type.dart';
import 'drawing_controller.dart';

/// Operaciones puras para la herramienta de Lazo y manipulación de selección.
abstract final class DrawingLassoOperations {
  static bool isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    int count = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];
      if ((p1.dy > point.dy) != (p2.dy > point.dy)) {
        final atX = (p2.dx - p1.dx) * (point.dy - p1.dy) / (p2.dy - p1.dy) + p1.dx;
        if (point.dx < atX) count++;
      }
    }
    return (count % 2) != 0;
  }

  static DrawingLassoSelection? createSelection(
    List<Offset> polygonPoints,
    List<DrawingStroke> layerStrokes,
  ) {
    if (polygonPoints.length < 3) return null;

    double minX = polygonPoints.first.dx;
    double maxX = polygonPoints.first.dx;
    double minY = polygonPoints.first.dy;
    double maxY = polygonPoints.first.dy;

    for (final p in polygonPoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);

    // Encontrar trazos encerrados o que intersectan
    final selectedIds = <String>[];
    for (final stroke in layerStrokes) {
      if (stroke.tool == DrawingToolType.eraser) continue;
      bool enclosed = false;
      for (final pt in stroke.points) {
        if (isPointInPolygon(pt.offset, polygonPoints)) {
          enclosed = true;
          break;
        }
      }
      if (!enclosed && stroke.points.length >= 2) {
        final p1 = stroke.points.first.offset;
        final p2 = stroke.points.last.offset;
        final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        if (isPointInPolygon(center, polygonPoints) ||
            isPointInPolygon(Offset(p1.dx, p2.dy), polygonPoints) ||
            isPointInPolygon(Offset(p2.dx, p1.dy), polygonPoints)) {
          enclosed = true;
        }
      }
      if (enclosed) {
        selectedIds.add(stroke.id);
      }
    }

    return DrawingLassoSelection(
      polygonPoints: polygonPoints,
      selectedStrokeIds: selectedIds,
      bounds: bounds,
    );
  }

  static List<DrawingStroke> moveStrokes(
    List<DrawingStroke> strokes,
    List<String> targetIds,
    Offset delta,
  ) {
    final targets = targetIds.toSet();
    return strokes.map((s) {
      if (!targets.contains(s.id)) return s;
      final movedPoints = s.points.map((p) => DrawingPoint(
        offset: p.offset + delta,
        pressure: p.pressure,
      )).toList();
      return s.copyWith(points: movedPoints);
    }).toList();
  }

  static (List<DrawingStroke>, List<String>) duplicateStrokes(
    List<DrawingStroke> strokes,
    List<String> targetIds,
    Offset offset,
  ) {
    final targets = targetIds.toSet();
    final newStrokes = <DrawingStroke>[];
    final newIds = <String>[];

    for (final s in strokes) {
      if (!targets.contains(s.id)) continue;
      final newId = 'dup_${DateTime.now().microsecondsSinceEpoch}_${s.id}';
      final duplicatedPoints = s.points.map((p) => DrawingPoint(
        offset: p.offset + offset,
        pressure: p.pressure,
      )).toList();
      final dup = s.copyWith(id: newId, points: duplicatedPoints);
      newStrokes.add(dup);
      newIds.add(newId);
    }

    return (List<DrawingStroke>.from(strokes)..addAll(newStrokes), newIds);
  }

  static List<DrawingStroke> deleteStrokes(
    List<DrawingStroke> strokes,
    List<String> targetIds,
  ) {
    final targets = targetIds.toSet();
    return strokes.where((s) => !targets.contains(s.id)).toList();
  }

  static DrawingStroke createPolygonFill(
    List<Offset> polygon,
    Color color,
    double opacity,
  ) {
    final pts = polygon.map((p) => DrawingPoint(offset: p, pressure: 1.0)).toList();
    return DrawingStroke(
      id: 'fill_${DateTime.now().microsecondsSinceEpoch}',
      tool: DrawingToolType.bucketFill,
      color: color,
      strokeWidth: 1.0,
      opacity: opacity,
      points: pts,
    );
  }

  static List<DrawingStroke> flipStrokesHorizontal(
    List<DrawingStroke> strokes,
    List<String> targetIds,
    Rect bounds,
  ) {
    final targets = targetIds.toSet();
    final centerX = bounds.center.dx;

    return strokes.map((s) {
      if (!targets.contains(s.id)) return s;
      final flippedPoints = s.points.map((p) {
        final dist = p.offset.dx - centerX;
        return DrawingPoint(
          offset: Offset(centerX - dist, p.offset.dy),
          pressure: p.pressure,
        );
      }).toList();
      return s.copyWith(points: flippedPoints);
    }).toList();
  }

  static void applyMoveSelection(DrawingController c, Offset delta) {
    final sel = c.activeSelection;
    if (sel == null || c.layers.isEmpty) return;
    final prev = List<DrawingStroke>.from(c.activeLayer.strokes);
    final movedStrokes = moveStrokes(c.activeLayer.strokes, sel.selectedStrokeIds, delta);
    final movedPoly = sel.polygonPoints.map((p) => p + delta).toList();
    c.activeSelection = sel.copyWith(
      polygonPoints: movedPoly,
      bounds: sel.bounds.shift(delta),
    );
    c.updateActiveLayerStrokes(movedStrokes);
    c.recordStrokesUpdate(prev, movedStrokes);
  }

  static void applyDuplicateSelection(DrawingController c) {
    final sel = c.activeSelection;
    if (sel == null || c.layers.isEmpty) return;
    const offset = Offset(24, 24);
    final prev = List<DrawingStroke>.from(c.activeLayer.strokes);
    final (newStrokes, newIds) = duplicateStrokes(c.activeLayer.strokes, sel.selectedStrokeIds, offset);
    final newPoly = sel.polygonPoints.map((p) => p + offset).toList();
    c.activeSelection = sel.copyWith(
      polygonPoints: newPoly,
      selectedStrokeIds: newIds,
      bounds: sel.bounds.shift(offset),
    );
    c.updateActiveLayerStrokes(newStrokes);
    c.recordStrokesUpdate(prev, newStrokes);
  }

  static void applyDeleteSelection(DrawingController c) {
    final sel = c.activeSelection;
    if (sel == null || c.layers.isEmpty) return;
    final prev = List<DrawingStroke>.from(c.activeLayer.strokes);
    final remaining = deleteStrokes(c.activeLayer.strokes, sel.selectedStrokeIds);
    c.activeSelection = null;
    c.updateActiveLayerStrokes(remaining);
    c.recordStrokesUpdate(prev, remaining);
  }

  static void applyFillSelection(DrawingController c) {
    final sel = c.activeSelection;
    if (sel == null || c.layers.isEmpty) return;
    final stroke = createPolygonFill(sel.polygonPoints, c.selectedColor, c.strokeOpacity);
    c.addDirectStroke(stroke);
  }

  static void applyFlipSelectionHorizontal(DrawingController c) {
    final sel = c.activeSelection;
    if (sel == null || c.layers.isEmpty) return;
    final prev = List<DrawingStroke>.from(c.activeLayer.strokes);
    final flipped = flipStrokesHorizontal(c.activeLayer.strokes, sel.selectedStrokeIds, sel.bounds);
    final centerX = sel.bounds.center.dx;
    final flippedPoly = sel.polygonPoints.map((p) => Offset(2 * centerX - p.dx, p.dy)).toList();
    c.activeSelection = sel.copyWith(polygonPoints: flippedPoly);
    c.updateActiveLayerStrokes(flipped);
    c.recordStrokesUpdate(prev, flipped);
  }
}
