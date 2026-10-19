import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Pantalla integrada de Pinterest sin barras de navegador
/// para que se sienta 100% nativa dentro de F.U.R.I.
class PinterestScreen extends StatefulWidget {
  const PinterestScreen({super.key});

  @override
  State<PinterestScreen> createState() => _PinterestScreenState();
}

class _PinterestScreenState extends State<PinterestScreen> {
  WebViewController? _controller;
  bool _loading = true;
  double _progress = 0.0;
  bool _isMobile = false;

  static const String _autoEmail = 'derrame_company@yahoo.com';
  static const String _autoPass = 'Tradden20';

  @override
  void initState() {
    super.initState();
    _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (_isMobile) {
      _initWebView();
    }
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF141414))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
                _loading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _loading = false);
            // Ocultar banners molestos y automatizar inicio de sesión si es necesario
            _injectCleanerCss();
            _injectAutoLogin();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Pinterest WebView Error: ${error.description}');
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
      )
      ..loadRequest(Uri.parse('https://www.pinterest.com/login/'));

    _controller = controller;
  }

  Future<void> _injectAutoLogin() async {
    if (_controller == null) return;
    try {
      await _controller!.runJavaScript('''
        (() => {
          function setNativeValue(el, val) {
            if (!el) return false;
            const proto = Object.getPrototypeOf(el);
            const set = Object.getOwnPropertyDescriptor(proto, 'value')?.set || Object.getOwnPropertyDescriptor(el, 'value')?.set;
            if (set) {
              set.call(el, val);
            } else {
              el.value = val;
            }
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
          }

          function performAutoLogin() {
            const email = document.querySelector('#email, input[type="email"], input[name="id"]');
            const pass = document.querySelector('#password, input[type="password"]');
            const btn = document.querySelector('button[type="submit"]');

            if (email && pass) {
              setNativeValue(email, '$_autoEmail');
              setNativeValue(pass, '$_autoPass');
              setTimeout(() => {
                const submit = document.querySelector('button[type="submit"]') || btn;
                if (submit) submit.click();
              }, 300);
              return true;
            }
            return false;
          }

          // Intento inmediato
          if (!performAutoLogin()) {
            let attempts = 0;
            const interval = setInterval(() => {
              attempts++;
              if (performAutoLogin() || attempts > 16) {
                clearInterval(interval);
              }
            }, 500);
          }
        })();
      ''');
    } catch (e) {
      debugPrint('Error en auto-login Pinterest: $e');
    }
  }

  Future<void> _injectCleanerCss() async {
    if (_controller == null) return;
    try {
      await _controller!.runJavaScript('''
        (() => {
          const style = document.createElement('style');
          style.innerHTML = `
            div[data-test-id="app-upsell-banner"],
            div[data-test-id="full-page-signup-barrier"],
            .appUpsell,
            .AppUpsellBanner,
            div[aria-label="banner"],
            div[aria-label="Smart App Banner"] {
              display: none !important;
            }
          `;
          document.head.appendChild(style);
        })();
      ''');
    } catch (e) {
      debugPrint('Error al inyectar CSS en Pinterest: $e');
    }
  }

  Future<bool> _handleBack() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
      return false;
    }
    return true;
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse('https://www.pinterest.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        backgroundColor: const Color(0xFF141414), // Fondo sólido sin negro puro
        body: SafeArea(
          child: Column(
            children: [
              // Cabecera superior nativa F.U.R.I
              _buildTopBar(),

              // Barra de progreso delgada si está cargando
              if (_loading && _isMobile)
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: const Color(0xFF222222),
                  color: const Color(0xFFE60023), // Rojo Pinterest sólido
                  minHeight: 2.5,
                ),

              // Contenido webview nativo (móvil) o lanzador (desktop)
              Expanded(
                child: _isMobile && _controller != null
                    ? WebViewWidget(controller: _controller!)
                    : _buildDesktopFallback(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF181818),
      child: Row(
        children: [
          // Botón Atrás
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final nav = Navigator.of(context);
              final shouldPop = await _handleBack();
              if (shouldPop && mounted) {
                nav.pop();
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF242424),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Badge icónico P
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFE60023),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.push_pin_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Título Pinterest
          Text(
            'PINTEREST',
            style: GoogleFonts.bangers(
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),

          const Spacer(),

          // Botón Auto-Login con la cuenta F.U.R.I
          if (_isMobile && _controller != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _injectAutoLogin();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Iniciando sesión automática en Pinterest...'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF242424),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFFE60023),
                  size: 18,
                ),
              ),
            ),
          const SizedBox(width: 8),

          // Botón de Inicio / Recargar Pinterest
          if (_isMobile && _controller != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _controller!.loadRequest(Uri.parse('https://www.pinterest.com'));
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF242424),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 8),

          // Botón Cerrar directo y volver a Galería
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2020),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE60023),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.push_pin_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pinterest',
              style: GoogleFonts.bangers(
                fontSize: 28,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'En el celular se abre directamente en pantalla completa sin salir de la app.\nEn Windows puedes abrirlo con un toque aquí abajo:',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Cuenta: $_autoEmail',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: _autoEmail));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email copiado al portapapeles')),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, color: Color(0xFFE60023), size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _openExternal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60023),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_browser_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Abrir Pinterest',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
