import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estilo brutalista modificado para la sección Ejercicios (skill_visual .md).
/// Fondo sólido, sin negro puro (#000000), borde y fondo idénticos, esquinas redondas.
class EjerciciosStyle {
  EjerciciosStyle._();

  static const bg = Color(0xFF0D170D);
  static const panel = Color(0xFF142614);
  static const panelLight = Color(0xFF1F381F);
  static const field = Color(0xFF264526);
  static const lime = Color(0xFF39FF14);
  static const cyan = Color(0xFF00D4FF);
  static const darkText = Color(0xFF051705);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF88A888);
  static const red = Color(0xFFFF5757);
  static const yellow = Color(0xFFFFDE59);
  static const pink = Color(0xFFFF66C4);
  static const facuColor = Color(0xFF00E5FF);
  static const rocioColor = Color(0xFFFF66C4);

  static const dayNames = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  static const defaultReactions = ['🔥', '💪', '🏆', '👏', '😤', '🥳'];

  static BoxDecoration panelDeco({Color? color, Color? borderColor, double radius = 16, double bw = 0}) {
    final c = color ?? panel;
    return BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static InputDecoration inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.bangers(color: muted, fontSize: 16),
      filled: true,
      fillColor: field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
