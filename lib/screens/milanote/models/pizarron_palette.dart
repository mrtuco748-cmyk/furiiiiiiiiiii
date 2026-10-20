import 'package:flutter/material.dart';

/// Paleta curada de colores vibrantes y oscuros (sin negro puro #000000).
class PizarronPalette {
  static const List<String> noteColors = [
    '#1E2436', // Slate profundo
    '#2B193D', // Violeta noche
    '#132A2E', // Petróleo oscuro
    '#3B1C32', // Borgoña oscuro
    '#1F2D1E', // Bosque oscuro
    '#33261E', // Tierra oscuro
    '#FF2A85', // Rosa fucsia vibrante
    '#7B2CBF', // Púrpura eléctrico
    '#3A86FF', // Azul intenso
    '#00BBF9', // Cian vibrante
    '#00F5D4', // Turquesa menta
    '#2EE50F', // Verde lima sólido
    '#FFB703', // Ámbar intenso
    '#FB5607', // Naranja fuego
    '#E63946', // Rojo coral
    '#FFF3B0', // Crema pastel cálido
    '#FDE2E4', // Rosa empolvado
    '#E2ECE9', // Menta hielo
    '#EAE4E9', // Lavanda suave
    '#FFFFFF', // Blanco puro
  ];

  static const List<String> boardColors = [
    '#141820', // Pizarra grafito (por defecto)
    '#18241E', // Pizarrón escolar verde oscuro
    '#1A162B', // Pizarra índigo profundo
    '#241A1E', // Pizarra ciruela oscuro
    '#16222F', // Pizarra azul marino
    '#26231F', // Pizarra carbón cálido
    '#2A3240', // Pizarra acero
    '#EDE9E0', // Lienzo papel crema
    '#E2E8F0', // Lienzo gris perla
  ];

  static const List<String> chalkColors = [
    '#FFFFFF', // Tiza blanca
    '#FFF3B0', // Tiza amarilla
    '#FF8FA3', // Tiza rosa
    '#80ED99', // Tiza verde
    '#72EFDD', // Tiza celeste
    '#C77DFF', // Tiza violeta
    '#FFB703', // Tiza naranja
  ];

  static Color parseHex(String hex, {Color fallback = const Color(0xFF1E2436)}) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final val = int.tryParse('FF$cleaned', radix: 16);
      if (val != null) return Color(val);
    } else if (cleaned.length == 8) {
      final val = int.tryParse(cleaned, radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  static String toHex(Color color) {
    final r =
        (color.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g =
        (color.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b =
        (color.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  static final List<String> recentColors = [
    '#FF2A85',
    '#7B2CBF',
    '#3A86FF',
    '#2EE50F',
    '#FFB703',
    '#1E2436',
    '#FFFFFF',
  ];

  static void addRecentColor(String hex) {
    final clean = hex.trim().toUpperCase();
    if (clean.isEmpty) return;
    recentColors.remove(clean);
    recentColors.insert(0, clean);
    if (recentColors.length > 10) {
      recentColors.removeLast();
    }
  }
}
