import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';

void main() {
  group('DrawingController Tests', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController();
    });

    test('Initializes with default layer and pen tool', () {
      expect(controller.layers.length, 1);
      expect(controller.activeLayerIndex, 0);
      expect(controller.activeLayer.name, 'Capa 1');
      expect(controller.selectedTool, DrawingToolType.pen);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });

    test('Stroke creation flow adds stroke to active layer and records history', () {
      controller.startStroke(const Offset(10, 10), 0.5);
      expect(controller.activeStroke, isNotNull);
      expect(controller.activeStroke!.points.length, 1);

      controller.updateStroke(const Offset(20, 20), 0.7);
      expect(controller.activeStroke!.points.length, 2);

      controller.endStroke();
      expect(controller.activeStroke, isNull);
      expect(controller.activeLayer.strokes.length, 1);
      expect(controller.canUndo, isTrue);
    });

    test('Undo and Redo restores strokes accurately', () {
      controller.startStroke(const Offset(10, 10), 1.0);
      controller.updateStroke(const Offset(20, 20), 1.0);
      controller.endStroke();

      expect(controller.activeLayer.strokes.length, 1);

      controller.undo();
      expect(controller.activeLayer.strokes.length, 0);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);

      controller.redo();
      expect(controller.activeLayer.strokes.length, 1);
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);
    });

    test('Layer management: add, switch, hide, opacity, delete', () {
      controller.addLayer(name: 'Líneas');
      expect(controller.layers.length, 2);
      expect(controller.activeLayerIndex, 1);
      expect(controller.activeLayer.name, 'Líneas');

      controller.toggleLayerVisibility(0);
      expect(controller.layers[0].isVisible, isFalse);

      controller.setLayerOpacity(1, 0.4);
      expect(controller.layers[1].opacity, 0.4);

      controller.setActiveLayer(0);
      expect(controller.activeLayerIndex, 0);

      // Cannot delete if only 1 layer remaining
      final deleted = controller.removeLayer(1);
      expect(deleted, isTrue);
      expect(controller.layers.length, 1);

      final secondDelete = controller.removeLayer(0);
      expect(secondDelete, isFalse);
      expect(controller.layers.length, 1);
    });

    test('Clear active layer clears strokes and allows undo', () {
      controller.startStroke(const Offset(10, 10), 1.0);
      controller.endStroke();
      expect(controller.activeLayer.strokes.length, 1);

      controller.clearActiveLayer();
      expect(controller.activeLayer.strokes.length, 0);

      controller.undo();
      expect(controller.activeLayer.strokes.length, 1);
    });

    test('Tool adjustments update values', () {
      controller.selectTool(DrawingToolType.pencil);
      expect(controller.selectedTool, DrawingToolType.pencil);

      controller.setColor(const Color(0xFFFF6B00));
      expect(controller.selectedColor, const Color(0xFFFF6B00));

      controller.setStrokeWidth(12.0);
      expect(controller.strokeWidth, 12.0);

      controller.setOpacity(0.65);
      expect(controller.strokeOpacity, 0.65);
    });
  });
}
