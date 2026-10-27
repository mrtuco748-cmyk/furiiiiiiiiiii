import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_layer_operations.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_layer.dart';

void main() {
  group('DrawingLayerOperations.reorderLayers Tests', () {
    test('Reordering 2 layers top to bottom swaps correctly without RangeError', () {
      final layer0 = DrawingLayer(id: 'l0', name: 'Layer 1', strokes: []);
      final layer1 = DrawingLayer(id: 'l1', name: 'Layer 2', strokes: []);
      final current = [layer0, layer1]; // layer0 is bottom, layer1 is top (visual index 0 is layer1, visual index 1 is layer0)

      // Dragging top visual (index 0) to bottom (index 2 in Flutter's onReorder)
      final (updated, nextActive) = DrawingLayerOperations.reorderLayers(current, 1, 0, 2);

      // After moving top to bottom, layer1 should now be at the bottom (index 0) and layer0 at the top (index 1)
      expect(updated.length, 2);
      expect(updated[0].id, 'l1');
      expect(updated[1].id, 'l0');
      // activeId 'l1' was at index 1, now at index 0
      expect(nextActive, 0);
    });

    test('Reordering 2 layers bottom to top swaps correctly', () {
      final layer0 = DrawingLayer(id: 'l0', name: 'Layer 1', strokes: []);
      final layer1 = DrawingLayer(id: 'l1', name: 'Layer 2', strokes: []);
      final current = [layer0, layer1]; // visual: [l1, l0]

      // Dragging bottom visual (index 1) to top (index 0)
      final (updated, nextActive) = DrawingLayerOperations.reorderLayers(current, 0, 1, 0);

      // visual: [l0, l1] -> current: [l1, l0]
      expect(updated.length, 2);
      expect(updated[0].id, 'l1');
      expect(updated[1].id, 'l0');
      expect(nextActive, 1); // activeId 'l0' is now at index 1
    });

    test('Reordering 3 layers maintains correct order and active tracking', () {
      final l0 = DrawingLayer(id: '0', name: 'Capa 1', strokes: []);
      final l1 = DrawingLayer(id: '1', name: 'Capa 2', strokes: []);
      final l2 = DrawingLayer(id: '2', name: 'Capa 3', strokes: []);
      // Layers: [0, 1, 2] (visual: [2, 1, 0])
      final current = [l0, l1, l2];

      // Drag top layer (visual 0 = layer 2) to middle (visual 2 -> targetIndex 1)
      final (updated, nextActive) = DrawingLayerOperations.reorderLayers(current, 2, 0, 2);

      // visual should be: [1, 2, 0] -> current layers: [0, 2, 1]
      expect(updated.map((l) => l.id).toList(), ['0', '2', '1']);
      expect(nextActive, 1); // layer '2' is now at index 1
    });

    test('Reordering out of bounds does not crash and returns original list', () {
      final l0 = DrawingLayer(id: '0', name: 'Capa 1', strokes: []);
      final l1 = DrawingLayer(id: '1', name: 'Capa 2', strokes: []);
      final current = [l0, l1];

      final (res1, active1) = DrawingLayerOperations.reorderLayers(current, 0, -1, 1);
      expect(res1, equals(current));
      expect(active1, 0);

      final (res2, active2) = DrawingLayerOperations.reorderLayers(current, 1, 0, 99);
      expect(res2, equals(current));
      expect(active2, 1);
    });

    test('Single layer reorder does nothing', () {
      final l0 = DrawingLayer(id: '0', name: 'Capa 1', strokes: []);
      final current = [l0];

      final (res, active) = DrawingLayerOperations.reorderLayers(current, 0, 0, 1);
      expect(res, equals(current));
      expect(active, 0);
    });

    test('Layer opacity and visibility operations work as expected', () {
      final l0 = DrawingLayer(id: '0', name: 'Capa 1', strokes: [], opacity: 1.0, isVisible: true);
      final l1 = DrawingLayer(id: '1', name: 'Capa 2', strokes: [], opacity: 1.0, isVisible: true);
      final current = [l0, l1];

      final opacified = DrawingLayerOperations.setOpacity(current, 1, 0.45);
      expect(opacified[1].opacity, closeTo(0.45, 0.001));
      expect(opacified[0].opacity, 1.0);

      final toggled = DrawingLayerOperations.toggleVisibility(current, 0);
      expect(toggled[0].isVisible, false);
      expect(toggled[1].isVisible, true);
    });
  });
}
