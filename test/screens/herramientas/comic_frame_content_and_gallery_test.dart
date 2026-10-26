import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_interaction_mode.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_drawing_thumbnail.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_editor_gesture_helper.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/canvas_background_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_layer.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_point.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_project.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_stroke.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_symmetry_mode.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/painters/drawing_panel_guide_painter.dart';

void main() {
  group('Comic Framing, Gallery & Drawing Enhancements Tests', () {
    test('ComicInteractionMode.frameContent conmutación y activación', () {
      final controller = ComicController(blankPage: true);
      controller.addPanel();
      expect(controller.interactionMode.isNormal, isTrue);

      controller.setInteractionMode(ComicInteractionMode.frameContent);
      expect(controller.interactionMode.isFrameContent, isTrue);
      expect(controller.interactionMode, ComicInteractionMode.frameContent);
    });

    test('ComicEditorGestureHelper.applyFramePan desplaza el contenido de la viñeta', () {
      final controller = ComicController(blankPage: true);
      controller.addPanel();
      final panelId = controller.activePage.panels.first.id;
      controller.selectPanel(panelId);

      controller.setPanelTransform(panelId, dx: 10.0, dy: -5.0, scale: 1.2);
      expect(controller.selectedPanel!.offsetX, 10.0);
      expect(controller.selectedPanel!.offsetY, -5.0);

      // Simular arrastre en modo encuadre
      final details = DragUpdateDetails(
        globalPosition: const Offset(100, 100),
        delta: const Offset(15.0, 20.0),
      );

      ComicEditorGestureHelper.applyFramePan(controller: controller, details: details);
      expect(controller.selectedPanel!.offsetX, 25.0);
      expect(controller.selectedPanel!.offsetY, 15.0);
    });

    testWidgets('ComicDrawingThumbnail renderiza preview vectorial si thumbnailBase64 es nulo', (tester) async {
      final stroke = DrawingStroke(
        id: 's1',
        tool: DrawingToolType.pen,
        color: const Color(0xFFFF0000),
        strokeWidth: 4.0,
        opacity: 1.0,
        points: [
          DrawingPoint(offset: const Offset(10, 10)),
          DrawingPoint(offset: const Offset(50, 50)),
        ],
      );

      final project = DrawingProject(
        id: 'test_proj',
        title: 'Boceto Manga',
        thumbnailBase64: null,
        layers: [
          DrawingLayer(id: 'l1', name: 'Tinta', strokes: [stroke]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 120,
              child: ComicDrawingThumbnail(project: project),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(ComicDrawingThumbnail),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    test('DrawingController duplica capa activa con todos sus trazos', () {
      final controller = DrawingController();
      controller.startStroke(const Offset(50, 50));
      controller.updateStroke(const Offset(60, 60));
      controller.endStroke();

      expect(controller.layers.length, 1);
      expect(controller.activeLayer.strokes.length, 1);

      controller.duplicateActiveLayer();
      expect(controller.layers.length, 2);
      expect(controller.activeLayer.strokes.length, 1);
      expect(controller.activeLayer.name, contains('Copia'));
    });

    test('DrawingController rota capa activa 90 grados alrededor del centro', () {
      final controller = DrawingController();
      controller.setCanvasSize(const Size(1000, 1000));
      controller.startStroke(const Offset(500, 200)); // Punto en el eje vertical superior
      controller.endStroke();

      final origPt = controller.activeLayer.strokes.first.points.first.offset;
      expect(origPt.dx, 500.0);
      expect(origPt.dy, 200.0);

      controller.rotateActiveLayer90();
      final rotPt = controller.activeLayer.strokes.first.points.first.offset;
      // Rotado 90° horario alrededor de (500, 500):
      // (500, 200) pasa a (800, 500)
      expect(rotPt.dx, closeTo(800.0, 0.01));
      expect(rotPt.dy, closeTo(500.0, 0.01));
    });

    test('DrawingController invierte colores de capa activa', () {
      final controller = DrawingController();
      controller.setColor(const Color(0xFF000000)); // Negro
      controller.startStroke(const Offset(10, 10));
      controller.endStroke();

      expect(controller.activeLayer.strokes.first.color.r, 0.0);

      controller.invertActiveLayerColors();
      final invColor = controller.activeLayer.strokes.first.color;
      // Invertido de negro es blanco (r=1.0, g=1.0, b=1.0)
      expect((invColor.r * 255).round(), 255);
      expect((invColor.g * 255).round(), 255);
      expect((invColor.b * 255).round(), 255);
    });

    test('DrawingController cicla tramas y fondos de lienzo', () {
      final controller = DrawingController();
      expect(controller.backgroundType, CanvasBackgroundType.blank);

      controller.cycleBackgroundPattern();
      expect(controller.backgroundType, CanvasBackgroundType.grid);

      controller.cycleBackgroundPattern();
      expect(controller.backgroundType, CanvasBackgroundType.dots);

      controller.cycleBackgroundPattern();
      expect(controller.backgroundType, CanvasBackgroundType.dark);

      controller.cycleBackgroundPattern();
      expect(controller.backgroundType, CanvasBackgroundType.blank);
    });

    test('DrawingSymmetryMode.kaleidoscope proyecta 7 trazos simétricos en 8 cuadrantes', () {
      const mode = DrawingSymmetryMode.kaleidoscope;
      const canvasSize = Size(1000, 1000);
      final pts = [const Offset(600, 700)];

      final projections = mode.projectPoints(pts, canvasSize);
      expect(projections.length, 7);

      for (final set in projections) {
        expect(set.length, 1);
        expect(set.first.dx, inInclusiveRange(0.0, 1000.0));
        expect(set.first.dy, inInclusiveRange(0.0, 1000.0));
      }
    });

    test('DrawingPanelGuidePainter crea y repinta máscara de recorte para panel de cómic', () {
      const painter1 = DrawingPanelGuidePainter(
        shape: ComicPanelShape.slantedRight,
        visible: true,
      );
      const painter2 = DrawingPanelGuidePainter(
        shape: ComicPanelShape.rectangle,
        visible: true,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter1), isFalse);
    });
  });
}
