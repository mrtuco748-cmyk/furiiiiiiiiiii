import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_canvas_viewport.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_viewport_gesture_coordinator.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_viewport_math.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drawing Viewport Zoom & Multi-touch Smoothness Tests', () {
    test('DrawingViewportMath.applyIncrementalTransform preserves focal scene point', () {
      final initialMatrix = Matrix4.identity();
      final prevFocal = const Offset(200, 200);
      final currentFocal = const Offset(230, 240); // panned by (30, 40)
      const scaleFactor = 1.5;

      final updatedMatrix = DrawingViewportMath.applyIncrementalTransform(
        currentMatrix: initialMatrix,
        prevFocalPoint: prevFocal,
        currentFocalPoint: currentFocal,
        scaleFactor: scaleFactor,
      );

      // El punto de escena bajo prevFocal debe mapearse exactamente a currentFocal
      final mappedFocal = MatrixUtils.transformPoint(updatedMatrix, prevFocal);
      expect(mappedFocal.dx, closeTo(currentFocal.dx, 0.001));
      expect(mappedFocal.dy, closeTo(currentFocal.dy, 0.001));
      expect(updatedMatrix.getMaxScaleOnAxis(), closeTo(1.5, 0.001));
    });

    test('DrawingViewportMath.calculateSpan handles 2 and 3 pointers smoothly', () {
      final twoPointers = [const Offset(100, 100), const Offset(200, 100)];
      expect(DrawingViewportMath.calculateSpan(twoPointers), closeTo(100.0, 0.001));

      // Orden inverso produce el mismo span
      final twoPointersReversed = [const Offset(200, 100), const Offset(100, 100)];
      expect(DrawingViewportMath.calculateSpan(twoPointersReversed), closeTo(100.0, 0.001));

      // 3 punteros
      final threePointers = [const Offset(0, 0), const Offset(100, 0), const Offset(50, 86.6)];
      final span = DrawingViewportMath.calculateSpan(threePointers);
      expect(span, greaterThan(50.0));
    });

    test('DrawingViewportGestureCoordinator does NOT jump when lifting one finger', () {
      final controller = DrawingController();
      final transformController = TransformationController();
      final canvasKey = GlobalKey();

      final coordinator = DrawingViewportGestureCoordinator(
        controller: controller,
        transformController: transformController,
        canvasKey: canvasKey,
        getContext: null,
        onCursorUpdate: (cursor, pressure, visible) {},
      );

      const canvasSize = Size(2000, 2000);

      // 1. Dedo 1 toca la pantalla en (100, 100)
      coordinator.handlePointerDown(
        const PointerDownEvent(pointer: 1, position: Offset(100, 100)),
        canvasSize,
      );
      expect(coordinator.hasActivePointers, isTrue);

      // 2. Dedo 2 toca la pantalla en (200, 100) -> Se activa modo multi-touch
      coordinator.handlePointerDown(
        const PointerDownEvent(pointer: 2, position: Offset(200, 100)),
        canvasSize,
      );

      // 3. Los dedos se separan (zoom in a 1.5x)
      coordinator.handlePointerMove(
        const PointerMoveEvent(pointer: 1, position: Offset(80, 100)),
        canvasSize,
      );
      coordinator.handlePointerMove(
        const PointerMoveEvent(pointer: 2, position: Offset(230, 100)),
        canvasSize,
      );

      final scaleAfterPinch = transformController.value.getMaxScaleOnAxis();
      expect(scaleAfterPinch, greaterThan(1.1));

      final matrixBeforeLift = Matrix4.copy(transformController.value);

      // 4. Se levanta el dedo 1
      coordinator.handlePointerUpOrCancel(
        const PointerUpEvent(pointer: 1, position: Offset(80, 100)),
      );

      // La matriz NO debe haber saltado ni reseteado su escala al levantar un dedo
      expect(transformController.value.getMaxScaleOnAxis(), equals(scaleAfterPinch));

      // 5. El dedo 2 se mueve ligeramente (paneo residual)
      coordinator.handlePointerMove(
        const PointerMoveEvent(pointer: 2, position: Offset(235, 102)),
        canvasSize,
      );

      // La escala debe permanecer intacta (sin saltos bruscos a 1.0)
      expect(transformController.value.getMaxScaleOnAxis(), equals(scaleAfterPinch));
      expect(transformController.value.entry(0, 3), closeTo(matrixBeforeLift.entry(0, 3) + 5, 0.1));

      // 6. Se levanta el segundo dedo -> fin del gesto
      coordinator.handlePointerUpOrCancel(
        const PointerUpEvent(pointer: 2, position: Offset(235, 102)),
      );
      expect(coordinator.hasActivePointers, isFalse);
    });

    test('Two-finger pinch with bucket fill tool does not flood canvas', () {
      final controller = DrawingController();
      controller.selectTool(DrawingToolType.bucketFill);
      final transformController = TransformationController();
      final canvasKey = GlobalKey();

      final coordinator = DrawingViewportGestureCoordinator(
        controller: controller,
        transformController: transformController,
        canvasKey: canvasKey,
        getContext: null,
        onCursorUpdate: (cursor, pressure, visible) {},
      );

      const canvasSize = Size(2000, 2000);

      // Dos dedos tocan sucesivamente para zoom
      coordinator.handlePointerDown(
        const PointerDownEvent(pointer: 1, position: Offset(100, 100)),
        canvasSize,
      );
      coordinator.handlePointerDown(
        const PointerDownEvent(pointer: 2, position: Offset(200, 100)),
        canvasSize,
      );

      // Se mueven para hacer zoom
      coordinator.handlePointerMove(
        const PointerMoveEvent(pointer: 1, position: Offset(80, 100)),
        canvasSize,
      );
      coordinator.handlePointerUpOrCancel(
        const PointerUpEvent(pointer: 1, position: Offset(80, 100)),
      );
      coordinator.handlePointerUpOrCancel(
        const PointerUpEvent(pointer: 2, position: Offset(200, 100)),
      );

      // NO debe haberse creado trazo de relleno por el pellizco
      expect(controller.activeLayer.strokes.isEmpty, isTrue);
    });

    testWidgets('DrawingCanvasViewport renders and handles gestures smoothly', (tester) async {
      final controller = DrawingController();
      final transformController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: DrawingCanvasViewport(
                controller: controller,
                transformController: transformController,
                canvasSize: const Size(1200, 1200),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvasViewport), findsOneWidget);

      // Simular pointer scroll (rueda de ratón)
      final center = tester.getCenter(find.byType(DrawingCanvasViewport));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0, -100),
        ),
      );
      await tester.pump();

      // Debe haber aumentado la escala mediante zoom con ratón
      expect(transformController.value.getMaxScaleOnAxis(), greaterThan(0.01));
    });
  });
}
