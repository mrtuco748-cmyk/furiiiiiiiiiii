import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Catálogo de fuentes extravagantes, creativas y variadas para el Pizarrón.
class PizarronFontCatalog {
  static const List<String> fonts = [
    'Plus Jakarta Sans',
    'Space Mono',
    'Syne',
    'Pacifico',
    'Caveat',
    'Permanent Marker',
    'Press Start 2P',
    'Cinzel',
    'Abril Fatface',
    'Righteous',
    'Orbitron',
    'Monoton',
    'Bungee',
    'Creepster',
    'Special Elite',
    'Sacramento',
    'Shadows Into Light',
    'Bebas Neue',
    'Lobster',
    'UnifrakturMaguntia',
    'VT323',
    'Comfortaa',
  ];

  /// Glifo corto representativo para mostrar como ícono visual de cada fuente
  /// sin usar etiquetas de texto largas.
  static String glyphFor(String fontName) {
    switch (fontName) {
      case 'Plus Jakarta Sans':
        return 'Aa';
      case 'Space Mono':
        return '{}';
      case 'Syne':
        return 'Sy';
      case 'Pacifico':
        return 'ℱ';
      case 'Caveat':
        return '✎';
      case 'Permanent Marker':
        return '★';
      case 'Press Start 2P':
        return '8B';
      case 'Cinzel':
        return 'IV';
      case 'Abril Fatface':
        return 'Æ';
      case 'Righteous':
        return 'Rg';
      case 'Orbitron':
        return '01';
      case 'Monoton':
        return '≡';
      case 'Bungee':
        return 'BG';
      case 'Creepster':
        return '⚡';
      case 'Special Elite':
        return 'T!';
      case 'Sacramento':
        return '𝒮';
      case 'Shadows Into Light':
        return '♪';
      case 'Bebas Neue':
        return 'BB';
      case 'Lobster':
        return 'Lb';
      case 'UnifrakturMaguntia':
        return '𝔉';
      case 'VT323':
        return '>_';
      case 'Comfortaa':
        return '◯';
      default:
        return 'Aa';
    }
  }

  static TextStyle resolveFont(
    String fontName, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.3,
  }) {
    try {
      return GoogleFonts.getFont(
        fontName,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    }
  }
}
