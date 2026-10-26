import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_interaction_mode.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_add_panels_tab.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_mode_indicator_banner.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_selection_handles.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_transform_resolver.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_panel_context_bar.dart';
import 'package:furi_app/screens/herramientas/comic/comic_editor_screen.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_project.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_page.dart';

void main() {
  group('Comic Gestures & Freeform Panel Creation Tests', () {
    late ComicController controller;

    setUp(() {
      controller = ComicController(blankPage: true);
    });

    test('ComicInteractionMode conmuta estados adecuadamente', () {
      expect(controller.interactionMode, ComicInteractionMode.normal);
      expect(controller.interactionMode.isNormal, isTrue);

      controller.setInteractionMode(ComicInteractionMode.drawPanel);
      expect(controller.interactionMode.isDrawPanel, isTrue);

      controller.setInteractionMode(ComicInteractionMode.slicePanel);
      expect(controller.interactionMode.isSlicePanel, isTrue);
    });

    test('addPanelFromRect crea viñeta con dimensiones personalizadas y retorna a modo normal', () {
      controller.setInteractionMode(ComicInteractionMode.drawPanel);

      const customRect = Rect.fromLTWH(0.15, 0.20, 0.70, 0.35);
      controller.addPanelFromRect(customRect, shape: ComicPanelShape.rectangle);

      expect(controller.activePage.panels.length, 1);
      final created = controller.activePage.panels.first;
      expect(created.normalizedRect.left, closeTo(0.15, 0.001));
      expect(created.normalizedRect.top, closeTo(0.20, 0.001));
      expect(created.normalizedRect.width, closeTo(0.70, 0.001));
      expect(created.normalizedRect.height, closeTo(0.35, 0.001));

      expect(controller.selectedPanelId, created.id);
      expect(controller.interactionMode, ComicInteractionMode.normal);
    });

    test('slicePanelWithLine corta una viñeta en dos partes proporcionales', () {
      const initialRect = Rect.fromLTWH(0.10, 0.10, 0.80, 0.60);
      controller.addPanelFromRect(initialRect);
      final panelId = controller.activePage.panels.first.id;

      // Corte vertical en x = 0.50
      controller.slicePanelWithLine(
        panelId,
        const Offset(0.50, 0.10),
        const Offset(0.50, 0.70),
      );

      expect(controller.activePage.panels.length, 2);
      final p1 = controller.activePage.panels[0];
      final p2 = controller.activePage.panels[1];

      expect(p1.normalizedRect.left, 0.10);
      expect(p1.normalizedRect.width, closeTo(0.39, 0.02));
      expect(p2.normalizedRect.left, closeTo(0.51, 0.02));
    });

    test('updatePanelRect redimensiona bordes independientes', () {
      controller.addPanel(normalizedRect: const Rect.fromLTWH(0.10, 0.10, 0.50, 0.40));
      final id = controller.activePage.panels.first.id;

      controller.updatePanelRect(id, const Rect.fromLTWH(0.10, 0.10, 0.75, 0.40));
      expect(controller.activePage.panels.first.normalizedRect.width, 0.75);
    });

    test('updatePanelBorder actualiza ancho y color de borde', () {
      controller.addPanel();
      final id = controller.activePage.panels.first.id;

      controller.updatePanelBorder(id, borderWidth: 8.0, borderColor: const Color(0xFFFF453A));
      expect(controller.activePage.panels.first.borderWidth, 8.0);
      expect(controller.activePage.panels.first.borderColor, const Color(0xFFFF453A));
    });

    test('ComicElementTransform identifica los 8 mangos y rotación vía hitTest', () {
      const transform = ComicElementTransform(
        center: Offset(200, 200),
        halfW: 100,
        halfH: 80,
        rotation: 0.0,
      );

      // 1. Mango de rotación lollipop
      expect(transform.hitTest(transform.rotationHandlePos), ComicHandleType.rotate);

      // 2. 4 Esquinas
      expect(transform.hitTest(transform.topLeftPos), ComicHandleType.cornerTopLeft);
      expect(transform.hitTest(transform.topRightPos), ComicHandleType.cornerTopRight);
      expect(transform.hitTest(transform.bottomLeftPos), ComicHandleType.cornerBottomLeft);
      expect(transform.hitTest(transform.bottomRightPos), ComicHandleType.cornerBottomRight);

      // 3. 4 Bordes independientes
      expect(transform.hitTest(transform.topEdgePos), ComicHandleType.edgeTop);
      expect(transform.hitTest(transform.bottomEdgePos), ComicHandleType.edgeBottom);
      expect(transform.hitTest(transform.leftEdgePos), ComicHandleType.edgeLeft);
      expect(transform.hitTest(transform.rightEdgePos), ComicHandleType.edgeRight);

      // 4. Cuerpo interior
      expect(transform.hitTest(const Offset(200, 200)), ComicHandleType.body);
    });

    testWidgets('ComicAddPanelsTab muestra opción destacada Trazar Viñeta y activa drawPanel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicAddPanelsTab(controller: controller),
          ),
        ),
      );

      expect(find.text('✏️ Trazar Viñeta en Pantalla'), findsOneWidget);

      await tester.tap(find.text('✏️ Trazar Viñeta en Pantalla'));
      await tester.pump();
      expect(controller.interactionMode, ComicInteractionMode.drawPanel);
    });

    testWidgets('ComicModeIndicatorBanner renderiza banner informativo y cancela modo', (tester) async {
      controller.setInteractionMode(ComicInteractionMode.drawPanel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ComicModeIndicatorBanner(controller: controller),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Arrastrá con el dedo para trazar la viñeta'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(controller.interactionMode, ComicInteractionMode.normal);
    });

    test('ComicTransformResolver delimita el panel exactamente sin desplazar por dibujo interno', () {
      controller.addPanel(normalizedRect: const Rect.fromLTWH(0.1, 0.2, 0.8, 0.6));
      final panel = controller.activePage.panels.first;
      controller.selectPanel(panel.id);
      controller.setPanelTransform(panel.id, scale: 2.5, dx: 40.0, dy: -30.0);

      const pageSize = Size(1000, 1000);
      final t = ComicTransformResolver.resolve(controller, pageSize);
      expect(t, isNotNull);
      // El centro del bounding box debe coincidir con el centro geométrico del panel
      expect(t!.center.dx, 500.0);
      expect(t.center.dy, 500.0);
      // El ancho del bounding box debe coincidir con el ancho del panel (800 / 2 = 400)
      expect(t.halfW, closeTo(400.0, 0.001));
      expect(t.halfH, closeTo(300.0, 0.001));
    });

    testWidgets('Tocar viñeta en ComicEditorScreen selecciona el panel y muestra ComicPanelContextBar', (tester) async {
      final panel = ComicPanel(
        id: 'test_p1',
        normalizedRect: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
      );
      final initialProj = ComicProject(
        id: 'proj_tap_test',
        title: 'Tap Test',
        pages: [
          ComicPage(
            id: 'page_1',
            pageNumber: 1,
            panels: [panel],
            bubbles: [],
            sfxStickers: [],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComicEditorScreen(initialProject: initialProj),
        ),
      );
      await tester.pumpAndSettle();

      // Al inicio no hay panel seleccionado
      expect(find.byType(ComicPanelContextBar), findsNothing);

      // Tocar en el centro del panel
      await tester.tapAt(const Offset(400, 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Debe seleccionar el panel y renderizar la barra de contexto in-place
      expect(find.byType(ComicPanelContextBar), findsOneWidget);
    });
  });
}
