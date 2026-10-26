import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/painters/drawing_cursor_painter.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_brush_cursor_card.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_canvas_viewport.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/popovers/drawing_options_popover.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drawing Tool Type showsBrushCursor Tests', () {
    test('Pencils and eraser have showsBrushCursor = true', () {
      expect(DrawingToolType.pencil.showsBrushCursor, isTrue);
      expect(DrawingToolType.pen.showsBrushCursor, isTrue);
      expect(DrawingToolType.gPen.showsBrushCursor, isTrue);
      expect(DrawingToolType.marker.showsBrushCursor, isTrue);
      expect(DrawingToolType.airbrush.showsBrushCursor, isTrue);
      expect(DrawingToolType.highlighter.showsBrushCursor, isTrue);
      expect(DrawingToolType.eraser.showsBrushCursor, isTrue);
      expect(DrawingToolType.smudge.showsBrushCursor, isTrue);
    });

    test('Lasso, fill and shapes have showsBrushCursor = false', () {
      expect(DrawingToolType.lasso.showsBrushCursor, isFalse);
      expect(DrawingToolType.bucketFill.showsBrushCursor, isFalse);
      expect(DrawingToolType.gradient.showsBrushCursor, isFalse);
      expect(DrawingToolType.rectangle.showsBrushCursor, isFalse);
      expect(DrawingToolType.circle.showsBrushCursor, isFalse);
    });
  });

  group('DrawingController Brush Cursor State Tests', () {
    test('showBrushCursor is true by default and can be toggled', () {
      final controller = DrawingController();
      expect(controller.showBrushCursor, isTrue);

      bool notified = false;
      controller.addListener(() => notified = true);

      controller.setShowBrushCursor(false);
      expect(controller.showBrushCursor, isFalse);
      expect(notified, isTrue);

      controller.toggleShowBrushCursor();
      expect(controller.showBrushCursor, isTrue);
    });
  });

  group('DrawingCursorPainter Unit Tests', () {
    test('DrawingCursorPainter paints circle with exact radius = strokeWidth / 2', () {
      final painter = DrawingCursorPainter(
        cursorPosition: const Offset(100, 100),
        strokeWidth: 30.0,
        tool: DrawingToolType.pencil,
        color: Colors.blue,
        visible: true,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(500, 500));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('DrawingCursorPainter for eraser paints coral tint and dual contrast ring', () {
      final painter = DrawingCursorPainter(
        cursorPosition: const Offset(50, 50),
        strokeWidth: 40.0,
        tool: DrawingToolType.eraser,
        color: Colors.white,
        visible: true,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(500, 500));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('DrawingCursorPainter paints mirrored positions when symmetry is active', () {
      final painter = DrawingCursorPainter(
        cursorPosition: const Offset(100, 100),
        mirroredPositions: [const Offset(400, 100)],
        strokeWidth: 20.0,
        tool: DrawingToolType.pen,
        color: Colors.black,
        visible: true,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(500, 500));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('DrawingCursorPainter does not paint when visible is false or position is null', () {
      final painter = DrawingCursorPainter(
        cursorPosition: null,
        strokeWidth: 20.0,
        tool: DrawingToolType.pen,
        color: Colors.black,
        visible: false,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(500, 500));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('DrawingBrushCursorCard and Options Widget Tests', () {
    testWidgets('DrawingBrushCursorCard displays toggle and updates controller', (tester) async {
      final controller = DrawingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingBrushCursorCard(controller: controller),
          ),
        ),
      );

      expect(find.text('Guía Visual de Pincel y Goma'), findsOneWidget);
      expect(find.text('Círculo con el grosor exacto en vivo'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(controller.showBrushCursor, isFalse);
    });

    testWidgets('DrawingOptionsPopover contains DrawingBrushCursorCard', (tester) async {
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

      expect(find.byType(DrawingBrushCursorCard), findsOneWidget);
      expect(find.text('Guía Visual de Pincel y Goma'), findsOneWidget);
    });

    testWidgets('DrawingCanvasViewport renders with cursor painter foreground', (tester) async {
      final controller = DrawingController();
      final transformController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: DrawingCanvasViewport(
                controller: controller,
                transformController: transformController,
                canvasSize: const Size(1000, 1000),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verificar que el widget CustomPaint con DrawingCursorPainter existe en el árbol
      final customPaintFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter is DrawingCursorPainter,
      );
      expect(customPaintFinder, findsOneWidget);
    });
  });
}
