import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/notification_service.dart';
import 'helpers/pinterest_controller_factory.dart';
import 'services/pinterest_service.dart';
import 'widgets/pinterest_top_bar.dart';
import 'widgets/pinterest_credentials_banner.dart';
import 'widgets/pinterest_desktop_fallback.dart';

/// Pantalla integrada de Pinterest optimizada como PWA nativa,
/// con anti-crash por decodificadores de video, supresión de intents,
/// caché permanente y ocultamiento automático de credenciales al iniciar sesión.
class PinterestScreen extends StatefulWidget {
  const PinterestScreen({super.key});

  @override
  State<PinterestScreen> createState() => _PinterestScreenState();
}

class _PinterestScreenState extends State<PinterestScreen> {
  final PinterestService _service = PinterestService();
  WebViewController? _controller;
  Widget? _webViewWidget;
  Widget? _customWidget;
  bool _loading = true;
  double _progress = 0.0;
  bool _isMobile = false;
  bool _showCredentialsBar = true;
  bool _isLoggedIn = false;

  static const String _accountEmail = 'derrame_company@yahoo.com';
  static const String _accountPass = 'Zapallo1234*';

  @override
  void initState() {
    super.initState();
    _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    _service.init().then((_) {
      if (mounted) {
        setState(() {
          _isLoggedIn = _service.isLoggedIn;
          _showCredentialsBar = !_isLoggedIn;
        });
      }
    });

    _service.loggedInNotifier.addListener(_onAuthChanged);

    if (_isMobile) {
      NotificationService.onWebViewRendererGone = _handleRendererGone;
      _initWebView();
    }
  }

  @override
  void dispose() {
    _service.loggedInNotifier.removeListener(_onAuthChanged);
    if (NotificationService.onWebViewRendererGone == _handleRendererGone) {
      NotificationService.onWebViewRendererGone = null;
    }
    _customWidget = null;
    _webViewWidget = null;
    _controller = null;
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      _isLoggedIn = _service.isLoggedIn;
      if (_isLoggedIn) {
        _showCredentialsBar = false;
      }
    });
  }

  void _handleRendererGone() {
    if (!mounted) return;
    debugPrint('[Pinterest] Renderer process recuperado de forma segura');
    setState(() {
      _loading = true;
      _progress = 0.0;
      _webViewWidget = null;
      _controller = null;
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _initWebView(initialUrl: _service.currentUrl);
      }
    });
  }

  void _initWebView({String? initialUrl}) {
    final (ctrl, widget) = PinterestControllerFactory.create(
      startUrl: initialUrl ?? _service.currentUrl,
      service: _service,
      onProgressUpdate: (progress, loading) {
        if (!mounted) return;
        if (loading != _loading || (progress - _progress).abs() >= 0.15) {
          setState(() {
            _progress = progress;
            _loading = loading;
          });
        }
      },
      onCustomWidgetChange: (customWidget) {
        if (mounted) setState(() => _customWidget = customWidget);
      },
    );

    _controller = ctrl;
    _webViewWidget = widget;
  }

  Future<bool> _handleBack() async {
    try {
      if (_customWidget != null) {
        setState(() => _customWidget = null);
        return false;
      }
      if (_controller != null && await _controller!.canGoBack()) {
        await _controller!.goBack();
        return false;
      }
    } catch (_) {}
    return true;
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(_service.currentUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
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
                isLoggedIn: _isLoggedIn,
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
                          if (_customWidget != null)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black,
                                child: _customWidget!,
                              ),
                            ),
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
