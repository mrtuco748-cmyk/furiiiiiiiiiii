import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_symmetry_mode.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/popovers/drawing_tools_popover.dart';

void main() {
  group('Drawing Pro Engine & Symmetry Tests', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController();
      controller.setCanvasSize(const Size(1000, 1000));
    });

    test('DrawingToolType nuevos tienen metadatos y helpers correctos', () {
      expect(DrawingToolType.trajectory.displayName, 'Trayectoria');
      expect(DrawingToolType.trajectory.isShape, isTrue);
      expect(DrawingToolType.trajectory.requiresDragVector, isTrue);

      expect(DrawingToolType.bucketFill.displayName, 'Rellenar');
      expect(DrawingToolType.bucketFill.isFill, isTrue);

      expect(DrawingToolType.gradient.displayName, 'Degradado');
      expect(DrawingToolType.gradient.isFill, isTrue);
      expect(DrawingToolType.gradient.requiresDragVector, isTrue);
    });

    test('DrawingSymmetryMode proyecta coordenadas adecuadamente', () {
      const canvasSize = Size(1000, 1000);
      const points = [Offset(200, 300)];

      // Vertical (cx = 500 => 2*500 - 200 = 800)
      final vProj = DrawingSymmetryMode.vertical.projectPoints(points, canvasSize);
      expect(vProj.length, 1);
      expect(vProj[0][0], const Offset(800, 300));

      // Horizontal (cy = 500 => 2*500 - 300 = 700)
      final hProj = DrawingSymmetryMode.horizontal.projectPoints(points, canvasSize);
      expect(hProj.length, 1);
      expect(hProj[0][0], const Offset(200, 700));

      // Radial4 (3 espejados)
      final rProj = DrawingSymmetryMode.radial4.projectPoints(points, canvasSize);
      expect(rProj.length, 3);
      expect(rProj[0][0], const Offset(800, 300));
      expect(rProj[1][0], const Offset(200, 700));
      expect(rProj[2][0], const Offset(800, 700));
    });

    test('DrawingController con simetría vertical duplica trazos en tiempo real', () {
      controller.setSymmetryMode(DrawingSymmetryMode.vertical);
      expect(controller.symmetryMode, DrawingSymmetryMode.vertical);

      controller.startStroke(const Offset(200, 300));
      expect(controller.activeStroke, isNotNull);
      expect(controller.activeMirroredStrokes.length, 1);
      expect(controller.activeMirroredStrokes[0].points.first.offset.dx, 800.0);

      controller.updateStroke(const Offset(220, 340));
      expect(controller.activeMirroredStrokes[0].points.last.offset.dx, closeTo(780.0, 10.0));

      controller.endStroke();
      // Ambos trazos (original y espejado) se guardan en la capa
      expect(controller.activeLayer.strokes.length, 2);

      // Deshacer atómico elimina ambos trazos simultáneamente
      controller.undo();
      expect(controller.activeLayer.strokes.isEmpty, isTrue);

      controller.redo();
      expect(controller.activeLayer.strokes.length, 2);
    });

    test('Herramientas geométricas realizan previsualización en vivo continua', () {
      controller.selectTool(DrawingToolType.line);
      controller.startStroke(const Offset(100, 100));

      controller.updateStroke(const Offset(150, 150));
      controller.updateStroke(const Offset(300, 300));

      // Para formas geométricas solo se preserva el punto inicial y el actual
      expect(controller.activeStroke!.points.length, 2);
      expect(controller.activeStroke!.points.last.offset, const Offset(300, 300));

      controller.endStroke();
      expect(controller.activeLayer.strokes.length, 1);
      expect(controller.activeLayer.strokes.first.tool, DrawingToolType.line);
    });

    test('Rellenar (floodFill) y Degradado (applyGradient) crean trazos en la capa activa', () {
      controller.floodFill(const Offset(50, 50), const Color(0xFF00D4FF));
      expect(controller.activeLayer.strokes.length, 1);
      expect(controller.activeLayer.strokes.first.tool, DrawingToolType.bucketFill);

      controller.applyGradient(const Offset(0, 0), const Offset(100, 100), const Color(0xFFFFDE59));
      expect(controller.activeLayer.strokes.length, 2);
      expect(controller.activeLayer.strokes.last.tool, DrawingToolType.gradient);
    });

    test('Cámara: Volteo de lienzo y bloqueo de rotación funcionan', () {
      expect(controller.isFlippedHorizontal, isFalse);
      controller.flipCanvasHorizontal();
      expect(controller.isFlippedHorizontal, isTrue);

      expect(controller.isFlippedVertical, isFalse);
      controller.flipCanvasVertical();
      expect(controller.isFlippedVertical, isTrue);

      expect(controller.isRotationLocked, isFalse);
      controller.toggleRotationLock();
      expect(controller.isRotationLocked, isTrue);
    });

    testWidgets('DrawingToolsPopover conecta herramientas Rellenar, Degradado y Simetría', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingToolsPopover(
              controller: controller,
              onResetZoom: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Rellenar'));
      await tester.pump();
      expect(controller.selectedTool, DrawingToolType.bucketFill);

      await tester.tap(find.text('Degradado'));
      await tester.pump();
      expect(controller.selectedTool, DrawingToolType.gradient);

      await tester.tap(find.text('Trayectoria'));
      await tester.pump();
      expect(controller.selectedTool, DrawingToolType.trajectory);

      await tester.tap(find.text('Vertical'));
      await tester.pump();
      expect(controller.symmetryMode, DrawingSymmetryMode.vertical);
    });

    test('DrawingLayerOperations gestiona capas, visibilidad y opacidad correctamente', () {
      expect(controller.layers.length, 1);
      controller.addLayer(name: 'Boceto');
      expect(controller.layers.length, 2);
      expect(controller.activeLayerIndex, 1);
      expect(controller.activeLayer.name, 'Boceto');

      controller.toggleLayerVisibility(1);
      expect(controller.layers[1].isVisible, isFalse);

      controller.setLayerOpacity(1, 0.45);
      expect(controller.layers[1].opacity, 0.45);

      final removed = controller.removeLayer(1);
      expect(removed, isTrue);
      expect(controller.layers.length, 1);
    });
  });
}
