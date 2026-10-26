import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';

void main() {
  group('Comic Critical Bugs Regression Tests', () {
    test('ComicPanel.copyWith allows clearing drawing when clearDrawing is true', () {
      final panel = ComicPanel(
        id: 'p1',
        normalizedRect: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.4),
        drawingProjectId: 'proj_123',
        drawingPngBase64: 'base64_data',
      );

      final cleared = panel.copyWith(
        drawingProjectId: null,
        drawingPngBase64: null,
        clearDrawing: true,
      );

      expect(cleared.drawingProjectId, isNull);
      expect(cleared.drawingPngBase64, isNull);
    });

    test('ComicController.setPanelDrawing with null clears the drawing from the panel', () {
      final controller = ComicController(blankPage: true);
      controller.addPanel();
      final panelId = controller.activePage.panels.first.id;

      controller.setPanelDrawing(panelId, 'proj_123', 'fake_data');
      expect(controller.selectedPanel!.drawingPngBase64, 'fake_data');

      controller.setPanelDrawing(panelId, null, null);
      expect(controller.selectedPanel!.drawingProjectId, isNull);
      expect(controller.selectedPanel!.drawingPngBase64, isNull);
    });

    test('ComicController exportPageToPng exports non-active page without error', () async {
      final controller = ComicController();
      controller.addPage();
      expect(controller.project.pages.length, 2);

      final pngBytes = await controller.exportPageToPng(0);
      expect(pngBytes, isNotNull);
      expect(pngBytes!.length, greaterThan(0));
    });
  });
}
