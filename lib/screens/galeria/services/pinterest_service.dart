import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../services/notification_service.dart';

/// Servicio singleton para gestionar el estado, la autenticación,
/// la persistencia de cookies y la optimización de Pinterest en F.U.R.I.
class PinterestService {
  static final PinterestService _instance = PinterestService._internal();
  factory PinterestService() => _instance;
  PinterestService._internal();

  static const String _prefKeyLoggedIn = 'furi_pinterest_logged_in_state';
  static const String _prefKeyLastNavUrl = 'furi_pinterest_last_nav_url';
  static const String _defaultUrl = 'https://www.pinterest.com/';

  bool _isLoggedIn = false;
  bool _initialized = false;
  String _currentUrl = _defaultUrl;

  bool get isLoggedIn => _isLoggedIn;
  String get currentUrl => _currentUrl;

  final ValueNotifier<bool> loggedInNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> urlNotifier = ValueNotifier<String>(_defaultUrl);

  /// Inicializa la sesión y última URL navegada desde SharedPreferences
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_prefKeyLoggedIn) ?? false;
      loggedInNotifier.value = _isLoggedIn;

      final savedUrl = prefs.getString(_prefKeyLastNavUrl);
      if (savedUrl != null &&
          savedUrl.isNotEmpty &&
          savedUrl.startsWith('http') &&
          !savedUrl.contains('intent:') &&
          !savedUrl.contains('market:')) {
        _currentUrl = savedUrl;
        urlNotifier.value = savedUrl;
      }

      // Comprobar cookies nativas en Android si estaban disponibles
      if (!kIsWeb && Platform.isAndroid) {
        final hasCookie = await NotificationService.checkPinterestAuthCookie();
        if (hasCookie && !_isLoggedIn) {
          await setLoggedIn(true);
        }
      }
    } catch (e) {
      debugPrint('[PinterestService] Error init: $e');
    }
  }

  /// Actualiza el estado de autenticación y lo persiste en disco
  Future<void> setLoggedIn(bool value) async {
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    loggedInNotifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyLoggedIn, value);
      if (!kIsWeb && Platform.isAndroid) {
        await NotificationService.flushWebViewCookies();
      }
    } catch (_) {}
  }

  /// Actualiza la URL activa de navegación SPA y la persiste en disco
  Future<void> updateUrl(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return;
    if (_currentUrl == url) return;

    // Si ya estamos autenticados y la URL recibida es un rebote a /login por error transitorio,
    // no pisar la última URL de navegación válida
    if (_isLoggedIn && url.contains('/login')) return;

    _currentUrl = url;
    urlNotifier.value = url;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLastNavUrl, url);
    } catch (_) {}
  }

  /// Valida el estado de autenticación analizando cookies o DOM
  Future<void> verifyAuthStatus(WebViewController? controller) async {
    if (controller == null) return;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final hasAuthCookie = await NotificationService.checkPinterestAuthCookie();
        if (hasAuthCookie) {
          setLoggedIn(true);
          return;
        }
      }

      // Evaluar cookies y marcadores en la página actual
      final dynamic res = await controller.runJavaScriptReturningResult('''
        (() => {
          try {
            const cookies = document.cookie || '';
            const hasSess = cookies.includes('_pinterest_sess') || cookies.includes('_auth=1');
            const hasProfile = !!document.querySelector('a[href*="/_saved/"], div[data-test-id="header-profile"], div[data-test-id="user-profile-button"], [data-test-id="mobile-bottom-nav"]');
            const isLoginPage = location.pathname.includes('/login') || !!document.querySelector('form[data-test-id="login-form"], input[name="id"]');
            if (isLoginPage) return false;
            return hasSess || hasProfile;
          } catch (_) {
            return false;
          }
        })();
      ''');

      final isAuth = res == true || res == 'true' || res == 1;
      setLoggedIn(isAuth);
    } catch (e) {
      debugPrint('[PinterestService] verifyAuthStatus error: $e');
    }
  }

  /// Guarda cookies nativas en disco inmediatamente
  Future<void> flushCookies() async {
    if (!kIsWeb && Platform.isAndroid) {
      await NotificationService.flushWebViewCookies();
    }
  }
}
