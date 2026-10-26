import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_lasso_operations.dart';
import 'package:furi_app/screens/herramientas/dibujo/helpers/drawing_render_exporter.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/canvas_background_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_layer.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_point.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_stroke.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';

void main() {
  group('Drawing Critical Bugs Regression Tests', () {
    test('DrawingRenderExporter scales strokes according to canvasSize', () async {
      final stroke = DrawingStroke(
        id: 's1',
        tool: DrawingToolType.pen,
        color: const Color(0xFF000000),
        strokeWidth: 10.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(1000, 1000)),
          DrawingPoint(offset: const Offset(1100, 1100)),
        ],
      );
      final layer = DrawingLayer(id: 'l1', name: 'Layer 1', strokes: [stroke]);

      final bytes = await DrawingRenderExporter.exportToPng(
        layers: [layer],
        backgroundType: CanvasBackgroundType.blank,
        size: const Size(200, 200),
        canvasSize: const Size(2000, 2000),
      );

      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(0));
    });

    test('DrawingController cancelActiveStroke discards stroke without undoing past strokes', () {
      final controller = DrawingController();
      controller.startStroke(const Offset(100, 100));
      controller.endStroke();
      expect(controller.activeLayer.strokes.length, 1);
      expect(controller.canUndo, isTrue);

      controller.startStroke(const Offset(200, 200));
      expect(controller.activeStroke, isNotNull);

      controller.cancelActiveStroke();
      expect(controller.activeStroke, isNull);
      expect(controller.activeLayer.strokes.length, 1);
      expect(controller.canUndo, isTrue);
    });

    test('DrawingLassoOperations creates polygon fill and Lasso select detects shapes', () {
      final poly = [
        const Offset(10, 10),
        const Offset(100, 10),
        const Offset(100, 100),
        const Offset(10, 100),
      ];
      final fillStroke = DrawingLassoOperations.createPolygonFill(
        poly,
        const Color(0xFFFF0000),
        1.0,
      );
      expect(fillStroke.tool, DrawingToolType.bucketFill);
      expect(fillStroke.points.length, 4);

      final circleStroke = DrawingStroke(
        id: 'c1',
        tool: DrawingToolType.circle,
        color: const Color(0xFF0000FF),
        strokeWidth: 4.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(30, 30)),
          DrawingPoint(offset: const Offset(80, 80)),
        ],
      );

      final selection = DrawingLassoOperations.createSelection(
        poly,
        [circleStroke],
      );
      expect(selection, isNotNull);
      expect(selection!.selectedStrokeIds, contains('c1'));
    });

    test('DrawingController toProject and loadProject preserve canvas dimensions', () {
      final controller = DrawingController();
      controller.setCanvasSize(const Size(1200, 1697));

      final project = controller.toProject();
      expect(project.canvasWidth, 1200);
      expect(project.canvasHeight, 1697);

      final newController = DrawingController(initialProject: project);
      expect(newController.canvasWidth, 1200);
      expect(newController.canvasHeight, 1697);
    });
  });
}
