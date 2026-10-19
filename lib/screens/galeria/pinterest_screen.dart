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
  bool _showCredentialsBar = true;

  static const String _accountEmail = 'derrame_company@yahoo.com';
  static const String _accountPass = 'Zapallo1234*';

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
            // Ocultar banners molestos de la web de Pinterest
            _injectCleanerCss();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Pinterest WebView Error: ${error.description}');
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
      )
      ..loadRequest(Uri.parse('https://www.pinterest.com/'));

    _controller = controller;
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

              // Barra rápida de credenciales (1-tap para copiar y pegar sin ser detectado como bot)
              if (_showCredentialsBar) _buildCredentialsBanner(),

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

          // Botón para mostrar / ocultar credenciales
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showCredentialsBar = !_showCredentialsBar;
              });
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _showCredentialsBar
                    ? const Color(0xFFE60023)
                    : const Color(0xFF242424),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.vpn_key_rounded,
                color: _showCredentialsBar ? Colors.white : const Color(0xFFE60023),
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
                _controller!.loadRequest(Uri.parse('https://www.pinterest.com/'));
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

  Widget _buildCredentialsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildCopyChip(
                    label: 'Copiar Correo',
                    icon: Icons.mail_outline_rounded,
                    value: _accountEmail,
                    snackMsg: 'Correo copiado: $_accountEmail',
                  ),
                  const SizedBox(width: 8),
                  _buildCopyChip(
                    label: 'Copiar Clave',
                    icon: Icons.lock_outline_rounded,
                    value: _accountPass,
                    snackMsg: 'Contraseña copiada al portapapeles',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showCredentialsBar = false);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF282828),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyChip({
    required String label,
    required IconData icon,
    required String value,
    required String snackMsg,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              snackMsg,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            backgroundColor: const Color(0xFF242424),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFE60023)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.copy_rounded, size: 12, color: Colors.white38),
          ],
        ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildCopyChip(
                  label: 'Copiar Correo',
                  icon: Icons.mail_outline_rounded,
                  value: _accountEmail,
                  snackMsg: 'Correo copiado: $_accountEmail',
                ),
                _buildCopyChip(
                  label: 'Copiar Clave',
                  icon: Icons.lock_outline_rounded,
                  value: _accountPass,
                  snackMsg: 'Contraseña copiada al portapapeles',
                ),
              ],
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
