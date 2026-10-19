import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:furi_app/providers/music_player_provider.dart';
import 'package:furi_app/services/notification_service.dart';
import 'package:furi_app/widgets/furi_global_overlay.dart';

void main() {
  testWidgets('InAppNotificationItem emits and displays properly in FuriGlobalOverlay',
      (WidgetTester tester) async {
    final musicPv = MusicPlayerProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MusicPlayerProvider>.value(value: musicPv),
        ],
        child: MaterialApp(
          home: FuriGlobalOverlay(
            child: const Scaffold(
              body: Center(child: Text('Main Screen Content')),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Main Screen Content'), findsOneWidget);

    // Emitir notificación in-app personalizada
    NotificationService.showInAppNotification(InAppNotificationItem(
      title: 'Rocío ❤️',
      body: 'Te mandé una cartita nueva',
      data: {'type': 'letter'},
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Debe mostrarse el título y el cuerpo de la notificación
    expect(find.text('Rocío ❤️'), findsOneWidget);
    expect(find.text('Te mandé una cartita nueva'), findsOneWidget);
    expect(find.text('CARTA'), findsOneWidget);
  });
}
