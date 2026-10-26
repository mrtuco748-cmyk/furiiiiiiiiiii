import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/comic_editor_screen.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_add_drawer.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_selection_handles.dart';

void main() {
  group('Comic Redesign Tests (Blank page, + button, individual adding, direct handles)', () {
    test('ComicController con blankPage: true inicia con 0 paneles', () {
      final controller = ComicController(blankPage: true);
      expect(controller.activePage.panels.isEmpty, isTrue);
      expect(controller.activePage.bubbles.isEmpty, isTrue);
      expect(controller.activePage.sfxStickers.isEmpty, isTrue);
    });

    test('addPage con blank: true agrega una página en blanco', () {
      final controller = ComicController(blankPage: true);
      controller.addPage(blank: true);
      expect(controller.project.pages.length, 2);
      expect(controller.activePage.panels.isEmpty, isTrue);
    });

    test('exclusividad de selección al agregar panel, globo y sfx', () {
      final controller = ComicController();
      controller.addPanel();
      expect(controller.selectedPanelId, isNotNull);
      expect(controller.selectedBubbleId, isNull);
      expect(controller.selectedSfxId, isNull);

      controller.addBubble();
      expect(controller.selectedBubbleId, isNotNull);
      expect(controller.selectedPanelId, isNull);
      expect(controller.selectedSfxId, isNull);

      controller.addSfx('¡BOOM!');
      expect(controller.selectedSfxId, isNotNull);
      expect(controller.selectedPanelId, isNull);
      expect(controller.selectedBubbleId, isNull);
    });

    test('addPanel agrega un panel individual y lo selecciona', () {
      final controller = ComicController(blankPage: true);
      expect(controller.activePage.panels.isEmpty, isTrue);

      controller.addPanel(shape: ComicPanelShape.slantedRight);
      expect(controller.activePage.panels.length, 1);
      expect(controller.activePage.panels.first.panelShape, ComicPanelShape.slantedRight);
      expect(controller.selectedPanelId, controller.activePage.panels.first.id);

      controller.addPanel(shape: ComicPanelShape.diamond);
      expect(controller.activePage.panels.length, 2);
      expect(controller.activePage.panels.last.panelShape, ComicPanelShape.diamond);
    });

    test('deletePanel permite borrar todos los paneles hasta quedar en blanco', () {
      final controller = ComicController(blankPage: true);
      controller.addPanel();
      expect(controller.activePage.panels.length, 1);

      controller.deletePanel(controller.activePage.panels.first.id);
      expect(controller.activePage.panels.isEmpty, isTrue);
    });

    test('movePanel actualiza coordenadas normalizadas', () {
      final controller = ComicController();
      controller.addPanel(shape: ComicPanelShape.rectangle);
      final id = controller.activePage.panels.first.id;
      final initialLeft = controller.activePage.panels.first.normalizedRect.left;

      controller.movePanel(id, 0.05, 0.02);
      final updatedLeft = controller.activePage.panels.first.normalizedRect.left;
      expect(updatedLeft, greaterThan(initialLeft));
    });

    test('ComicElementTransform calcula handles de rotación y escala correctamente', () {
      const transform = ComicElementTransform(
        center: Offset(200, 300),
        halfW: 80,
        halfH: 50,
        rotation: 0.0,
      );

      final rotPos = transform.rotationHandlePos;
      expect(rotPos.dx, 200);
      expect(rotPos.dy, lessThan(300 - 50));

      final br = transform.bottomRightPos;
      expect(br.dx, greaterThan(200));
      expect(br.dy, greaterThan(300));

      expect(transform.containsPoint(const Offset(200, 300)), isTrue);
      expect(transform.containsPoint(const Offset(500, 500)), isFalse);
    });

    testWidgets('ComicAddDrawer muestra 3 pestañas: Viñeta, Globo y SFX', (tester) async {
      final controller = ComicController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicAddDrawer(controller: controller),
          ),
        ),
      );

      expect(find.text('Viñeta'), findsOneWidget);
      expect(find.text('Globo'), findsOneWidget);
      expect(find.text('SFX'), findsOneWidget);

      expect(find.text('Rectangular Clásico'), findsOneWidget);
      expect(find.text('Corte Shonen Diagonal'), findsOneWidget);

      await tester.tap(find.text('Globo'));
      await tester.pumpAndSettle();
      expect(find.text('AGREGAR'), findsOneWidget);

      await tester.tap(find.text('SFX'));
      await tester.pumpAndSettle();
      expect(find.text('¡BOOM!'), findsOneWidget);
      expect(find.text('¡ZAS!'), findsOneWidget);
    });

    testWidgets('ComicEditorScreen renderiza botón flotante + abajo a la derecha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ComicEditorScreen(),
        ),
      );

      expect(find.byIcon(Icons.add), findsWidgets);
    });
  });
}
