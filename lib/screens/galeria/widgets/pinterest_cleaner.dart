import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/pinterest_service.dart';

/// Script y utilidades de optimización visual, anti-crash y persistencia
/// para que Pinterest funcione rápido, fluido y sin reinicios en F.U.R.I.
class PinterestCleaner {
  static const String channelName = 'FuriPinterest';

  static const String cleanerJs = '''
    (() => {
      try {
        // 1. Simulación de PWA Standalone para evitar banners y redirecciones de app
        try {
          Object.defineProperty(navigator, 'standalone', { get: () => true, configurable: true });
        } catch (_) {}

        if (window.matchMedia) {
          const origMatch = window.matchMedia;
          window.matchMedia = function(q) {
            if (q && (q.includes('display-mode: standalone') || q.includes('display-mode: fullscreen'))) {
              return {
                matches: true,
                media: q,
                onchange: null,
                addListener: function() {},
                removeListener: function() {},
                addEventListener: function() {},
                removeEventListener: function() {},
                dispatchEvent: function() { return false; }
              };
            }
            return origMatch.apply(this, arguments);
          };
        }

        // Pre-sembrar flags de no-upsell
        try {
          document.cookie = "app_upsell_dismissed=true; path=/; max-age=31536000; SameSite=Lax";
          document.cookie = "_pinterest_pf_installed=true; path=/; max-age=31536000; SameSite=Lax";
          localStorage.setItem('hide_app_upsell', 'true');
          localStorage.setItem('app_banner_dismissed', 'true');
        } catch (_) {}

        // 2. Neutralizar enlaces e intentos de salto a intent:// o tiendas que reinician la página
        const isExternalIntent = (url) => {
          if (!url || typeof url !== 'string') return false;
          const u = url.toLowerCase();
          return u.startsWith('intent:') || u.startsWith('pinterest:') || 
                 u.startsWith('market:') || u.startsWith('android-app:') ||
                 u.includes('play.google.com') || u.includes('apps.apple.com');
        };

        const origAssign = window.location.assign;
        window.location.assign = function(url) {
          if (isExternalIntent(url)) return;
          return origAssign.apply(this, arguments);
        };

        const origReplace = window.location.replace;
        window.location.replace = function(url) {
          if (isExternalIntent(url)) return;
          return origReplace.apply(this, arguments);
        };

        document.addEventListener('click', (e) => {
          const a = e.target && e.target.closest ? e.target.closest('a') : null;
          if (a && a.href && isExternalIntent(a.href)) {
            e.preventDefault();
            e.stopPropagation();
          }
        }, true);

        // 3. Prevenir agotamiento de decodificadores de hardware por videos en segundo plano
        try {
          const origPlay = HTMLMediaElement.prototype.play;
          HTMLMediaElement.prototype.play = function() {
            if (this.tagName === 'VIDEO' && this.autoplay && !this.dataset.userActive) {
              this.pause();
              return Promise.resolve();
            }
            return origPlay.apply(this, arguments);
          };
        } catch (_) {}

        // 4. Inyección de reglas CSS para ocultamiento instantáneo sin alterar React 18
        const styleId = 'furi-pinterest-cleaner';
        if (!document.getElementById(styleId) && document.head) {
          const style = document.createElement('style');
          style.id = styleId;
          style.textContent = `
            div[data-test-id="app-upsell-banner"],
            div[data-test-id="full-page-signup-barrier"],
            div[data-test-id="smart-banner"],
            div[data-test-id="header-app-upsell"],
            div[data-test-id="native-app-upsell"],
            div[data-test-id="inline-app-upsell"],
            div[data-test-id="open-in-app-button"],
            div[data-test-id="growth-app-upsell"],
            div[data-test-id="mweb-unauth-header"],
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

        // 5. Monitoreo reactivo de navegación SPA y estado de sesión
        const notifyDart = () => {
          try {
            if (!window.FuriPinterest) return;
            const cookies = document.cookie || '';
            const isLoginPage = location.pathname.includes('/login') || !!document.querySelector('form[data-test-id="login-form"], input[name="id"]');
            const hasSess = cookies.includes('_pinterest_sess') || cookies.includes('_auth=1');
            const hasProfile = !!document.querySelector('a[href*="/_saved/"], div[data-test-id="header-profile"], div[data-test-id="user-profile-button"], [data-test-id="mobile-bottom-nav"]');
            const loggedIn = !isLoginPage && (hasSess || hasProfile);

            window.FuriPinterest.postMessage(JSON.stringify({
              type: 'state_update',
              url: location.href,
              isLoggedIn: loggedIn
            }));
          } catch (_) {}
        };

        const wrapHistory = (type) => {
          const orig = history[type];
          return function() {
            const rv = orig.apply(this, arguments);
            setTimeout(notifyDart, 80);
            return rv;
          };
        };
        history.pushState = wrapHistory('pushState');
        history.replaceState = wrapHistory('replaceState');
        window.addEventListener('popstate', () => setTimeout(notifyDart, 80));

        setTimeout(notifyDart, 200);
        setTimeout(notifyDart, 1500);
      } catch (_) {}
    })();
  ''';

  /// Inyecta las optimizaciones anti-crash, PWA y reglas de CSS en el WebView
  static Future<void> injectCleanerCss(WebViewController? controller) async {
    if (controller == null) return;
    try {
      await controller.runJavaScript(cleanerJs);
    } catch (e) {
      debugPrint('Error al inyectar script en Pinterest: $e');
    }
  }

  /// Procesa los mensajes recibidos a través del canal JavaScript FuriPinterest
  static void handleChannelMessage(String message, PinterestService service) {
    try {
      final data = jsonDecode(message);
      if (data is Map) {
        if (data['url'] is String) {
          service.updateUrl(data['url'] as String);
        }
        if (data['isLoggedIn'] is bool) {
          service.setLoggedIn(data['isLoggedIn'] as bool);
        }
      }
    } catch (_) {}
  }
}
