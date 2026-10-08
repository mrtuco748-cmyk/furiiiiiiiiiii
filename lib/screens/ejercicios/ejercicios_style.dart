import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EjerciciosStyle {
  static const bg = Color(0xFF0A0A0A);
  static const cyan = Color(0xFF00D4FF);
  static const panel = Color(0xFF004466);
  static const panelLight = Color(0xFF006688);
  static const darkText = Color(0xFF002233);
  static const white = Color(0xFFFFFFFF);
  static const red = Color(0xFFFF4444);
  static const facuColor = Color(0xFF00E5FF);
  static const rocioColor = Color(0xFFFF66C4);

  static const dayNames = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  static const defaultReactions = ['🔥', '💪', '🏆', '👏', '😤', '🥳'];

  static BoxDecoration panelDeco({Color? color, Color? borderColor}) =>
      BoxDecoration(
        color: color ?? panel,
        border: Border.all(color: borderColor ?? color ?? panel, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0),
        ],
      );

  static InputDecoration inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.bangers(color: white.withValues(alpha: 0.4), fontSize: 13),
      filled: true,
      fillColor: panelLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: panelLight, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: panelLight, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: cyan, width: 3),
      ),
    );
  }
}
