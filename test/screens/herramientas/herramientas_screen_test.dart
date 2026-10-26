import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/herramientas/herramientas_screen.dart';
import 'package:furi_app/screens/herramientas/dibujo/dibujo_screen.dart';
import 'package:furi_app/theme/app_theme.dart';

void main() {
  group('Herramientas & Dibujo Screen Tests', () {
    testWidgets('HerramientasScreen renders tools cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HerramientasScreen(mode: AppMode.dark),
        ),
      );

      expect(find.text('HERRAMIENTAS'), findsOneWidget);
      expect(find.text('DIBUJO DIGITAL'), findsOneWidget);
      expect(find.text('HISTORIETAS & COMIC'), findsOneWidget);
      expect(find.text('DISPONIBLE'), findsNWidgets(2));
      expect(find.text('EN ESPERA'), findsOneWidget);
    });

    testWidgets('DibujoScreen renders canvas and toolbars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DibujoScreen(),
        ),
      );

      // Verify Infinite Painter UI controls
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.byIcon(Icons.architecture), findsOneWidget);
      expect(find.byIcon(Icons.crop_free), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });
  });
}
