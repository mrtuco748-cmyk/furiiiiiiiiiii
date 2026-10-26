import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_bubble.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_editor_gesture_helper.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_page_editor_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Comic Bubble Smooth Move and Drag Tests', () {
    test('ComicEditorGestureHelper.applyMove moves bubble smoothly with delta', () {
      final controller = ComicController(blankPage: true);
      controller.addBubble(
        text: 'Test Bubble',
        type: ComicBubbleType.mangaOval,
        x: 0.50,
        y: 0.40,
      );

      final bubble = controller.selectedBubble!;
      expect(bubble.x, closeTo(0.50, 0.001));
      expect(bubble.y, closeTo(0.40, 0.001));

      const pageSize = Size(400, 600);
      final details = DragUpdateDetails(
        globalPosition: const Offset(240, 300),
        localPosition: const Offset(240, 300),
        delta: const Offset(40, 60),
      );

      ComicEditorGestureHelper.applyMove(
        controller: controller,
        pos: details.localPosition,
        details: details,
        pageSize: pageSize,
      );

      final movedBubble = controller.selectedBubble!;
      expect(movedBubble.x, closeTo(0.60, 0.001));
      expect(movedBubble.y, closeTo(0.50, 0.001));
    });

    test('ComicEditorGestureHelper.applyBubbleEdgeResize modifies width and height', () {
      final controller = ComicController(blankPage: true);
      controller.addBubble(
        text: 'Resize Bubble',
        type: ComicBubbleType.mangaOval,
        x: 0.50,
        y: 0.50,
      );

      final bubble = controller.selectedBubble!;
      final initialW = bubble.width;
      final initialH = bubble.height;

      // Expandir ancho hacia la derecha
      ComicEditorGestureHelper.applyBubbleEdgeResize(
        controller: controller,
        mode: ComicDragMode.resizeRight,
        details: DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(20, 0),
        ),
        bubble: bubble,
      );

      expect(controller.selectedBubble!.width, greaterThan(initialW));

      // Expandir alto hacia abajo
      ComicEditorGestureHelper.applyBubbleEdgeResize(
        controller: controller,
        mode: ComicDragMode.resizeBottom,
        details: DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, 15),
        ),
        bubble: controller.selectedBubble!,
      );

      expect(controller.selectedBubble!.height, greaterThan(initialH));
    });

    testWidgets('Touching and dragging an unselected bubble immediately selects and moves it', (tester) async {
      final controller = ComicController(blankPage: true);
      controller.addBubble(
        text: 'Drag Me',
        type: ComicBubbleType.mangaOval,
        x: 0.50,
        y: 0.50,
      );
      controller.deselectAll();
      expect(controller.selectedBubbleId, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicPageEditorWidget(
              controller: controller,
              onPanelTap: (_) {},
              onBubbleTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editorFinder = find.byType(ComicPageEditorWidget);
      expect(editorFinder, findsOneWidget);

      final center = tester.getCenter(editorFinder);
      final initialX = controller.activePage.bubbles.first.x;
      final initialY = controller.activePage.bubbles.first.y;

      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(40, 30));
      await tester.pump();
      await gesture.moveBy(const Offset(40, 30));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.selectedBubbleId, isNotNull);
      expect(controller.selectedBubble!.x, greaterThan(initialX));
      expect(controller.selectedBubble!.y, greaterThan(initialY));
    });

    testWidgets('Bubble inside a panel can be modified on 2nd interaction even if panel was selected', (tester) async {
      final controller = ComicController(blankPage: true);
      controller.addPanel(normalizedRect: const Rect.fromLTWH(0.05, 0.05, 0.90, 0.90));
      final panel = controller.selectedPanel!;
      expect(panel, isNotNull);

      controller.addBubble(
        text: 'Bubble In Panel',
        type: ComicBubbleType.mangaOval,
        x: 0.50,
        y: 0.50,
      );
      expect(controller.selectedBubbleId, isNotNull);

      // Simular que el usuario toca el panel (cambiando selección a la viñeta)
      controller.selectPanel(panel.id);
      expect(controller.selectedPanelId, panel.id);
      expect(controller.selectedBubbleId, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicPageEditorWidget(
              controller: controller,
              onPanelTap: (_) {},
              onBubbleTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editorFinder = find.byType(ComicPageEditorWidget);
      final center = tester.getCenter(editorFinder);

      // Ahora el usuario interactúa por 2da vez con el globo encima de la viñeta
      final initialBubbleX = controller.activePage.bubbles.first.x;
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(30, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(30, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Debe haber priorizado el globo, seleccionándolo y moviéndolo en vez de bloquearse con la viñeta
      expect(controller.selectedBubbleId, isNotNull);
      expect(controller.selectedBubble!.x, greaterThan(initialBubbleX));
    });
  });
}
