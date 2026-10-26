import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_history.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_panel_operations.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_bubble.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_color_palette.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_page.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_sticker.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_template.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_template_layouts.dart';
import 'package:furi_app/screens/herramientas/comic/painters/comic_panel_shape_helper.dart';

void main() {
  group('Comic Template Layouts Tests', () {
    test('Todos los 12 layouts clásicos generan paneles con rects válidos', () {
      expect(ComicTemplateType.values.length, 12);

      for (final type in ComicTemplateType.values) {
        final panels = ComicTemplateLayouts.generate(type);
        expect(panels.isNotEmpty, isTrue, reason: 'Layout ${type.name} debe tener paneles');
        for (final p in panels) {
          expect(p.normalizedRect.width, greaterThan(0));
          expect(p.normalizedRect.height, greaterThan(0));
          expect(p.normalizedRect.left, greaterThanOrEqualTo(0));
          expect(p.normalizedRect.right, lessThanOrEqualTo(1.05));
        }
      }
    });
  });

  group('Comic Panel Shapes and Geometry Tests', () {
    test('ComicPanelShapeHelper genera Path válido para todas las formas', () {
      const rect = Rect.fromLTWH(10, 20, 200, 150);

      for (final shape in ComicPanelShape.values) {
        final panel = ComicPanel(
          id: 'test_${shape.name}',
          normalizedRect: const Rect.fromLTWH(0, 0, 1, 1),
          panelShape: shape,
          skewX: 0.1,
          rotation: 0.05,
          borderRadius: 8.0,
        );

        final path = ComicPanelShapeHelper.getPanelPath(rect, panel);
        final bounds = path.getBounds();
        expect(bounds.isEmpty, isFalse, reason: 'Shape ${shape.name} no debe generar path vacío');
        expect(bounds.width, greaterThan(0));
        expect(bounds.height, greaterThan(0));
      }
    });

    test('ComicPanel serialización preserva formas, rotación, skew y borde', () {
      final panel = ComicPanel(
        id: 'panel_shonen',
        normalizedRect: const Rect.fromLTWH(0.05, 0.05, 0.9, 0.45),
        panelShape: ComicPanelShape.slantedRight,
        rotation: 0.12,
        skewX: -0.08,
        borderRadius: 16.0,
        backgroundColor: const Color(0xFF1E1E2E),
        borderColor: const Color(0xFFFF5555),
        borderWidth: 4.0,
      );

      final map = panel.toMap();
      final restored = ComicPanel.fromMap(map);

      expect(restored.id, 'panel_shonen');
      expect(restored.panelShape, ComicPanelShape.slantedRight);
      expect(restored.rotation, 0.12);
      expect(restored.skewX, -0.08);
      expect(restored.borderRadius, 16.0);
      expect(restored.backgroundColor, const Color(0xFF1E1E2E));
      expect(restored.borderColor, const Color(0xFFFF5555));
      expect(restored.borderWidth, 4.0);
    });

    test('ComicPanelOperations divide paneles vertical y horizontalmente', () {
      final basePanel = ComicPanel(
        id: 'p_split',
        normalizedRect: const Rect.fromLTWH(0.1, 0.2, 0.8, 0.6),
      );

      final page = ComicPage(
        id: 'pg_split',
        pageNumber: 1,
        panels: [basePanel],
        bubbles: [],
        sfxStickers: [],
      );

      final resultV = ComicPanelOperations.splitPanel(page, 'p_split', vertical: true);
      expect(resultV, isNotNull);
      final (pageV, newIdV) = resultV!;
      expect(pageV.panels.length, 2);
      expect(newIdV.isNotEmpty, isTrue);

      final resultH = ComicPanelOperations.splitPanel(page, 'p_split', vertical: false);
      expect(resultH, isNotNull);
      final (pageH, newIdH) = resultH!;
      expect(pageH.panels.length, 2);
      expect(newIdH.isNotEmpty, isTrue);
    });
  });

  group('Comic Bubble Extended Features Tests', () {
    test('ComicBubble serializa rotación y cola correctamente', () {
      final bubble = ComicBubble(
        id: 'bubble_rotate',
        type: ComicBubbleType.whisperDotted,
        text: 'Murmullo secreto...',
        rotation: 0.25,
        tailDirection: ComicTailDirection.left,
        tailX: 15.0,
        tailY: 40.0,
        fontFamily: 'Bangers',
        borderWidth: 3.5,
      );

      final map = bubble.toMap();
      final restored = ComicBubble.fromMap(map);

      expect(restored.id, 'bubble_rotate');
      expect(restored.type, ComicBubbleType.whisperDotted);
      expect(restored.rotation, 0.25);
      expect(restored.tailDirection, ComicTailDirection.left);
      expect(restored.tailX, 15.0);
      expect(restored.tailY, 40.0);
      expect(restored.fontFamily, 'Bangers');
      expect(restored.borderWidth, 3.5);
    });
  });

  group('Comic Sticker & SFX Styles Tests', () {
    test('ComicSticker soporta estilos gráficos de SFX y serialización', () {
      for (final style in ComicSfxStyle.values) {
        expect(style.label.isNotEmpty, isTrue);
      }

      final sticker = ComicSticker(
        id: 'sfx_3d',
        text: '¡¡SMASH!!',
        sfxStyle: ComicSfxStyle.extruded3D,
        fontFamily: 'Permanent Marker',
        fontSize: 36,
        color: const Color(0xFFFFCC00),
        rotation: -0.15,
        scale: 1.8,
      );

      final map = sticker.toMap();
      final restored = ComicSticker.fromMap(map);

      expect(restored.id, 'sfx_3d');
      expect(restored.sfxStyle, ComicSfxStyle.extruded3D);
      expect(restored.fontFamily, 'Permanent Marker');
      expect(restored.fontSize, 36);
      expect(restored.color, const Color(0xFFFFCC00));
      expect(restored.rotation, -0.15);
      expect(restored.scale, 1.8);
    });
  });

  group('Comic History & Palettes Tests', () {
    test('ComicHistory maneja snapshot undo y redo', () {
      final history = ComicHistory();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);

      final page1 = ComicPage(
        id: 'pg1',
        pageNumber: 1,
        panels: ComicTemplateType.singleFull.createPanels(),
        bubbles: [],
        sfxStickers: [],
      );
      final page2 = page1.copyWith(
        panels: ComicTemplateType.twoHorizontal.createPanels(),
      );

      history.recordSnapshot(page1);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);

      final undoPage = history.undo(page2);
      expect(undoPage, isNotNull);
      expect(undoPage!.panels.length, 1);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);

      final redoPage = history.redo(undoPage);
      expect(redoPage, isNotNull);
      expect(redoPage!.panels.length, 2);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('ComicColorPalettes contiene 7 paletas legendarias completas', () {
      expect(ComicColorPalettes.all.length, 7);
      for (final pal in ComicColorPalettes.all) {
        expect(pal.name.isNotEmpty, isTrue);
        expect(pal.origin.isNotEmpty, isTrue);
        expect(pal.colors.length, greaterThanOrEqualTo(4));
      }
    });
  });
}
