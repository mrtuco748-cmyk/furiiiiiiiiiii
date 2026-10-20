import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Script y utilidades de limpieza visual para embeber Pinterest limpiamente en WebView.
class PinterestCleaner {
  static const String cleanerJs = '''
    (() => {
      try {
        const styleId = 'furi-pinterest-cleaner';
        if (!document.getElementById(styleId) && document.head) {
          const style = document.createElement('style');
          style.id = styleId;
          style.textContent = `
            div[data-test-id="app-upsell-banner"],
            div[data-test-id="full-page-signup-barrier"],
            div[data-test-id="smart-banner"],
            .appUpsell,
            .AppUpsellBanner,
            div[aria-label="Smart App Banner"],
            iframe[src*="smartbanner"] {
              display: none !important;
              visibility: hidden !important;
              pointer-events: none !important;
              height: 0 !important;
              max-height: 0 !important;
              overflow: hidden !important;
            }
            html, body {
              overflow-y: auto !important;
              -webkit-overflow-scrolling: touch !important;
            }
          `;
          document.head.appendChild(style);
        }
      } catch (_) {}
    })();
  ''';

  /// Inyecta las reglas CSS que ocultan banners molestos e instaladores de apps en Pinterest móvil.
  static Future<void> injectCleanerCss(WebViewController? controller) async {
    if (controller == null) return;
    try {
      await controller.runJavaScript(cleanerJs);
    } catch (e) {
      debugPrint('Error al inyectar CSS en Pinterest: $e');
    }
  }
}
