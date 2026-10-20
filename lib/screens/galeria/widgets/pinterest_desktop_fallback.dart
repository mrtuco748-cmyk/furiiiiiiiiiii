import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PinterestDesktopFallback extends StatelessWidget {
  final String accountEmail;
  final String accountPass;
  final VoidCallback onOpenExternal;

  const PinterestDesktopFallback({
    super.key,
    required this.accountEmail,
    required this.accountPass,
    required this.onOpenExternal,
  });

  Widget _buildCopyChip({
    required BuildContext context,
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

  @override
  Widget build(BuildContext context) {
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
                  context: context,
                  label: 'Copiar Correo',
                  icon: Icons.mail_outline_rounded,
                  value: accountEmail,
                  snackMsg: 'Correo copiado: $accountEmail',
                ),
                _buildCopyChip(
                  context: context,
                  label: 'Copiar Clave',
                  icon: Icons.lock_outline_rounded,
                  value: accountPass,
                  snackMsg: 'Contraseña copiada al portapapeles',
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onOpenExternal,
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
