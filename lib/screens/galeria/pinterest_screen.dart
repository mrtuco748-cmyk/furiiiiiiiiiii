import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../services/notification_service.dart';
import 'widgets/pinterest_top_bar.dart';
import 'widgets/pinterest_credentials_banner.dart';
import 'widgets/pinterest_desktop_fallback.dart';

/// Pantalla integrada de Pinterest sin barras de navegador
/// para que se sienta 100% nativa dentro de F.U.R.I.
class PinterestScreen extends StatefulWidget {
  const PinterestScreen({super.key});

  @override
  State<PinterestScreen> createState() => _PinterestScreenState();
}

class _PinterestScreenState extends State<PinterestScreen> {
  WebViewController? _controller;
  Widget? _webViewWidget;
  bool _loading = true;
  double _progress = 0.0;
  bool _isMobile = false;
  bool _showCredentialsBar = true;
  String _lastUrl = 'https://www.pinterest.com/';

  static const String _accountEmail = 'derrame_company@yahoo.com';
  static const String _accountPass = 'Zapallo1234*';

  @override
  void initState() {
    super.initState();
    _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (_isMobile) {
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}

      NotificationService.onWebViewRendererGone = _handleRendererGone;
      _initWebView();
    }
  }

  @override
  void dispose() {
    if (NotificationService.onWebViewRendererGone == _handleRendererGone) {
      NotificationService.onWebViewRendererGone = null;
    }
    _webViewWidget = null;
    _controller = null;
    super.dispose();
  }

  void _handleRendererGone() {
    if (!mounted) return;
    debugPrint('Pinterest WebView renderer process gone: recreando WebView de forma segura');
    setState(() {
      _loading = true;
      _progress = 0.0;
      _webViewWidget = null;
      _controller = null;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _initWebView(initialUrl: _lastUrl);
      }
    });
  }

  void _initWebView({String initialUrl = 'https://www.pinterest.com/'}) {
    final delegate = NavigationDelegate(
      onProgress: (int progress) {
        if (!mounted) return;
        final newProgress = progress / 100.0;
        final newLoading = progress < 100;
        if (newLoading != _loading || (newProgress - _progress).abs() >= 0.15) {
          setState(() {
            _progress = newProgress;
            _loading = newLoading;
          });
        }
      },
      onPageStarted: (String url) {
        if (url.startsWith('http')) {
          _lastUrl = url;
        }
        NotificationService.protectAndroidWebViews();
        if (mounted && !_loading) {
          setState(() => _loading = true);
        }
      },
      onPageFinished: (String url) {
        if (url.startsWith('http')) {
          _lastUrl = url;
        }
        NotificationService.protectAndroidWebViews();
        if (mounted && _loading) {
          setState(() => _loading = false);
        }
        _injectCleanerCss();
      },
      onWebResourceError: (WebResourceError error) {
        debugPrint('Pinterest WebView Error: ${error.description}');
      },
      onNavigationRequest: (!kIsWeb && Platform.isAndroid)
          ? null
          : (NavigationRequest request) {
              final uri = Uri.tryParse(request.url);
              if (uri == null) return NavigationDecision.prevent;

              final scheme = uri.scheme.toLowerCase();
              if (scheme != 'http' && scheme != 'https') {
                return NavigationDecision.prevent;
              }

              final host = uri.host.toLowerCase();
              if (host.contains('play.google.com') ||
                  host.contains('apps.apple.com')) {
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
    );

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF141414))
      ..setNavigationDelegate(delegate)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
      );

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(true);

      androidController.setCustomWidgetCallbacks(
        onShowCustomWidget: (widget, onCustomWidgetHidden) {
          onCustomWidgetHidden();
        },
        onHideCustomWidget: () {
          // No-op: nunca hacer pop() de la ruta de Flutter
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
        displayWithHybridComposition: false,
      );
    }

    _controller = controller;
    _webViewWidget = WebViewWidget.fromPlatformCreationParams(params: params);

    controller.loadRequest(Uri.parse(initialUrl));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.protectAndroidWebViews();
    });
  }

  Future<void> _injectCleanerCss() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    try {
      await ctrl.runJavaScript('''
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
      ''');
    } catch (e) {
      debugPrint('Error al inyectar CSS en Pinterest: $e');
    }
  }

  Future<bool> _handleBack() async {
    try {
      if (_controller != null && await _controller!.canGoBack()) {
        await _controller!.goBack();
        return false;
      }
    } catch (_) {}
    return true;
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(_lastUrl.isNotEmpty ? _lastUrl : 'https://www.pinterest.com');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final shouldPop = await _handleBack();
        if (shouldPop && mounted) {
          nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF141414),
        body: SafeArea(
          child: Column(
            children: [
              PinterestTopBar(
                isMobile: _isMobile,
                hasController: _controller != null,
                showCredentialsBar: _showCredentialsBar,
                onBack: () async {
                  final nav = Navigator.of(context);
                  final shouldPop = await _handleBack();
                  if (shouldPop && mounted) nav.pop();
                },
                onToggleCredentials: () {
                  setState(() => _showCredentialsBar = !_showCredentialsBar);
                },
                onReload: () {
                  _controller?.loadRequest(Uri.parse('https://www.pinterest.com/'));
                },
                onClose: () => Navigator.of(context).pop(),
              ),
              if (_showCredentialsBar)
                PinterestCredentialsBanner(
                  accountEmail: _accountEmail,
                  accountPass: _accountPass,
                  onClose: () => setState(() => _showCredentialsBar = false),
                ),
              Expanded(
                child: _isMobile && _webViewWidget != null
                    ? Stack(
                        children: [
                          Positioned.fill(child: _webViewWidget!),
                          if (_loading)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(
                                value: _progress > 0 ? _progress : null,
                                backgroundColor: const Color(0xFF222222),
                                color: const Color(0xFFE60023),
                                minHeight: 2.5,
                              ),
                            ),
                        ],
                      )
                    : PinterestDesktopFallback(
                        accountEmail: _accountEmail,
                        accountPass: _accountPass,
                        onOpenExternal: _openExternal,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
