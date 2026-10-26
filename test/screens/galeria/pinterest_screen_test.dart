import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/galeria/pinterest_screen.dart';
import 'package:furi_app/screens/galeria/widgets/pinterest_desktop_fallback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PinterestScreen en Desktop renderiza fallback con correo y clave', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PinterestScreen(),
      ),
    );
    await tester.pump();

    // En entorno de test de escritorio (no Android/iOS), se renderiza PinterestDesktopFallback
    expect(find.byType(PinterestDesktopFallback), findsOneWidget);
    expect(find.text('Copiar Correo'), findsWidgets);
    expect(find.text('Copiar Clave'), findsWidgets);
    expect(find.text('Abrir Pinterest'), findsOneWidget);
  });
}
