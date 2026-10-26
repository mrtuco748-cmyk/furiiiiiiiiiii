import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_lasso_action_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drawing Lasso Selection Tool Tests', () {
    test('Lasso tool selection, stroke capture and selection creation', () {
      final controller = DrawingController();

      // 1. Agregar un trazo previo en el centro (60, 60)
      controller.startStroke(const Offset(60, 60));
      controller.updateStroke(const Offset(65, 65));
      controller.endStroke();

      expect(controller.activeLayer.strokes.length, 1);
      final targetStroke = controller.activeLayer.strokes.first;

      // 2. Seleccionar herramienta Lazo
      controller.selectTool(DrawingToolType.lasso);
      expect(controller.selectedTool, DrawingToolType.lasso);
      expect(controller.hasSelection, isFalse);

      // 3. Trazar un polígono de lazo envolviendo (60, 60)
      controller.startStroke(const Offset(40, 40));
      controller.updateStroke(const Offset(80, 40));
      controller.updateStroke(const Offset(80, 80));
      controller.updateStroke(const Offset(40, 80));
      controller.updateStroke(const Offset(40, 40));
      controller.endStroke();

      // Debe haber generado una selección activa conteniendo el trazo
      expect(controller.hasSelection, isTrue);
      expect(controller.activeSelection, isNotNull);
      expect(controller.activeSelection!.selectedStrokeIds, contains(targetStroke.id));
      expect(controller.activeSelection!.bounds.contains(const Offset(60, 60)), isTrue);
    });

    test('Lasso selection move, duplicate, fill and delete operations', () {
      final controller = DrawingController();

      // Agregar trazo
      controller.startStroke(const Offset(100, 100));
      controller.updateStroke(const Offset(110, 110));
      controller.endStroke();
      final initialStroke = controller.activeLayer.strokes.first;

      // Seleccionar con lazo
      controller.selectTool(DrawingToolType.lasso);
      controller.startStroke(const Offset(80, 80));
      controller.updateStroke(const Offset(130, 80));
      controller.updateStroke(const Offset(130, 130));
      controller.updateStroke(const Offset(80, 130));
      controller.endStroke();

      expect(controller.hasSelection, isTrue);

      // 1. Mover selección (+20, +30)
      controller.moveSelection(const Offset(20, 30));
      final movedStroke = controller.activeLayer.strokes.firstWhere((s) => s.id == initialStroke.id);
      expect(movedStroke.points.first.offset, const Offset(120, 130));
      expect(controller.activeSelection!.bounds.left, 100);

      // 2. Duplicar selección
      controller.duplicateSelection();
      expect(controller.activeLayer.strokes.length, 2);
      final dupId = controller.activeSelection!.selectedStrokeIds.first;

      // 3. Rellenar polígono del lazo
      controller.fillSelection();
      expect(controller.activeLayer.strokes.length, 3);
      expect(controller.activeLayer.strokes.last.tool, DrawingToolType.bucketFill);

      // 4. Borrar elementos seleccionados
      controller.deleteSelection();
      expect(controller.hasSelection, isFalse);
      expect(controller.activeLayer.strokes.any((s) => s.id == dupId), isFalse);
      expect(controller.activeLayer.strokes.any((s) => s.id == initialStroke.id), isTrue);
    });

    testWidgets('DrawingLassoActionBar renders when selection exists and triggers clearSelection', (tester) async {
      final controller = DrawingController();

      // Crear trazo y selección con lazo
      controller.startStroke(const Offset(50, 50));
      controller.endStroke();

      controller.selectTool(DrawingToolType.lasso);
      controller.startStroke(const Offset(30, 30));
      controller.updateStroke(const Offset(70, 30));
      controller.updateStroke(const Offset(70, 70));
      controller.updateStroke(const Offset(30, 70));
      controller.endStroke();

      expect(controller.hasSelection, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingLassoActionBar(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mover'), findsOneWidget);
      expect(find.text('Duplicar'), findsOneWidget);
      expect(find.text('Rellenar'), findsOneWidget);
      expect(find.text('Voltear H'), findsOneWidget);
      expect(find.text('Borrar'), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);

      // Tocar Listo para deseleccionar
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      expect(controller.hasSelection, isFalse);
    });
  });
}
