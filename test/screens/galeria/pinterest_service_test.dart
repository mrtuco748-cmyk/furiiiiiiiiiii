import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:furi_app/screens/galeria/services/pinterest_service.dart';
import 'package:furi_app/screens/galeria/widgets/pinterest_cleaner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PinterestService Tests', () {
    test('Inicialización y persistencia de sesión', () async {
      final service = PinterestService();
      await service.init();
      expect(service.isLoggedIn, isFalse);

      await service.setLoggedIn(true);
      expect(service.isLoggedIn, isTrue);
      expect(service.loggedInNotifier.value, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('furi_pinterest_logged_in_state'), isTrue);

      await service.setLoggedIn(false);
      expect(service.isLoggedIn, isFalse);
      expect(service.loggedInNotifier.value, isFalse);
    });

    test('Actualización y normalización de URL activa', () {
      final service = PinterestService();
      expect(service.currentUrl, 'https://www.pinterest.com/');

      service.updateUrl('https://www.pinterest.com/pin/123456789/');
      expect(service.currentUrl, 'https://www.pinterest.com/pin/123456789/');
      expect(service.urlNotifier.value, 'https://www.pinterest.com/pin/123456789/');

      // Ignora URLs no-http o vacías
      service.updateUrl('');
      expect(service.currentUrl, 'https://www.pinterest.com/pin/123456789/');

      service.updateUrl('intent://pinterest.com/pin/123');
      expect(service.currentUrl, 'https://www.pinterest.com/pin/123456789/');
    });
  });

  group('PinterestCleaner Tests', () {
    test('Procesamiento de mensajes desde JavaScriptChannel', () async {
      final service = PinterestService();
      await service.setLoggedIn(false);

      // Mensaje de cambio de URL y autenticación
      const jsonMessage = '{"url":"https://www.pinterest.com/_saved/","isLoggedIn":true}';
      PinterestCleaner.handleChannelMessage(jsonMessage, service);

      expect(service.currentUrl, 'https://www.pinterest.com/_saved/');
      expect(service.isLoggedIn, isTrue);

      // Mensaje con formato incorrecto no debe fallar
      PinterestCleaner.handleChannelMessage('invalid_json', service);
      expect(service.isLoggedIn, isTrue);
    });

    test('El script cleanerJs contiene protecciones críticas', () {
      expect(PinterestCleaner.channelName, 'FuriPinterest');
      expect(PinterestCleaner.cleanerJs, contains('standalone'));
      expect(PinterestCleaner.cleanerJs, contains('isExternalIntent'));
      expect(PinterestCleaner.cleanerJs, contains('HTMLMediaElement.prototype.play'));
      expect(PinterestCleaner.cleanerJs, contains('sanitizeMedia'));
      expect(PinterestCleaner.cleanerJs, contains('furi-pinterest-cleaner'));
      expect(PinterestCleaner.cleanerJs, contains('app_upsell_dismissed'));
    });
  });
}
