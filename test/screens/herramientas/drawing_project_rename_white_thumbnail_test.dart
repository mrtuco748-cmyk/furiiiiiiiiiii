import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_drawing_thumbnail.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_layer.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_point.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_project.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_stroke.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_projects_sheet.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_top_bar.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/popovers/drawing_options_popover.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drawing Thumbnail White Canvas Background Tests', () {
    testWidgets('ComicDrawingThumbnail renders on white container and paints white paper canvas', (tester) async {
      final project = DrawingProject(
        id: 'p_test',
        title: 'Boceto Manga',
        layers: [
          DrawingLayer(
            id: 'l1',
            name: 'Tinta',
            strokes: [
              DrawingStroke(
                id: 's1',
                tool: DrawingToolType.pen,
                color: Colors.black,
                strokeWidth: 4,
                opacity: 1.0,
                points: [
                  DrawingPoint(offset: const Offset(10, 10)),
                  DrawingPoint(offset: const Offset(50, 50)),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: ComicDrawingThumbnail(project: project),
            ),
          ),
        ),
      );

      // El contenedor de la miniatura debe ser blanco sólido (no negro/gris)
      final containerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.color == Colors.white,
      );
      expect(containerFinder, findsOneWidget);
    });
  });

  group('Drawing Project Rename Tests', () {
    testWidgets('DrawingTopBar displays editable project title and allows renaming', (tester) async {
      final controller = DrawingController();
      controller.setTitle('Mi Primer Dibujo');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingTopBar(
              controller: controller,
              onToggleTools: () {},
              onToggleEdit: () {},
              onToggleLayers: () {},
              onToggleOptions: () {},
              onOpenProjects: () {},
              onExport: () {},
              onToggleImmersive: () {},
            ),
          ),
        ),
      );

      expect(find.text('Mi Primer Dibujo'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Tocar el título abre el diálogo de renombrar
      await tester.tap(find.text('Mi Primer Dibujo'));
      await tester.pumpAndSettle();

      expect(find.text('Nombre del Proyecto'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Ingresar nuevo nombre y guardar
      await tester.enterText(find.byType(TextField), 'Ilustración Final');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(controller.projectTitle, 'Ilustración Final');
      expect(find.text('Ilustración Final'), findsOneWidget);
    });

    testWidgets('DrawingProjectsSheet renders rename icon button for projects', (tester) async {
      final controller = DrawingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingProjectsSheet(controller: controller),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('MIS DIBUJOS'), findsOneWidget);
    });

    testWidgets('DrawingOptionsPopover renders Renombrar button in grid', (tester) async {
      final controller = DrawingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingOptionsPopover(
              controller: controller,
              onOpenProjects: () {},
              onExport: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Renombrar'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}
