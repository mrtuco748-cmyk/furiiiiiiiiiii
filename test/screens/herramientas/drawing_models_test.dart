import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_point.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_stroke.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_layer.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';

void main() {
  group('Drawing Models Tests', () {
    test('DrawingPoint instantiates with offset and pressure', () {
      final point = DrawingPoint(
        offset: const Offset(10, 20),
        pressure: 0.8,
        timestamp: 12345,
      );

      expect(point.offset.dx, 10);
      expect(point.offset.dy, 20);
      expect(point.pressure, 0.8);
      expect(point.timestamp, 12345);
    });

    test('DrawingStroke creates and calculates smoothed path', () {
      final stroke = DrawingStroke(
        id: 'stroke_1',
        tool: DrawingToolType.pen,
        color: const Color(0xFF00D4FF),
        strokeWidth: 4.0,
        opacity: 0.9,
        points: [
          DrawingPoint(offset: const Offset(0, 0)),
          DrawingPoint(offset: const Offset(10, 10)),
          DrawingPoint(offset: const Offset(20, 20)),
          DrawingPoint(offset: const Offset(30, 20)),
        ],
      );

      expect(stroke.id, 'stroke_1');
      expect(stroke.tool, DrawingToolType.pen);
      expect(stroke.points.length, 4);

      final path = stroke.path;
      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.left, 0);
      expect(bounds.top, 0);
      expect(bounds.right, 30);
    });

    test('DrawingLayer handles strokes and properties', () {
      final layer = DrawingLayer(
        id: 'layer_1',
        name: 'Boceto',
        isVisible: true,
        isLocked: false,
        opacity: 0.75,
        strokes: [],
      );

      expect(layer.id, 'layer_1');
      expect(layer.name, 'Boceto');
      expect(layer.isVisible, true);
      expect(layer.opacity, 0.75);

      final stroke = DrawingStroke(
        id: 's1',
        tool: DrawingToolType.pencil,
        color: const Color(0xFFFFFFFF),
        strokeWidth: 2.0,
        opacity: 1.0,
        points: [DrawingPoint(offset: const Offset(5, 5))],
      );

      final updated = layer.copyWith(
        strokes: [stroke],
        opacity: 0.5,
      );

      expect(updated.strokes.length, 1);
      expect(updated.opacity, 0.5);
      expect(updated.id, 'layer_1');
    });

    test('DrawingToolType provides tool metadata', () {
      expect(DrawingToolType.pen.displayName, 'Birome');
      expect(DrawingToolType.pencil.displayName, 'Lápiz');
      expect(DrawingToolType.eraser.isEraser, isTrue);
      expect(DrawingToolType.highlighter.defaultOpacity < 1.0, isTrue);
    });
  });
}
