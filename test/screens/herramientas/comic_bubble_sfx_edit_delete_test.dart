import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/comic/comic_editor_screen.dart';
import 'package:furi_app/screens/herramientas/comic/controllers/comic_controller.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_floating_bubble_bar.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_sfx_editor_bar.dart';
import 'package:furi_app/screens/herramientas/comic/widgets/comic_transform_resolver.dart';

void main() {
  group('Comic Bubble and SFX Edit and Delete Tests', () {
    test('ComicTransformResolver detects taps on bubbles and wide SFX accurately', () {
      final controller = ComicController(blankPage: true);
      controller.addBubble(text: 'Hola amor', x: 0.5, y: 0.5);
      controller.addSfx('¡KAAAABOOOM!', x: 0.3, y: 0.3);

      const pageSize = Size(400, 600);
      // Tap on center of bubble
      final tappedBubble = ComicTransformResolver.findTappedBubble(controller, const Offset(200, 300), pageSize);
      expect(tappedBubble, isNotNull);
      expect(tappedBubble!.text, 'Hola amor');

      // Tap on the edge of the wide SFX text
      final tappedSfx = ComicTransformResolver.findTappedSfx(controller, const Offset(130, 180), pageSize);
      expect(tappedSfx, isNotNull);
      expect(tappedSfx!.text, '¡KAAAABOOOM!');
    });

    testWidgets('Tapping a bubble shows ComicFloatingBubbleBar with delete icon and deletes bubble', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ComicEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Encontrar el ComicEditorScreen y su controller
      final screenState = tester.state(find.byType(ComicEditorScreen));
      // Agregar un globo vía controller directamente
      dynamic dynState = screenState;
      final ComicController controller = dynState.controller ?? screenState;
      controller.addBubble(text: 'Mi diálogo de prueba');
      await tester.pumpAndSettle();

      // Debe aparecer el ComicFloatingBubbleBar
      expect(find.byType(ComicFloatingBubbleBar), findsOneWidget);

      // El icono de papelera de borrado debe estar presente
      final deleteIcon = find.descendant(
        of: find.byType(ComicFloatingBubbleBar),
        matching: find.byIcon(Icons.delete_outline),
      );
      expect(deleteIcon, findsOneWidget);

      // Tocar el botón de borrar
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // El globo debe haber sido eliminado de la página
      expect(controller.activePage.bubbles, isEmpty);
      expect(controller.selectedBubble, isNull);
    });

    testWidgets('Tapping an SFX shows ComicSfxEditorBar with delete icon and deletes SFX', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ComicEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final screenState = tester.state(find.byType(ComicEditorScreen));
      dynamic dynState = screenState;
      final ComicController controller = dynState.controller ?? screenState;
      controller.addSfx('¡BOOM!');
      await tester.pumpAndSettle();

      // Debe aparecer el ComicSfxEditorBar
      expect(find.byType(ComicSfxEditorBar), findsOneWidget);

      // El icono de papelera de borrado debe estar presente
      final deleteIcon = find.descendant(
        of: find.byType(ComicSfxEditorBar),
        matching: find.byIcon(Icons.delete_outline),
      );
      expect(deleteIcon, findsOneWidget);

      // Tocar el botón de borrar
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // El SFX debe haber sido eliminado de la página
      expect(controller.activePage.sfxStickers, isEmpty);
      expect(controller.selectedSfx, isNull);
    });

    testWidgets('Editing bubble text in ComicFloatingBubbleBar updates controller live', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ComicEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final screenState = tester.state(find.byType(ComicEditorScreen));
      dynamic dynState = screenState;
      final ComicController controller = dynState.controller ?? screenState;
      controller.addBubble(text: 'Original');
      await tester.pumpAndSettle();

      expect(find.byType(ComicFloatingBubbleBar), findsOneWidget);

      final textFieldFinder = find.descendant(
        of: find.byType(ComicFloatingBubbleBar),
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'Texto Editado');
      await tester.pumpAndSettle();

      expect(controller.selectedBubble?.text, 'Texto Editado');
      expect(controller.activePage.bubbles.first.text, 'Texto Editado');
    });

    testWidgets('Editing SFX text in ComicSfxEditorBar updates controller live', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ComicEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final screenState = tester.state(find.byType(ComicEditorScreen));
      dynamic dynState = screenState;
      final ComicController controller = dynState.controller ?? screenState;
      controller.addSfx('CRASH');
      await tester.pumpAndSettle();

      expect(find.byType(ComicSfxEditorBar), findsOneWidget);

      final textFieldFinder = find.descendant(
        of: find.byType(ComicSfxEditorBar),
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'KABOOM');
      await tester.pumpAndSettle();

      expect(controller.selectedSfx?.text, 'KABOOM');
      expect(controller.activePage.sfxStickers.first.text, 'KABOOM');
    });
  });
}
