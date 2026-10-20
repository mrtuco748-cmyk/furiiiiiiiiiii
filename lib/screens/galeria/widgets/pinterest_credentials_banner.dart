import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PinterestCredentialsBanner extends StatelessWidget {
  final String accountEmail;
  final String accountPass;
  final VoidCallback onClose;

  const PinterestCredentialsBanner({
    super.key,
    required this.accountEmail,
    required this.accountPass,
    required this.onClose,
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
                    context: context,
                    label: 'Copiar Correo',
                    icon: Icons.mail_outline_rounded,
                    value: accountEmail,
                    snackMsg: 'Correo copiado: $accountEmail',
                  ),
                  const SizedBox(width: 8),
                  _buildCopyChip(
                    context: context,
                    label: 'Copiar Clave',
                    icon: Icons.lock_outline_rounded,
                    value: accountPass,
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
              onClose();
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
}
