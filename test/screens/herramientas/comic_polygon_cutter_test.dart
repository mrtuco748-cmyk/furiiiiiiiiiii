import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/helpers/comic_polygon_cutter.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';
import 'package:furi_app/screens/herramientas/comic/painters/comic_panel_shape_helper.dart';

void main() {
  group('ComicPolygonCutter Tests', () {
    late ComicPanel squarePanel;

    setUp(() {
      squarePanel = ComicPanel(
        id: 'test_rect',
        normalizedRect: const Rect.fromLTWH(0.10, 0.10, 0.80, 0.80),
      );
    });

    test('slicePanel corta viñeta en diagonal creando dos polígonos complementarios', () {
      // Corte diagonal desde (0.10, 0.10) hasta (0.90, 0.90)
      final result = ComicPolygonCutter.slicePanel(
        squarePanel,
        const Offset(0.10, 0.10),
        const Offset(0.90, 0.90),
        gutter: 0.01,
      );

      expect(result, isNotNull);
      final (p1, p2) = result!;

      // Ambos deben poseer polígonos válidos con al menos 3 vértices
      expect(p1.polygonPoints, isNotNull);
      expect(p1.polygonPoints!.length, greaterThanOrEqualTo(3));
      expect(p2.polygonPoints, isNotNull);
      expect(p2.polygonPoints!.length, greaterThanOrEqualTo(3));

      // Las coordenadas de los polígonos normalizados deben estar en [0..1]
      for (final pt in p1.polygonPoints!) {
        expect(pt.dx, inInclusiveRange(-0.01, 1.01));
        expect(pt.dy, inInclusiveRange(-0.01, 1.01));
      }
      for (final pt in p2.polygonPoints!) {
        expect(pt.dx, inInclusiveRange(-0.01, 1.01));
        expect(pt.dy, inInclusiveRange(-0.01, 1.01));
      }
    });

    test('slicePanel consecutivo permite cortar un panel poligonal resultante de un corte previo', () {
      // Primer corte diagonal
      final res1 = ComicPolygonCutter.slicePanel(
        squarePanel,
        const Offset(0.10, 0.10),
        const Offset(0.90, 0.90),
      );
      expect(res1, isNotNull);
      final (polyPart1, polyPart2) = res1!;

      // Segundo corte diagonal sobre la primera parte
      final res2 = ComicPolygonCutter.slicePanel(
        polyPart1,
        const Offset(0.10, 0.90),
        const Offset(0.90, 0.10),
      );

      expect(res2, isNotNull);
      final (subPartA, subPartB) = res2!;
      expect(subPartA.polygonPoints, isNotNull);
      expect(subPartB.polygonPoints, isNotNull);
      expect(subPartA.polygonPoints!.length, greaterThanOrEqualTo(3));
      expect(subPartB.polygonPoints!.length, greaterThanOrEqualTo(3));
    });

    test('ComicController.slicePanelWithLine corta en diagonal y añade comando al historial de deshacer', () {
      final controller = ComicController(blankPage: true);
      controller.addPanelFromRect(const Rect.fromLTWH(0.10, 0.10, 0.80, 0.80));
      final panelId = controller.activePage.panels.first.id;

      // Corte diagonal
      controller.slicePanelWithLine(
        panelId,
        const Offset(0.15, 0.20),
        const Offset(0.85, 0.80),
      );

      expect(controller.activePage.panels.length, 2);
      expect(controller.activePage.panels[0].polygonPoints, isNotNull);
      expect(controller.activePage.panels[1].polygonPoints, isNotNull);
      expect(controller.canUndo, isTrue);

      // Deshacer restaura el panel original rectangular sin polygonPoints
      controller.undo();
      expect(controller.activePage.panels.length, 1);
      expect(controller.activePage.panels.first.polygonPoints, isNull);

      // Rehacer vuelve a aplicar el corte diagonal
      controller.redo();
      expect(controller.activePage.panels.length, 2);
      expect(controller.activePage.panels[0].polygonPoints, isNotNull);
    });

    test('ComicPanelShapeHelper genera Path triangular/trapezoidal para panel con polygonPoints', () {
      final polyPanel = ComicPanel(
        id: 'poly_test',
        normalizedRect: const Rect.fromLTWH(0.10, 0.10, 0.40, 0.40),
        polygonPoints: const [
          Offset(0.0, 0.0),
          Offset(1.0, 0.0),
          Offset(0.0, 1.0),
        ],
      );

      const panelRect = Rect.fromLTWH(100, 100, 200, 200);
      final path = ComicPanelShapeHelper.getPanelPath(panelRect, polyPanel);

      expect(path, isNotNull);
      // Punto dentro del triángulo superior-izquierdo (120, 120) -> en coords normalizadas (0.1, 0.1) dentro de triángulo
      expect(path.contains(const Offset(120, 120)), isTrue);
      // Punto fuera del triángulo (190, 190) -> (0.45, 0.45) fuera de hipotenusa x + y <= 1
      expect(path.contains(const Offset(290, 290)), isFalse);
    });

    test('slicePanel rechaza corte degenerado con longitud cero', () {
      final result = ComicPolygonCutter.slicePanel(
        squarePanel,
        const Offset(0.50, 0.50),
        const Offset(0.50, 0.50),
      );
      expect(result, isNull);
    });
  });
}
