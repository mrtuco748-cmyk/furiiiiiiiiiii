import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Feedback global estilo F.U.R.I para confirmar acciones (guardado, hecho,
/// deshecho). Usa el [ScaffoldMessenger] del [context] del que se llame.
class AppFeedback {
  static void _show(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String text,
    String? undoLabel,
    VoidCallback? onUndo,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color, width: 2),
        ),
        duration: onUndo != null
            ? const Duration(seconds: 4)
            : const Duration(seconds: 2),
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
          ),
          if (onUndo != null)
            GestureDetector(
              onTap: () {
                onUndo();
                messenger.hideCurrentSnackBar();
              },
              child: Text('DESHACER',
                  style: GoogleFonts.bangers(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
        ]),
      ),
    );
  }

  /// Confirmación de una acción satisfactoria (guardado / hecho). Con
  /// [celebration] pide confeti/check cuando se completa un logro.
  static void success(BuildContext context, String text, {bool celebration = false}) {
    _show(context,
        color: const Color(0xFF008844),
        icon: celebration ? Icons.celebration : Icons.check_circle,
        text: text);
  }

  /// Confirmación de un guardado sencillo.
  static void saved(BuildContext context, String text) =>
      _show(context, color: const Color(0xFF008844),
          icon: Icons.check_circle, text: text);

  /// Borrado con opción de Deshacer.
  static void deleted(BuildContext context, String text,
      {required VoidCallback onUndo}) {
    _show(context,
        color: const Color(0xFF880000),
        icon: Icons.delete_outline,
        text: text,
        undoLabel: 'DESHACER',
        onUndo: onUndo);
  }

  /// Error en una acción.
  static void error(BuildContext context, String text) =>
      _show(context, color: const Color(0xFF880000),
          icon: Icons.error_outline, text: text);
}