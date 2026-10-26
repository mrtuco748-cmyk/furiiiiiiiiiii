import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/dibujo_screen.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_infinite_dock.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_layers_dock.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_top_bar.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_undo_redo_buttons.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/popovers/drawing_options_popover.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/popovers/drawing_tools_popover.dart';

void main() {
  group('Drawing Studio Infinite Painter UI Tests', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController();
    });

    test('DrawingToolType.smudge existe y tiene metadatos', () {
      expect(DrawingToolType.smudge.displayName, 'Difuminar');
      expect(DrawingToolType.smudge.isSmudge, isTrue);
      expect(DrawingToolType.smudge.isEraser, isFalse);
      expect(DrawingToolType.smudge.defaultOpacity, lessThan(0.5));
    });

    testWidgets('DrawingInfiniteDock renderiza herramientas, grosor, color y opacidad', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingInfiniteDock(
              controller: controller,
              onToggleColorPopover: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.brush), findsOneWidget);
      expect(find.byTooltip('Borrador'), findsOneWidget);

      await tester.tap(find.byTooltip('Borrador'));
      await tester.pump();
      expect(controller.selectedTool, DrawingToolType.eraser);
    });

    testWidgets('DrawingTopBar renderiza Home icon a la izquierda y 4 herramientas a la derecha', (tester) async {
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

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.architecture), findsOneWidget);
      expect(find.byIcon(Icons.crop_free), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);

      // No debe contener botones innecesarios que rompan el diseño de Infinite Painter
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byIcon(Icons.save_alt), findsNothing);
    });

    testWidgets('DrawingLayersDock renderiza botón +, capas y círculo de fondo', (tester) async {
      controller.addLayer(name: 'Boceto');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingLayersDock(
              controller: controller,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('C1'), findsOneWidget);
      expect(find.text('C2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(controller.layers.length, 3);
    });

    testWidgets('DrawingUndoRedoButtons ejecuta undo y redo reactivamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingUndoRedoButtons(controller: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);

      controller.startStroke(const Offset(10, 10));
      controller.endStroke();
      expect(controller.canUndo, isTrue);

      await tester.pump();
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pump();
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);
    });

    testWidgets('DrawingToolsPopover muestra herramientas, formas y cámara', (tester) async {
      bool resetZoomCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingToolsPopover(
              controller: controller,
              onResetZoom: () => resetZoomCalled = true,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Herramientas'), findsOneWidget);
      expect(find.text('Formas'), findsOneWidget);
      expect(find.text('Encajar'), findsOneWidget);

      await tester.tap(find.text('Encajar'));
      expect(resetZoomCalled, isTrue);
    });

    testWidgets('DrawingEditPopover y DrawingOptionsPopover renderizan correctamente', (tester) async {
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

      expect(find.text('Opciones'), findsOneWidget);
      expect(find.text('Nuevo'), findsOneWidget);
      expect(find.text('Abrir'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Exportar'), findsOneWidget);
    });

    testWidgets('DibujoScreen renderiza la UI completa estilo Infinite Painter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DibujoScreen(),
        ),
      );

      // Header icons Infinite Painter (Screenshots 4 & 5)
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.architecture), findsOneWidget);
      expect(find.byIcon(Icons.crop_free), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);

      // Dock izquierdo (con pincel y borrador, sin blur raro)
      expect(find.byIcon(Icons.brush), findsOneWidget);

      // Botón Deshacer inferior izquierdo
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
    });
  });
}
