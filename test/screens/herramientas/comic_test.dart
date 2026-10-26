import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_bubble.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_page.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_project.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_sticker.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_template.dart';

void main() {
  group('Comic Models & Templates', () {
    test('ComicBubble serialización y estilos', () {
      final bubble = ComicBubble(
        id: 'b1',
        type: ComicBubbleType.screamSpiky,
        text: '¡¡SHOUT!!',
        x: 0.3,
        y: 0.7,
        fontFamily: 'Permanent Marker',
        fontSize: 24,
      );

      expect(bubble.type.displayName, 'Grito / Acción');
      expect(bubble.type.label, 'Grito / Acción');
      expect(bubble.type.icon, Icons.flash_on);

      final map = bubble.toMap();
      final from = ComicBubble.fromMap(map);
      expect(from.id, 'b1');
      expect(from.type, ComicBubbleType.screamSpiky);
      expect(from.text, '¡¡SHOUT!!');
      expect(from.fontFamily, 'Permanent Marker');
    });

    test('ComicBubble cubre todos los tipos', () {
      for (final type in ComicBubbleType.values) {
        expect(type.displayName.isNotEmpty, isTrue);
        expect(type.label.isNotEmpty, isTrue);
        expect(type.icon, isNotNull);
      }
    });

    test('ComicPanel transformaciones y serialización', () {
      final panel = ComicPanel(
        id: 'p1',
        normalizedRect: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.4),
        scale: 1.5,
        offsetX: 10,
        offsetY: -20,
      );

      final map = panel.toMap();
      final from = ComicPanel.fromMap(map);
      expect(from.id, 'p1');
      expect(from.scale, 1.5);
      expect(from.offsetX, 10);
      expect(from.offsetY, -20);
    });

    test('ComicTemplateType genera la cantidad correcta de paneles', () {
      expect(ComicTemplateType.singleFull.createPanels().length, 1);
      expect(ComicTemplateType.twoHorizontal.createPanels().length, 2);
      expect(ComicTemplateType.threeTiers.createPanels().length, 3);
      expect(ComicTemplateType.fourKoma.createPanels().length, 4);
      expect(ComicTemplateType.sixGrid.createPanels().length, 6);

      for (final t in ComicTemplateType.values) {
        expect(t.displayName.isNotEmpty, isTrue);
        expect(t.description.isNotEmpty, isTrue);
      }
    });

    test('ComicSticker serialización', () {
      final sticker = ComicSticker(
        id: 's1',
        text: '¡¡BOOM!!',
        x: 0.5,
        y: 0.5,
        rotation: 0.2,
        scale: 1.2,
      );

      final map = sticker.toMap();
      final from = ComicSticker.fromMap(map);
      expect(from.id, 's1');
      expect(from.text, '¡¡BOOM!!');
      expect(from.rotation, 0.2);
    });

    test('ComicProject serialización completa JSON', () {
      final project = ComicProject(
        id: 'c1',
        title: 'Manga de Prueba',
        pages: [
          ComicPage(
            id: 'page_1',
            pageNumber: 1,
            panels: ComicTemplateType.fourKoma.createPanels(),
            bubbles: [
              ComicBubble(id: 'b1', text: 'Hola'),
            ],
            sfxStickers: [
              ComicSticker(id: 's1', text: '¡¡ZAP!!'),
            ],
          ),
        ],
      );

      final jsonStr = project.toJson();
      final fromJson = ComicProject.fromJson(jsonStr);
      expect(fromJson.id, 'c1');
      expect(fromJson.title, 'Manga de Prueba');
      expect(fromJson.pages.length, 1);
      expect(fromJson.pages.first.panels.length, 4);
      expect(fromJson.pages.first.bubbles.length, 1);
      expect(fromJson.pages.first.sfxStickers.length, 1);
    });
  });

  group('ComicController State Management', () {
    late ComicController controller;

    setUp(() {
      controller = ComicController();
    });

    test('inicializa con 1 página y 4 paneles por defecto', () {
      expect(controller.project.pages.length, 1);
      expect(controller.activePage.panels.length, 4);
      expect(controller.activePageIndex, 0);
    });

    test('agrega, navega y elimina páginas', () {
      controller.addPage(template: ComicTemplateType.twoHorizontal);
      expect(controller.project.pages.length, 2);
      expect(controller.activePageIndex, 1);
      expect(controller.activePage.panels.length, 2);

      controller.goToPage(0);
      expect(controller.activePageIndex, 0);

      final removed = controller.removePage(1);
      expect(removed, isTrue);
      expect(controller.project.pages.length, 1);

      // No debe permitir eliminar la última página
      final cantRemove = controller.removePage(0);
      expect(cantRemove, isFalse);
    });

    test('gestiona viñetas: selección y dibujo', () {
      final firstPanelId = controller.activePage.panels.first.id;
      controller.selectPanel(firstPanelId);
      expect(controller.selectedPanelId, firstPanelId);
      expect(controller.selectedPanel, isNotNull);

      controller.setPanelDrawing(firstPanelId, 'draw_1', 'fake_base64');
      final updated = controller.activePage.panels.firstWhere((p) => p.id == firstPanelId);
      expect(updated.drawingProjectId, 'draw_1');
      expect(updated.drawingPngBase64, 'fake_base64');

      controller.setPanelTransform(firstPanelId, scale: 2.0, dx: 15, dy: -5);
      final transformed = controller.activePage.panels.firstWhere((p) => p.id == firstPanelId);
      expect(transformed.scale, 2.0);
      expect(transformed.offsetX, 15);
      expect(transformed.offsetY, -5);
    });

    test('gestiona globos de diálogo: agregar, mover, actualizar, borrar', () {
      controller.addBubble(type: ComicBubbleType.thoughtCloud, text: 'Pensando...');
      expect(controller.activePage.bubbles.length, 1);
      final bubble = controller.activePage.bubbles.first;
      expect(bubble.text, 'Pensando...');
      expect(controller.selectedBubbleId, bubble.id);

      controller.moveBubble(bubble.id, 0.7, 0.8);
      expect(controller.activePage.bubbles.first.x, 0.7);
      expect(controller.activePage.bubbles.first.y, 0.8);

      controller.updateBubble(bubble.copyWith(text: 'Pensando más...'));
      expect(controller.activePage.bubbles.first.text, 'Pensando más...');

      controller.deleteBubble(bubble.id);
      expect(controller.activePage.bubbles.isEmpty, isTrue);
      expect(controller.selectedBubbleId, isNull);
    });

    test('gestiona onomatopeyas SFX', () {
      controller.addSfx('¡¡KABOOM!!');
      expect(controller.activePage.sfxStickers.length, 1);
      final sfx = controller.activePage.sfxStickers.first;
      expect(sfx.text, '¡¡KABOOM!!');

      controller.moveSfx(sfx.id, 0.2, 0.3);
      expect(controller.activePage.sfxStickers.first.x, 0.2);

      controller.deleteSfx(sfx.id);
      expect(controller.activePage.sfxStickers.isEmpty, isTrue);
    });

    test('cambia plantilla de la página activa', () {
      controller.applyTemplateToActivePage(ComicTemplateType.sixGrid);
      expect(controller.activePage.panels.length, 6);
    });
  });
}
