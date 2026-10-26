import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/screens/galeria/widgets/pinterest_top_bar.dart';
import 'package:furi_app/screens/galeria/widgets/pinterest_credentials_banner.dart';

void main() {
  testWidgets('PinterestTopBar renderiza correctamente y responde a callbacks', (tester) async {
    bool toggled = false;
    bool reloaded = false;
    bool closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinterestTopBar(
            isMobile: true,
            hasController: true,
            showCredentialsBar: false,
            isLoggedIn: true,
            onBack: () {},
            onToggleCredentials: () => toggled = true,
            onReload: () => reloaded = true,
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    expect(find.text('PINTEREST'), findsOneWidget);
    expect(find.byIcon(Icons.vpn_key_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.vpn_key_rounded));
    expect(toggled, isTrue);

    await tester.tap(find.byIcon(Icons.home_rounded));
    expect(reloaded, isTrue);

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closed, isTrue);
  });

  testWidgets('PinterestCredentialsBanner muestra correo y clave con botón de cierre', (tester) async {
    bool closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinterestCredentialsBanner(
            accountEmail: 'test@yahoo.com',
            accountPass: 'Secret123*',
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    expect(find.text('Copiar Correo'), findsOneWidget);
    expect(find.text('Copiar Clave'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closed, isTrue);
  });
}
