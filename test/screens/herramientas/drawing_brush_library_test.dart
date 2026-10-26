import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/dibujo_screen.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_floating_brush_popover.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_infinite_dock.dart';

void main() {
  group('Drawing Studio Brush Library Tests', () {
    testWidgets('DrawingFloatingBrushPopover renders all 6 brushes and updates controller', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = DrawingController();
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingFloatingBrushPopover(
              controller: controller,
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que los 6 pinceles están visibles
      expect(find.text('Birome'), findsOneWidget);
      expect(find.text('Pluma G Manga'), findsOneWidget);
      expect(find.text('Lápiz Grafito'), findsOneWidget);
      expect(find.text('Marcador Tinta'), findsOneWidget);
      expect(find.text('Aerógrafo'), findsOneWidget);
      expect(find.text('Resaltador'), findsOneWidget);

      // Seleccionar Pluma G Manga
      await tester.tap(find.text('Pluma G Manga'));
      await tester.pumpAndSettle();
      expect(controller.selectedTool, DrawingToolType.gPen);

      // Seleccionar Aerógrafo
      await tester.tap(find.text('Aerógrafo'));
      await tester.pumpAndSettle();
      expect(controller.selectedTool, DrawingToolType.airbrush);

      // Seleccionar chip de tamaño rápido 35
      await tester.scrollUntilVisible(find.text('35'), 50);
      await tester.tap(find.text('35'));
      await tester.pumpAndSettle();
      expect(controller.strokeWidth, 35.0);

      // Tocar botón cerrar
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });

    testWidgets('Tapping brush icon in DibujoScreen dock opens DrawingFloatingBrushPopover', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DibujoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Popover no debe estar visible inicialmente
      expect(find.byType(DrawingFloatingBrushPopover), findsNothing);

      // Encontrar el botón de pincel en el dock (con icono de pen/brush)
      final brushDockButton = find.descendant(
        of: find.byType(DrawingInfiniteDock),
        matching: find.byIcon(Icons.brush),
      );
      expect(brushDockButton, findsOneWidget);

      // Tocar el botón de pincel
      await tester.tap(brushDockButton);
      await tester.pumpAndSettle();

      // Debe abrirse el popover de la biblioteca de pinceles
      expect(find.byType(DrawingFloatingBrushPopover), findsOneWidget);
      expect(find.text('Pluma G Manga'), findsOneWidget);
    });
  });
}
