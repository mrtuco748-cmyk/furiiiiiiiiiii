import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/helpers/drawing_flood_fill_helper.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_point.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_stroke.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DrawingFloodFillHelper Islands & Holes Tests', () {
    const canvasSize = Size(1000, 1000);

    test('Fill inside a circle with an interior dot excludes the dot from the fill path', () {
      // Circle centered at (200, 200) with radius 100
      final circle = DrawingStroke(
        id: 'circle_outer',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 4.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(300, 300)),
        ],
      );

      // Single interior dot at (160, 160)
      final dot = DrawingStroke(
        id: 'inner_dot',
        tool: DrawingToolType.pen,
        color: const Color(0xFF000000),
        strokeWidth: 10.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(160, 160)),
        ],
      );

      // Tap on empty space inside the circle at (220, 220)
      final fillStroke = DrawingFloodFillHelper.createFillStroke(
        seed: const Offset(220, 220),
        color: const Color(0xFFFFCC00),
        opacity: 1.0,
        existingStrokes: [circle, dot],
        canvasSize: canvasSize,
      );

      final path = fillStroke.path;

      // Must fill inside the circle around the dot
      expect(path.contains(const Offset(220, 220)), isTrue, reason: 'Seed point must be filled');
      expect(path.contains(const Offset(200, 250)), isTrue, reason: 'Empty interior must be filled');

      // Must NOT fill the interior dot!
      expect(path.contains(const Offset(160, 160)), isFalse, reason: 'Inner dot must be excluded from fill');
      // Outside the circle must also be false
      expect(path.contains(const Offset(50, 50)), isFalse, reason: 'Outside circle must be excluded');
    });

    test('Fill inside a circle with multiple inner dots and spots preserves all islands', () {
      final circle = DrawingStroke(
        id: 'circle_outer',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 4.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(300, 300)),
        ],
      );

      // Eye 1 (dot at 160, 170)
      final eye1 = DrawingStroke(
        id: 'eye1',
        tool: DrawingToolType.pen,
        color: const Color(0xFF000000),
        strokeWidth: 8.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(160, 170)),
        ],
      );

      // Eye 2 (dot at 240, 170)
      final eye2 = DrawingStroke(
        id: 'eye2',
        tool: DrawingToolType.pen,
        color: const Color(0xFF000000),
        strokeWidth: 8.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(240, 170)),
        ],
      );

      // Inner stroke / spot (small stroke near 200, 230)
      final spot = DrawingStroke(
        id: 'spot',
        tool: DrawingToolType.marker,
        color: const Color(0xFF000000),
        strokeWidth: 6.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(195, 230)),
          DrawingPoint(offset: const Offset(205, 230)),
        ],
      );

      // Seed in empty forehead area
      final fillStroke = DrawingFloodFillHelper.createFillStroke(
        seed: const Offset(200, 140),
        color: const Color(0xFFFFE0BD),
        opacity: 1.0,
        existingStrokes: [circle, eye1, eye2, spot],
        canvasSize: canvasSize,
      );

      final path = fillStroke.path;

      // Forehead and cheeks filled
      expect(path.contains(const Offset(200, 140)), isTrue);
      expect(path.contains(const Offset(200, 180)), isTrue);
      expect(path.contains(const Offset(200, 260)), isTrue);

      // Both eyes and spot must NOT be painted over
      expect(path.contains(const Offset(160, 170)), isFalse, reason: 'Eye 1 must be left unpainted');
      expect(path.contains(const Offset(240, 170)), isFalse, reason: 'Eye 2 must be left unpainted');
      expect(path.contains(const Offset(200, 230)), isFalse, reason: 'Mouth/spot must be left unpainted');
    });

    test('Fill inside a circle with an inner circle (inner ring/donut) excludes the inner circle', () {
      // Outer circle: (100, 100) to (300, 300) -> center (200, 200), radius 100
      final outer = DrawingStroke(
        id: 'outer_c',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 3.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(300, 300)),
        ],
      );

      // Inner circle: (180, 180) to (220, 220) -> center (200, 200), radius 20
      final inner = DrawingStroke(
        id: 'inner_c',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 3.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(180, 180)),
          DrawingPoint(offset: const Offset(220, 220)),
        ],
      );

      // Tap in ring between outer and inner circle (at 200, 140)
      final fill = DrawingFloodFillHelper.createFillStroke(
        seed: const Offset(200, 140),
        color: const Color(0xFF3388FF),
        opacity: 1.0,
        existingStrokes: [outer, inner],
        canvasSize: canvasSize,
      );

      expect(fill.path.contains(const Offset(200, 140)), isTrue, reason: 'Ring area must be filled');
      expect(fill.path.contains(const Offset(200, 200)), isFalse, reason: 'Inner circle must NOT be painted');
    });

    test('Tap directly ON an inner spot fills the spot itself, not the outer circle', () {
      final outer = DrawingStroke(
        id: 'outer_c',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 3.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(300, 300)),
        ],
      );

      // Inner circle spot
      final spot = DrawingStroke(
        id: 'spot_c',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 3.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(180, 180)),
          DrawingPoint(offset: const Offset(220, 220)),
        ],
      );

      // Tap directly INSIDE the spot (at 200, 200)
      final fill = DrawingFloodFillHelper.createFillStroke(
        seed: const Offset(200, 200),
        color: const Color(0xFFFF0000),
        opacity: 1.0,
        existingStrokes: [outer, spot],
        canvasSize: canvasSize,
      );

      // Only the spot should be filled, not the surrounding outer circle
      expect(fill.path.contains(const Offset(200, 200)), isTrue);
      expect(fill.path.contains(const Offset(200, 140)), isFalse, reason: 'Outer circle background must NOT be filled');
    });

    test('DrawingController floodFill respects islands and preserves points serialization', () {
      final controller = DrawingController();
      controller.setCanvasSize(canvasSize);

      final circle = DrawingStroke(
        id: 'c_ext',
        tool: DrawingToolType.circle,
        color: const Color(0xFF000000),
        strokeWidth: 4.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(100, 100)),
          DrawingPoint(offset: const Offset(300, 300)),
        ],
      );
      final dot = DrawingStroke(
        id: 'dot_int',
        tool: DrawingToolType.pen,
        color: const Color(0xFF000000),
        strokeWidth: 12.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(200, 200)),
        ],
      );

      controller.addDirectStroke(circle);
      controller.addDirectStroke(dot);

      controller.selectTool(DrawingToolType.bucketFill);
      controller.setColor(const Color(0xFF00FF00));
      controller.startStroke(const Offset(200, 250)); // tap outside the dot

      expect(controller.activeLayer.strokes.length, equals(3));
      final fillStroke = controller.activeLayer.strokes.last;
      expect(fillStroke.tool, equals(DrawingToolType.bucketFill));

      // Check fill path
      expect(fillStroke.path.contains(const Offset(200, 250)), isTrue);
      expect(fillStroke.path.contains(const Offset(200, 200)), isFalse, reason: 'Dot must not be painted');

      // Recreate stroke from its points (simulating JSON serialization roundtrip)
      final restoredStroke = DrawingStroke(
        id: fillStroke.id,
        tool: fillStroke.tool,
        color: fillStroke.color,
        strokeWidth: fillStroke.strokeWidth,
        opacity: fillStroke.opacity,
        points: fillStroke.points,
      );

      expect(restoredStroke.path.contains(const Offset(200, 250)), isTrue);
      expect(restoredStroke.path.contains(const Offset(200, 200)), isFalse, reason: 'Serialization must preserve cutout');
    });
  });
}
