import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../services/notification_service.dart';
import '../services/pinterest_service.dart';
import '../widgets/pinterest_cleaner.dart';

/// Factoría para instanciar y configurar el WebViewController y WebViewWidget
/// de Pinterest con aceleración por hardware, PWA y canales JS.
class PinterestControllerFactory {
  static (WebViewController, Widget) create({
    required String startUrl,
    required PinterestService service,
    required void Function(double progress, bool loading) onProgressUpdate,
    required void Function(Widget? customWidget) onCustomWidgetChange,
  }) {
    WebViewController? ctrl;

    final delegate = NavigationDelegate(
      onProgress: (int progress) {
        onProgressUpdate(progress / 100.0, progress < 100);
      },
      onPageStarted: (String url) {
        if (url.startsWith('http')) {
          service.updateUrl(url);
        }
        PinterestCleaner.injectCleanerCss(ctrl);
        NotificationService.protectAndroidWebViews();
        onProgressUpdate(0.0, true);
      },
      onPageFinished: (String url) {
        if (url.startsWith('http')) {
          service.updateUrl(url);
        }
        PinterestCleaner.injectCleanerCss(ctrl);
        NotificationService.protectAndroidWebViews();
        service.flushCookies();
        service.verifyAuthStatus(ctrl);
        onProgressUpdate(1.0, false);
      },
      onWebResourceError: (WebResourceError error) {
        debugPrint('[Pinterest] Resource error: ${error.description}');
      },
      onNavigationRequest: (NavigationRequest request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null) return NavigationDecision.prevent;

        final scheme = uri.scheme.toLowerCase();
        if (scheme != 'http' && scheme != 'https') {
          return NavigationDecision.prevent;
        }

        final host = uri.host.toLowerCase();
        if (host.contains('play.google.com') || host.contains('apps.apple.com')) {
          return NavigationDecision.prevent;
        }

        // Permitir toda la navegación interna de Pinterest y proveedores de autenticación
        final isPinterestOrAuth = host.contains('pinterest.') ||
            host.contains('pinimg.com') ||
            host == 'pin.it' ||
            host.contains('google.com') ||
            host.contains('apple.com') ||
            host.contains('facebook.com') ||
            host.contains('recaptcha.net');
        if (isPinterestOrAuth) {
          return NavigationDecision.navigate;
        }

        // Si es un enlace externo fuera de Pinterest (tiendas, blogs, recetas):
        // Abrir en el navegador externo para no saturar el WebView de la app
        launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      },
    );

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF141414))
      ..setNavigationDelegate(delegate)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; SM-X910) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
      )
      ..addJavaScriptChannel(
        PinterestCleaner.channelName,
        onMessageReceived: (JavaScriptMessage msg) {
          PinterestCleaner.handleChannelMessage(msg.message, service);
        },
      );

    ctrl = controller;

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(true);

      androidController.setCustomWidgetCallbacks(
        onShowCustomWidget: (widget, onCustomWidgetHidden) {
          onCustomWidgetChange(widget);
        },
        onHideCustomWidget: () {
          onCustomWidgetChange(null);
        },
      );
    }

    PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(
      controller: controller.platform,
      layoutDirection: TextDirection.ltr,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
      },
    );

    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewWidgetCreationParams
          .fromPlatformWebViewWidgetCreationParams(
        params,
        displayWithHybridComposition: true,
      );
    }

    final webViewWidget = WebViewWidget.fromPlatformCreationParams(params: params);
    controller.loadRequest(Uri.parse(startUrl));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.protectAndroidWebViews();
    });

    return (controller, webViewWidget);
  }
}
