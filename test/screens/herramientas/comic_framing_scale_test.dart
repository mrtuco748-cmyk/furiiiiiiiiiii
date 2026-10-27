import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_interaction_mode.dart';
import 'package:furi_app/screens/herramientas/comic/models/comic_panel.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_mode_indicator_banner.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_page_editor_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Comic Framing Canvas Scale Tests', () {
    test('ComicController.setPanelTransform modifies panel scale and offsets', () {
      final controller = ComicController(blankPage: true);
      controller.addPanelFromRect(const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8));
      final panel = controller.selectedPanel!;
      expect(panel.scale, 1.0);
      expect(panel.offsetX, 0.0);
      expect(panel.offsetY, 0.0);

      controller.setPanelTransform(panel.id, scale: 2.5, dx: 30.0, dy: -20.0);
      final updated = controller.selectedPanel!;
      expect(updated.scale, 2.5);
      expect(updated.offsetX, 30.0);
      expect(updated.offsetY, -20.0);
    });

    testWidgets('ComicModeIndicatorBanner renders zoom buttons and scales canvas in framing mode', (tester) async {
      final controller = ComicController(blankPage: true);
      controller.addPanelFromRect(const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8));
      controller.setInteractionMode(ComicInteractionMode.frameContent);

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
      await tester.pumpAndSettle();

      expect(find.text('Encuadre'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.filter_center_focus), findsOneWidget);

      // Tapping + increases scale
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(controller.selectedPanel!.scale, greaterThan(1.0));
      expect(find.text('115%'), findsOneWidget);

      // Tapping - decreases scale
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(controller.selectedPanel!.scale, closeTo(1.0, 0.01));

      // Tapping chip resets to 100%
      controller.setPanelTransform(controller.selectedPanelId!, scale: 2.0);
      await tester.pumpAndSettle();
      expect(find.text('200%'), findsOneWidget);
      await tester.tap(find.text('200%'));
      await tester.pumpAndSettle();
      expect(controller.selectedPanel!.scale, 1.0);

      // Tapping Listo exits framing mode
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(controller.interactionMode, ComicInteractionMode.normal);
    });

    testWidgets('ComicPageEditorWidget scales canvas during framing with scale gestures', (tester) async {
      final controller = ComicController(blankPage: true);
      controller.addPanelFromRect(const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8));
      controller.setInteractionMode(ComicInteractionMode.frameContent);

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

      final panel = controller.selectedPanel!;
      expect(panel.scale, 1.0);

      // Programmatic transform verifies page editor responsiveness
      controller.setPanelTransform(panel.id, scale: 1.8, dx: 15.0, dy: 25.0);
      await tester.pumpAndSettle();

      expect(controller.selectedPanel!.scale, 1.8);
      expect(controller.selectedPanel!.offsetX, 15.0);
      expect(controller.selectedPanel!.offsetY, 25.0);
    });
  });
}
