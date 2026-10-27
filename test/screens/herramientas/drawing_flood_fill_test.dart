import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/helpers/drawing_flood_fill_helper.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_point.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_stroke.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DrawingFloodFillHelper & Fill Tool Tests', () {
    const canvasSize = Size(1000, 1000);

    test('DrawingStroke._buildPath closes the path for bucketFill tool', () {
      final stroke = DrawingStroke(
        id: 'fill_1',
        tool: DrawingToolType.bucketFill,
        color: const Color(0xFFFF0000),
        strokeWidth: 1.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(10, 10)),
          DrawingPoint(offset: const Offset(50, 10)),
          DrawingPoint(offset: const Offset(50, 50)),
          DrawingPoint(offset: const Offset(10, 50)),
        ],
      );

      final path = stroke.path;
      expect(path.contains(const Offset(30, 30)), isTrue);
      expect(path.contains(const Offset(5, 5)), isFalse);
    });

    test('findEnclosedRegion detects circle shape and fills inside without flooding canvas', () {
      final circleStroke = DrawingStroke(
        id: 'circle_1',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 4.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(300, 300)),
        ],
      );

      final polygon = DrawingFloodFillHelper.findEnclosedRegion(
        seed: const Offset(200, 200),
        strokes: [circleStroke],
        canvasSize: canvasSize,
      );

      // Must be a circular polygon of >= 24 points around center (200, 200), not the 4 canvas boundary points
      expect(polygon.length, greaterThanOrEqualTo(24));
      expect(polygon, isNot(equals([
        Offset.zero,
        Offset(canvasSize.width, 0),
        Offset(canvasSize.width, canvasSize.height),
        Offset(0, canvasSize.height),
      ])));

      // The points must surround (200, 200) with radius approx 100
      for (final pt in polygon) {
        final dist = (pt - const Offset(200, 200)).distance;
        expect(dist, closeTo(100.0, 5.0));
      }
    });

    test('findEnclosedRegion detects rectangle shape and returns 4 corners', () {
      final rectStroke = DrawingStroke(
        id: 'rect_1',
        tool: DrawingToolType.rectangle,
        color: const Color(0xFF000000),
        strokeWidth: 4.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(50, 50)),
          DrawingPoint(offset: const Offset(250, 150)),
        ],
      );

      final polygon = DrawingFloodFillHelper.findEnclosedRegion(
        seed: const Offset(100, 100),
        strokes: [rectStroke],
        canvasSize: canvasSize,
      );

      expect(polygon.length, equals(4));
      expect(polygon, containsAll([
        const Offset(50, 50),
        const Offset(250, 50),
        const Offset(250, 150),
        const Offset(50, 150),
      ]));
    });

    test('findEnclosedRegion detects single-stroke closed freehand loop', () {
      // Draw a closed square loop with pen
      final loopStroke = DrawingStroke(
        id: 'loop_1',
        tool: DrawingToolType.pen,
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(200, 100)),
          DrawingPoint(offset: const Offset(200, 200)),
          DrawingPoint(offset: const Offset(100, 200)),
          DrawingPoint(offset: const Offset(100, 100)), // closed: same as first
        ],
      );

      final polygon = DrawingFloodFillHelper.findEnclosedRegion(
        seed: const Offset(150, 150),
        strokes: [loopStroke],
        canvasSize: canvasSize,
      );

      expect(polygon.length, equals(5));
      expect(polygon.first, const Offset(100, 100));
    });

    test('findEnclosedRegion does NOT falsely treat an open "U" curve as closed', () {
      // Draw an open U-curve: endpoints are far apart (100, 100) and (200, 100)
      final openStroke = DrawingStroke(
        id: 'open_u',
        tool: DrawingToolType.pen,
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(100, 250)),
          DrawingPoint(offset: const Offset(200, 250)),
          DrawingPoint(offset: const Offset(200, 100)),
        ],
      );

      final polygon = DrawingFloodFillHelper.findEnclosedRegion(
        seed: const Offset(150, 200),
        strokes: [openStroke],
        canvasSize: canvasSize,
      );

      // Since the top of the U is completely open, it must NOT return a closed shape of the stroke points
      expect(polygon, isNot(equals(openStroke.points.map((p) => p.offset).toList())));
    });

    test('findEnclosedRegion detects multi-stroke enclosure (triangle of 3 lines)', () {
      final line1 = DrawingStroke(
        id: 'l1',
        tool: DrawingToolType.line,
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
        opacity: 1.0,
        points: [DrawingPoint(offset: const Offset(100, 100)), DrawingPoint(offset: const Offset(300, 100))],
      );
      final line2 = DrawingStroke(
        id: 'l2',
        tool: DrawingToolType.line,
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
        opacity: 1.0,
        points: [DrawingPoint(offset: const Offset(300, 100)), DrawingPoint(offset: const Offset(200, 300))],
      );
      final line3 = DrawingStroke(
        id: 'l3',
        tool: DrawingToolType.line,
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
        opacity: 1.0,
        points: [DrawingPoint(offset: const Offset(200, 300)), DrawingPoint(offset: const Offset(100, 100))],
      );

      final polygon = DrawingFloodFillHelper.findEnclosedRegion(
        seed: const Offset(200, 150),
        strokes: [line1, line2, line3],
        canvasSize: canvasSize,
      );

      // Must detect all-around boundary and return >= 24 polygon points inside canvas
      expect(polygon.length, greaterThanOrEqualTo(24));
      for (final pt in polygon) {
        expect(pt.dx, inInclusiveRange(95.0, 305.0));
        expect(pt.dy, inInclusiveRange(95.0, 305.0));
      }
    });

    test('findEnclosedRegion allows re-coloring an already filled region', () {
      final existingFill = DrawingStroke(
        id: 'prev_fill',
        tool: DrawingToolType.bucketFill,
        color: const Color(0xFFFF0000),
        strokeWidth: 1.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(200, 100)),
          DrawingPoint(offset: const Offset(200, 200)),
          DrawingPoint(offset: const Offset(100, 200)),
        ],
      );

      final polygon = DrawingFloodFillHelper.findEnclosedRegion(
        seed: const Offset(150, 150),
        strokes: [existingFill],
        canvasSize: canvasSize,
      );

      expect(polygon.length, equals(4));
      expect(polygon.first, const Offset(100, 100));
    });

    test('DrawingController floodFill uses visible layers as boundary and adds stroke to active layer', () {
      final controller = DrawingController();
      controller.setCanvasSize(canvasSize);

      // Capa 1: Draw a circle
      final circle = DrawingStroke(
        id: 'c1',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 4.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(300, 300)),
        ],
      );
      controller.addDirectStroke(circle);

      // Add Capa 2 (active layer)
      controller.addLayer(name: 'Capa 2');
      expect(controller.activeLayerIndex, equals(1));
      expect(controller.activeLayer.strokes, isEmpty);

      // Fill inside the circle while on Capa 2
      controller.selectTool(DrawingToolType.bucketFill);
      controller.setColor(const Color(0xFF00D4FF));
      controller.startStroke(const Offset(200, 200));

      // Active layer (Capa 2) should now have the bucketFill stroke
      expect(controller.activeLayer.strokes.length, equals(1));
      final fillStroke = controller.activeLayer.strokes.first;
      expect(fillStroke.tool, equals(DrawingToolType.bucketFill));
      expect(fillStroke.points.length, greaterThanOrEqualTo(24));

      // Layer 1 still only has the original circle
      expect(controller.layers[0].strokes.length, equals(1));
      expect(controller.layers[0].strokes.first.tool, equals(DrawingToolType.circle));
    });
  });
}
