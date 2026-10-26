import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/comic_reader_screen.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_page.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_project.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_layers_dock.dart';

void main() {
  group('ComicReaderScreen Tests', () {
    testWidgets('Renders 1-page comic without Slider crash (min < max guard)', (tester) async {
      final project = ComicProject(
        id: 'c1',
        title: 'Cómic de 1 Página',
        pages: [
          ComicPage(id: 'p1', pageNumber: 1, panels: [], bubbles: [], sfxStickers: []),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComicReaderScreen(project: project),
        ),
      );

      expect(find.text('Cómic de 1 Página'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      // Slider must not exist when totalPages <= 1 to avoid min == max assertion
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('Renders multi-page comic with interactive Slider', (tester) async {
      final project = ComicProject(
        id: 'c2',
        title: 'Cómic Multi-Página',
        pages: [
          ComicPage(id: 'p1', pageNumber: 1, panels: [], bubbles: [], sfxStickers: []),
          ComicPage(id: 'p2', pageNumber: 2, panels: [], bubbles: [], sfxStickers: []),
          ComicPage(id: 'p3', pageNumber: 3, panels: [], bubbles: [], sfxStickers: []),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComicReaderScreen(project: project),
        ),
      );

      expect(find.text('Cómic Multi-Página'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Toggle controls by tapping
      await tester.tap(find.byType(PageView));
      await tester.pump();
      // Controls should be hidden
      expect(find.text('1 / 3'), findsNothing);

      // Tap again to show
      await tester.tap(find.byType(PageView));
      await tester.pump();
      expect(find.text('1 / 3'), findsOneWidget);
    });
  });

  group('DrawingLayersDock Close Button Tests', () {
    testWidgets('Tapping close icon invokes onClose callback', (tester) async {
      final controller = DrawingController();
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingLayersDock(
              controller: controller,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      final closeIcon = find.byIcon(Icons.close);
      expect(closeIcon, findsOneWidget);

      await tester.tap(closeIcon);
      expect(closed, isTrue);
    });
  });
}
