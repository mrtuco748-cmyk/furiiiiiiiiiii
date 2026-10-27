import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_bubble.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_page.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_project.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_template.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_chapter_card.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_page_thumbnail.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_project.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';

void main() {
  group('Preservación de grosor al intercalar entre lápiz y borrador', () {
    test('El grosor del lápiz y del borrador no se resetea al alternar entre ellos', () {
      final controller = DrawingController();

      // Configurar grosor personalizado para lápiz/pluma (pen)
      controller.selectTool(DrawingToolType.pen);
      controller.setStrokeWidth(14.0);
      controller.setOpacity(0.85);
      expect(controller.strokeWidth, 14.0);
      expect(controller.strokeOpacity, 0.85);

      // Cambiar a borrador
      controller.selectTool(DrawingToolType.eraser);
      expect(controller.selectedTool, DrawingToolType.eraser);
      // Configurar grosor personalizado para el borrador
      controller.setStrokeWidth(48.0);
      expect(controller.strokeWidth, 48.0);

      // Regresar a lápiz: NO debe resetearse a defaultWidth (3.0), debe recordar 14.0
      controller.selectTool(DrawingToolType.pen);
      expect(controller.selectedTool, DrawingToolType.pen);
      expect(controller.strokeWidth, 14.0);
      expect(controller.strokeOpacity, 0.85);

      // Regresar a borrador: NO debe resetearse a defaultWidth (24.0), debe recordar 48.0
      controller.selectTool(DrawingToolType.eraser);
      expect(controller.selectedTool, DrawingToolType.eraser);
      expect(controller.strokeWidth, 48.0);

      // Probar alternancia mediante toggleTool
      controller.toggleTool(DrawingToolType.eraser);
      expect(controller.selectedTool, DrawingToolType.pen);
      expect(controller.strokeWidth, 14.0);

      controller.toggleTool(DrawingToolType.eraser);
      expect(controller.selectedTool, DrawingToolType.eraser);
      expect(controller.strokeWidth, 48.0);
    });

    test('Múltiples herramientas conservan su grosor específico de forma independiente', () {
      final controller = DrawingController();

      controller.selectTool(DrawingToolType.pencil);
      controller.setStrokeWidth(7.5);

      controller.selectTool(DrawingToolType.marker);
      controller.setStrokeWidth(22.0);

      controller.selectTool(DrawingToolType.highlighter);
      controller.setStrokeWidth(35.0);

      controller.selectTool(DrawingToolType.eraser);
      controller.setStrokeWidth(55.0);

      // Verificar que cada herramienta mantiene su grosor individual
      controller.selectTool(DrawingToolType.pencil);
      expect(controller.strokeWidth, 7.5);

      controller.selectTool(DrawingToolType.marker);
      expect(controller.strokeWidth, 22.0);

      controller.selectTool(DrawingToolType.highlighter);
      expect(controller.strokeWidth, 35.0);

      controller.selectTool(DrawingToolType.eraser);
      expect(controller.strokeWidth, 55.0);
    });

    test('DrawingController preserva thumbnailBase64 y title a través de toProject', () {
      final proj = DrawingProject(
        id: 'p1',
        title: 'Mi Gran Dibujo',
        canvasWidth: 1080,
        canvasHeight: 1080,
        thumbnailBase64: 'fake_thumb_base64_data',
        layers: [],
      );

      final controller = DrawingController(initialProject: proj);
      expect(controller.projectTitle, 'Mi Gran Dibujo');

      // toProject sin argumentos conserva la miniatura previa
      final exported1 = controller.toProject();
      expect(exported1.thumbnailBase64, 'fake_thumb_base64_data');
      expect(exported1.title, 'Mi Gran Dibujo');

      // Modificar título y verificar persistencia
      controller.setTitle('Título Actualizado');
      final exported2 = controller.toProject();
      expect(exported2.title, 'Título Actualizado');
      expect(exported2.thumbnailBase64, 'fake_thumb_base64_data');
    });
  });

  group('Previsualización de primera hoja en cómics', () {
    testWidgets('ComicPageThumbnail previsualiza vectorialmente la primera página cuando coverImageBase64 es null', (tester) async {
      final page = ComicPage(
        id: 'p1',
        pageNumber: 1,
        backgroundColor: Colors.white,
        panels: [
          ComicPanel(
            id: 'pan1',
            normalizedRect: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.4),
            borderColor: Colors.black,
            borderWidth: 2.0,
          ),
          ComicPanel(
            id: 'pan2',
            normalizedRect: const Rect.fromLTWH(0.1, 0.55, 0.8, 0.4),
            borderColor: Colors.black,
            borderWidth: 2.0,
          ),
        ],
        bubbles: [
          ComicBubble(
            id: 'b1',
            text: '¡Hola FURI!',
            x: 0.2,
            y: 0.2,
            width: 140,
            height: 70,
          ),
        ],
        sfxStickers: [],
      );

      final project = ComicProject(
        id: 'comic_test_1',
        title: 'Cómic de Prueba',
        pages: [page],
        coverImageBase64: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 280,
              child: ComicPageThumbnail(project: project),
            ),
          ),
        ),
      );

      // Debe renderizar el CustomPaint de ComicPagePainter para la primera hoja
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('ComicPageThumbnail despliega coverImageBase64 cuando existe', (tester) async {
      // 1x1 PNG transparente codificado en base64
      const transparent1x1Png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      final project = ComicProject(
        id: 'comic_test_2',
        title: 'Cómic Con Portada',
        pages: [
          ComicPage(id: 'p1', pageNumber: 1, panels: [], bubbles: [], sfxStickers: []),
        ],
        coverImageBase64: transparent1x1Png,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 280,
              child: ComicPageThumbnail(project: project),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('ComicChapterCard incluye thumbnail de primer hoja y botón de renombrar', (tester) async {
      bool renameCalled = false;
      bool deleteCalled = false;

      final project = ComicProject(
        id: 'comic_test_3',
        title: 'Capítulo Épico',
        pages: [
          ComicPage(
            id: 'p1',
            pageNumber: 1,
            panels: ComicTemplateType.fourKoma.createPanels(),
            bubbles: [],
            sfxStickers: [],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 260,
              child: ComicChapterCard(
                project: project,
                onTap: () {},
                onRename: () => renameCalled = true,
                onDelete: () => deleteCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Capítulo Épico'), findsOneWidget);
      expect(find.text('1 pág.'), findsOneWidget);
      expect(find.byType(ComicPageThumbnail), findsOneWidget);

      // Presionar el botón de renombrar
      final renameBtn = find.byIcon(Icons.edit_outlined);
      expect(renameBtn, findsOneWidget);
      await tester.tap(renameBtn);
      expect(renameCalled, isTrue);
      expect(deleteCalled, isFalse);
    });

    test('ComicController setCoverImage asigna la portada del proyecto correctamente', () {
      final controller = ComicController();
      expect(controller.project.coverImageBase64, isNull);

      controller.setCoverImage('test_cover_base64');
      expect(controller.project.coverImageBase64, 'test_cover_base64');
    });
  });
}
