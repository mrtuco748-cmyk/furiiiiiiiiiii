import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_controller.dart';
import 'package:furi_app/screens/herramientas/dibujo/controllers/drawing_stroke_stabilizer.dart';
import 'package:furi_app/screens/herramientas/dibujo/models/drawing_tool_type.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_infinite_dock.dart';
import 'package:furi_app/screens/herramientas/dibujo/widgets/drawing_predictive_stroke_card.dart';
import 'package:furi_app/screens/herramientas/widgets/creative_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drawing Stroke Stabilizer & Anti-Jitter Tests', () {
    test('DrawingStrokeStabilizer ignores sub-pixel jitter < 1.0 px', () {
      final stabilizer = DrawingStrokeStabilizer();
      stabilizer.start(const Offset(100, 100));

      final (point, shouldSkip) = stabilizer.update(
        const Offset(100.4, 100.3),
        isPredictiveEnabled: false,
        predictiveLevel: 5,
      );

      expect(shouldSkip, isTrue);
      expect(point, const Offset(100, 100));
    });

    test('DrawingStrokeStabilizer applies subtle low-pass smoothing on normal movements', () {
      final stabilizer = DrawingStrokeStabilizer();
      stabilizer.start(const Offset(100, 100));

      final (point, shouldSkip) = stabilizer.update(
        const Offset(110, 100),
        isPredictiveEnabled: false,
        predictiveLevel: 5,
      );

      expect(shouldSkip, isFalse);
      // Con weight = 0.72, 100 + 10 * 0.72 = 107.2 (suavizado natural sin temblor)
      expect(point.dx, closeTo(107.2, 0.1));
      expect(point.dy, closeTo(100.0, 0.1));
    });

    test('DrawingStrokeStabilizer preserves sharp corners', () {
      // Movimiento hacia la derecha y quiebre brusco hacia abajo
      final smoothed = DrawingStrokeStabilizer.filterMicroJitter(
        currentRaw: const Offset(110, 120),
        lastSmoothed: const Offset(110, 100),
        prevRaw: const Offset(90, 100),
      );

      // En quiebre agudo de 90 grados, el factor es 0.94 (no redondea la esquina)
      expect(smoothed.dy, greaterThan(118.0));
    });

    test('DrawingStrokeStabilizer predictive stroke scales with level 1 to 10', () {
      final stabilizer = DrawingStrokeStabilizer();
      stabilizer.start(const Offset(50, 50));

      // Nivel 1: Seguimiento ágil
      final (p1, _) = stabilizer.update(
        const Offset(70, 50),
        isPredictiveEnabled: true,
        predictiveLevel: 1,
      );

      stabilizer.start(const Offset(50, 50));
      // Nivel 10: Mayor amortiguación predictiva sedosa
      final (p10, _) = stabilizer.update(
        const Offset(70, 50),
        isPredictiveEnabled: true,
        predictiveLevel: 10,
      );

      expect(p1.dx, isNot(equals(p10.dx)));
    });

    test('DrawingStrokeStabilizer finish generates ending connection points', () {
      final stabilizer = DrawingStrokeStabilizer();
      stabilizer.start(const Offset(10, 10));
      stabilizer.update(const Offset(30, 30), isPredictiveEnabled: true, predictiveLevel: 8);

      final ending = stabilizer.finish(1.0);
      expect(ending, isNotEmpty);
      expect(ending.last.offset, const Offset(30, 30));
    });
  });

  group('DrawingController Predictive Stroke State & Real-time Integration', () {
    test('Controller handles predictive stroke toggle and level clamping (1 to 10)', () {
      final controller = DrawingController();
      expect(controller.isPredictiveStrokeEnabled, isFalse);
      expect(controller.predictiveStrokeLevel, 5);

      controller.setPredictiveStrokeEnabled(true);
      expect(controller.isPredictiveStrokeEnabled, isTrue);

      controller.setPredictiveStrokeLevel(10);
      expect(controller.predictiveStrokeLevel, 10);

      controller.setPredictiveStrokeLevel(15);
      expect(controller.predictiveStrokeLevel, 10); // Clamped at 10

      controller.setPredictiveStrokeLevel(0);
      expect(controller.predictiveStrokeLevel, 1); // Clamped at 1
    });

    test('Controller stabilizes freehand stroke in real-time', () {
      final controller = DrawingController();
      controller.selectTool(DrawingToolType.pen);

      controller.startStroke(const Offset(100, 100));
      expect(controller.activeStroke, isNotNull);
      expect(controller.activeStroke!.points.length, 1);

      // Micro-temblor insignificante (< 1.0 px) no agrega punto tembloroso
      controller.updateStroke(const Offset(100.2, 100.3));
      expect(controller.activeStroke!.points.length, 1);

      // Movimiento real agrega punto suavizado
      controller.updateStroke(const Offset(115, 100));
      expect(controller.activeStroke!.points.length, 2);

      controller.endStroke();
      expect(controller.activeStroke, isNull);
      expect(controller.activeLayer.strokes.length, 1);
    });
  });

  group('DrawingPredictiveStrokeCard Widget Tests', () {
    testWidgets('Renders toggle and slider from 1 to 10', (tester) async {
      final controller = DrawingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => DrawingPredictiveStrokeCard(controller: controller),
            ),
          ),
        ),
      );

      expect(find.text('Trazo Predictivo'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Activar switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(controller.isPredictiveStrokeEnabled, isTrue);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('5 / 10'), findsOneWidget);
    });
  });

  group('Eraser Icon Visual Tests', () {
    test('DrawingToolType.eraser returns proper eraser icon', () {
      expect(DrawingToolType.eraser.svgAsset, 'eraser');
      expect(DrawingToolType.eraser.icon, isNot(Icons.auto_fix_high));
    });

    testWidgets('DrawingInfiniteDock renders CreativeIcon eraser', (tester) async {
      final controller = DrawingController();
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

      final creativeIconFinder = find.byWidgetPredicate(
        (w) => w is CreativeIcon && w.assetName == 'eraser',
      );
      expect(creativeIconFinder, findsOneWidget);
    });
  });
}
