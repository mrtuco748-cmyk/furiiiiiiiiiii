import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_lasso_selection.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_lasso_action_bar.dart';
import 'package:furi_app/screens/herramientas/herramientas_screen.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_interaction_mode.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_editor_overlays.dart';
import 'package:furi_app/theme/app_theme.dart';

void main() {
  group('Drawing Tool Toggle & Deselection Tests', () {
    test('Default drawing tool is pen and previousDrawingTool is pen', () {
      final controller = DrawingController();
      expect(controller.selectedTool, equals(DrawingToolType.pen));
      expect(controller.previousDrawingTool, equals(DrawingToolType.pen));
    });

    test('Selecting a brush updates both selectedTool and previousDrawingTool', () {
      final controller = DrawingController();
      controller.selectTool(DrawingToolType.pencil);
      expect(controller.selectedTool, equals(DrawingToolType.pencil));
      expect(controller.previousDrawingTool, equals(DrawingToolType.pencil));

      controller.selectTool(DrawingToolType.marker);
      expect(controller.selectedTool, equals(DrawingToolType.marker));
      expect(controller.previousDrawingTool, equals(DrawingToolType.marker));
    });

    test('Toggling eraser switches to eraser and toggling again restores previous tool', () {
      final controller = DrawingController();
      controller.selectTool(DrawingToolType.pencil);

      // Select eraser via toggle
      controller.toggleTool(DrawingToolType.eraser);
      expect(controller.selectedTool, equals(DrawingToolType.eraser));
      expect(controller.previousDrawingTool, equals(DrawingToolType.pencil));

      // Deselect eraser via toggle
      controller.toggleTool(DrawingToolType.eraser);
      expect(controller.selectedTool, equals(DrawingToolType.pencil));
    });

    test('Toggling smudge switches to smudge and toggling again restores previous tool', () {
      final controller = DrawingController();
      controller.selectTool(DrawingToolType.gPen);

      // Select smudge
      controller.toggleTool(DrawingToolType.smudge);
      expect(controller.selectedTool, equals(DrawingToolType.smudge));
      expect(controller.previousDrawingTool, equals(DrawingToolType.gPen));

      // Deselect smudge
      controller.toggleTool(DrawingToolType.smudge);
      expect(controller.selectedTool, equals(DrawingToolType.gPen));
    });

    test('Toggling shapes, lasso and fill switches and restores previous tool', () {
      final controller = DrawingController();
      controller.selectTool(DrawingToolType.airbrush);

      // Lasso
      controller.toggleTool(DrawingToolType.lasso);
      expect(controller.selectedTool, equals(DrawingToolType.lasso));
      expect(controller.previousDrawingTool, equals(DrawingToolType.airbrush));
      controller.toggleTool(DrawingToolType.lasso);
      expect(controller.selectedTool, equals(DrawingToolType.airbrush));

      // Rectangle
      controller.toggleTool(DrawingToolType.rectangle);
      expect(controller.selectedTool, equals(DrawingToolType.rectangle));
      controller.toggleTool(DrawingToolType.rectangle);
      expect(controller.selectedTool, equals(DrawingToolType.airbrush));

      // Bucket Fill
      controller.toggleTool(DrawingToolType.bucketFill);
      expect(controller.selectedTool, equals(DrawingToolType.bucketFill));
      controller.toggleTool(DrawingToolType.bucketFill);
      expect(controller.selectedTool, equals(DrawingToolType.airbrush));
    });
  });

  group('DrawingLassoActionBar Mover Action Tests', () {
    testWidgets('Tapping Mover shows SnackBar guidance without crashing', (tester) async {
      final controller = DrawingController();
      controller.activeSelection = const DrawingLassoSelection(
        polygonPoints: [Offset(10, 10), Offset(50, 10), Offset(50, 50), Offset(10, 50)],
        selectedStrokeIds: [],
        bounds: Rect.fromLTWH(10, 10, 40, 40),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingLassoActionBar(controller: controller),
          ),
        ),
      );

      expect(find.text('Mover'), findsOneWidget);
      await tester.tap(find.text('Mover'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Arrastrá con un dedo dentro de la selección para moverla'), findsOneWidget);
    });
  });

  group('HerramientasScreen Flipbook Dialog Tests', () {
    testWidgets('Tapping ANIMACIÓN FLIPBOOK opens informational dialog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HerramientasScreen(mode: AppMode.dark),
        ),
      );

      final flipbookFinder = find.text('ANIMACIÓN FLIPBOOK');
      expect(flipbookFinder, findsOneWidget);

      await tester.tap(flipbookFinder);
      await tester.pumpAndSettle();

      expect(find.text('Animación Flipbook'), findsOneWidget);
      expect(find.text('IR A DIBUJO'), findsOneWidget);
      expect(find.text('CERRAR'), findsOneWidget);

      await tester.tap(find.text('CERRAR'));
      await tester.pumpAndSettle();
      expect(find.text('Animación Flipbook'), findsNothing);
    });
  });

  group('ComicEditorOverlays Slice & FrameContent Toggle Tests', () {
    testWidgets('Slice and frame content toggle interaction modes', (tester) async {
      final controller = ComicController();
      controller.addPanel();
      final panel = controller.activePage.panels.first;
      controller.selectPanel(panel.id);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicEditorOverlays(
              controller: controller,
              activePanel: panel,
              editingBubble: null,
              editingSfx: null,
              showBubbleBar: false,
              showSfxBar: false,
              showSfxEditor: false,
              showPanelCustomizer: false,
              showTemplateBar: false,
              isImmersive: false,
              onDrawInPanel: () {},
              onInsertDrawing: () {},
              onOpenPanelCustomizer: () {},
              onClosePanelCustomizer: () {},
              onSaveBubble: (_) {},
              onDeleteBubble: (_) {},
              onCloseBubble: () {},
              onUpdateSfx: (_) {},
              onDeleteSfx: () {},
              onCloseSfxEditor: () {},
              onStampSfx: (_, _) {},
              onCloseSfxBar: () {},
              onCloseTemplateBar: () {},
            ),
          ),
        ),
      );

      // Tap slice button
      final sliceButton = find.byIcon(Icons.content_cut);
      expect(sliceButton, findsOneWidget);

      await tester.tap(sliceButton);
      expect(controller.interactionMode, equals(ComicInteractionMode.slicePanel));

      // Tap slice button again -> toggles off to normal!
      await tester.tap(sliceButton);
      expect(controller.interactionMode, equals(ComicInteractionMode.normal));
    });
  });
}
