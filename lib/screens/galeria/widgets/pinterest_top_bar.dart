import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PinterestTopBar extends StatelessWidget {
  final bool isMobile;
  final bool hasController;
  final bool showCredentialsBar;
  final VoidCallback onBack;
  final VoidCallback onToggleCredentials;
  final VoidCallback onReload;
  final VoidCallback onClose;

  const PinterestTopBar({
    super.key,
    required this.isMobile,
    required this.hasController,
    required this.showCredentialsBar,
    required this.onBack,
    required this.onToggleCredentials,
    required this.onReload,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF181818),
      child: Row(
        children: [
          // Botón Atrás
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBack();
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
              onToggleCredentials();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: showCredentialsBar
                    ? const Color(0xFFE60023)
                    : const Color(0xFF242424),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.vpn_key_rounded,
                color: showCredentialsBar ? Colors.white : const Color(0xFFE60023),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón de Inicio / Recargar Pinterest
          if (isMobile && hasController) ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onReload();
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
          ],

          // Botón Cerrar directo y volver a Galería
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onClose();
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
}
