import 'dart:ui';
import '../models/drawing_layer.dart';
import '../models/drawing_point.dart';

/// Operaciones puras sobre la lista de capas del taller de dibujo.
abstract final class DrawingLayerOperations {
  static (List<DrawingLayer>, int) addLayer(List<DrawingLayer> currentLayers, {String? name}) {
    final nextNumber = currentLayers.length + 1;
    final layer = DrawingLayer(
      id: 'layer_${DateTime.now().microsecondsSinceEpoch}',
      name: name ?? 'Capa $nextNumber',
      strokes: [],
    );
    final updated = List<DrawingLayer>.from(currentLayers)..add(layer);
    return (updated, updated.length - 1);
  }

  static (List<DrawingLayer>, int) duplicateLayer(List<DrawingLayer> currentLayers, int activeIndex) {
    if (activeIndex < 0 || activeIndex >= currentLayers.length) return (currentLayers, activeIndex);
    final src = currentLayers[activeIndex];
    final copy = DrawingLayer(
      id: 'layer_${DateTime.now().microsecondsSinceEpoch}',
      name: '${src.name} (Copia)',
      strokes: List.from(src.strokes),
      isVisible: src.isVisible,
      opacity: src.opacity,
    );
    final updated = List<DrawingLayer>.from(currentLayers)..insert(activeIndex + 1, copy);
    return (updated, activeIndex + 1);
  }

  static (List<DrawingLayer>, int)? removeLayer(
    List<DrawingLayer> currentLayers,
    int activeIndex,
    int indexToRemove,
  ) {
    if (currentLayers.length <= 1) return null;
    if (indexToRemove < 0 || indexToRemove >= currentLayers.length) return null;

    final updated = List<DrawingLayer>.from(currentLayers)..removeAt(indexToRemove);
    final nextActive = activeIndex >= updated.length ? updated.length - 1 : activeIndex;
    return (updated, nextActive);
  }

  static List<DrawingLayer> toggleVisibility(List<DrawingLayer> currentLayers, int index) {
    if (index < 0 || index >= currentLayers.length) return currentLayers;
    return currentLayers.asMap().entries.map((entry) {
      if (entry.key == index) {
        return entry.value.copyWith(isVisible: !entry.value.isVisible);
      }
      return entry.value;
    }).toList();
  }

  static List<DrawingLayer> setOpacity(List<DrawingLayer> currentLayers, int index, double opacity) {
    if (index < 0 || index >= currentLayers.length) return currentLayers;
    return currentLayers.asMap().entries.map((entry) {
      if (entry.key == index) {
        return entry.value.copyWith(opacity: opacity.clamp(0.0, 1.0));
      }
      return entry.value;
    }).toList();
  }

  static List<DrawingLayer> rotateLayer90(List<DrawingLayer> currentLayers, int index, Size canvasSize) {
    if (index < 0 || index >= currentLayers.length) return currentLayers;
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;

    final rotatedStrokes = currentLayers[index].strokes.map((stroke) {
      final newPoints = stroke.points.map((p) {
        final newX = cx - (p.offset.dy - cy);
        final newY = cy + (p.offset.dx - cx);
        return DrawingPoint(offset: Offset(newX, newY), pressure: p.pressure);
      }).toList();
      return stroke.copyWith(points: newPoints);
    }).toList();

    return currentLayers.asMap().entries.map((e) {
      if (e.key == index) return e.value.copyWith(strokes: rotatedStrokes);
      return e.value;
    }).toList();
  }

  static List<DrawingLayer> invertLayerColors(List<DrawingLayer> currentLayers, int index) {
    if (index < 0 || index >= currentLayers.length) return currentLayers;
    final inverted = currentLayers[index].strokes.map((stroke) {
      final c = stroke.color;
      final invR = (255 - (c.r * 255.0).round()).clamp(0, 255);
      final invG = (255 - (c.g * 255.0).round()).clamp(0, 255);
      final invB = (255 - (c.b * 255.0).round()).clamp(0, 255);
      final a = (c.a * 255.0).round().clamp(0, 255);
      final invColor = Color.fromARGB(a, invR, invG, invB);
      return stroke.copyWith(color: invColor);
    }).toList();

    return currentLayers.asMap().entries.map((e) {
      if (e.key == index) return e.value.copyWith(strokes: inverted);
      return e.value;
    }).toList();
  }
}
