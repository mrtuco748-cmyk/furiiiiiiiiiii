import 'package:flutter/material.dart';

/// Paleta de colores auténtica de Milanote
class MilanotePalette {
  // Colores de notas y tarjetas
  static const Color noteYellow = Color(0xFFFFF9C4); // Clásico Milanote Post-It
  static const Color notePeach = Color(0xFFFFE0B2);  // Melocotón cálido
  static const Color notePink = Color(0xFFF8BBD0);   // Rosa suave
  static const Color notePurple = Color(0xFFE1BEE7); // Lavanda
  static const Color noteBlue = Color(0xFFBBDEFB);   // Celeste cielo
  static const Color noteMint = Color(0xFFC8E6C9);   // Menta fresca
  static const Color noteWhite = Color(0xFFFFFFFF);  // Blanco limpio
  static const Color noteCharcoal = Color(0xFF263238); // Carbón oscuro

  // Colores para elementos de acento
  static const List<Color> swatchColors = [
    noteWhite,
    noteYellow,
    notePeach,
    notePink,
    notePurple,
    noteBlue,
    noteMint,
    noteCharcoal,
    Color(0xFFFF5252), // Rojo coral
    Color(0xFFFF9800), // Naranja vibrante
    Color(0xFF39FF14), // Neón FURI
    Color(0xFF00E5FF), // Cian eléctrico
    Color(0xFF7B2D8E), // Púrpura FURI
  ];

  // Fondos y bordes de la interfaz
  static const Color canvasDark = Color(0xFF141416);
  static const Color canvasGridDark = Color(0xFF25272C);
  static const Color canvasLight = Color(0xFFF4F5F7);
  static const Color canvasGridLight = Color(0xFFDFE2E8);

  static const Color dockBackground = Color(0xFF1E2024);
  static const Color dockBorder = Color(0xFF2D3036);

  static Color parseHex(String? hex, {Color defaultColor = noteYellow}) {
    if (hex == null || hex.isEmpty) return defaultColor;
    try {
      var clean = hex.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
