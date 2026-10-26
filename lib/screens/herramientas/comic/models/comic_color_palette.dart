import 'package:flutter/material.dart';

/// Colección curada de paletas de color legendarias del manga y cómic mundial.
class ComicPalette {
  final String id;
  final String name;
  final String origin;
  final List<Color> colors;
  final Color accentColor;

  const ComicPalette({
    required this.id,
    required this.name,
    required this.origin,
    required this.colors,
    required this.accentColor,
  });
}

abstract final class ComicColorPalettes {
  static const List<ComicPalette> all = [
    // 1. Shonen Jump Clásico (Dragon Ball / One Piece)
    ComicPalette(
      id: 'shonen_jump',
      name: 'Shonen Jump Clásico',
      origin: 'Dragon Ball & One Piece',
      accentColor: Color(0xFFFF6B00),
      colors: [
        Color(0xFFFF6B00), // Naranja Goku
        Color(0xFF0055B8), // Azul Gi Toriyama
        Color(0xFFFFDE59), // Amarillo Super Saiyan
        Color(0xFFE60012), // Rojo Shonen Jump
        Color(0xFF10A34E), // Verde Namek
        Color(0xFFFDDCB8), // Piel Anime
        Color(0xFF111111), // Negro Tinta
        Color(0xFFFFFFFF), // Blanco Papel
      ],
    ),

    // 2. Akira & Neo-Tokyo Cyberpunk (Katsuhiro Otomo)
    ComicPalette(
      id: 'akira_cyberpunk',
      name: 'Akira Cyberpunk',
      origin: 'Neo-Tokyo 1988',
      accentColor: Color(0xFFD00000),
      colors: [
        Color(0xFFD00000), // Rojo Moto Kaneda
        Color(0xFFEEFF04), // Neón Cibernético
        Color(0xFF00E5FF), // Cian Holograma
        Color(0xFF58007C), // Púrpura Noche
        Color(0xFF7D828A), // Gris Concreto
        Color(0xFF181818), // Asfalto Oscuro
        Color(0xFFFF851B), // Fuego Explosión
        Color(0xFFFFFFFF), // Blanco Láser
      ],
    ),

    // 3. JoJo's Bizarre Adventure (Hirohiko Araki)
    ComicPalette(
      id: 'jojo_vibrant',
      name: 'JoJo Bizarre',
      origin: 'Hirohiko Araki Stand Aura',
      accentColor: Color(0xFF8A2BE2),
      colors: [
        Color(0xFF8A2BE2), // Violeta Stand
        Color(0xFFFF007F), // Fucsia Menacing (ゴゴゴ)
        Color(0xFFFFD700), // Dorado Golden Wind
        Color(0xFF00F0B5), // Turquesa Morioh
        Color(0xFF7FFF00), // Verde Ácido
        Color(0xFFD6006E), // Magenta Intenso
        Color(0xFF2E0854), // Morado Sombrío
        Color(0xFFFFFFFF), // Blanco Flash
      ],
    ),

    // 4. Marvel Vintage 4-Color CMYK (Jack Kirby / Stan Lee 60s)
    ComicPalette(
      id: 'marvel_vintage',
      name: 'Marvel Retro CMYK',
      origin: 'Jack Kirby & Stan Lee',
      accentColor: Color(0xFFDF1F2D),
      colors: [
        Color(0xFFDF1F2D), // Rojo Spidey / Cap
        Color(0xFF0072BC), // Azul Ben-Day Dots
        Color(0xFFFFD200), // Amarillo Primario Cómic
        Color(0xFF29A634), // Verde Increíble Hulk
        Color(0xFF662D91), // Púrpura Villano
        Color(0xFFE97300), // Naranja Antorcha
        Color(0xFF0A0A0A), // Negro Registro Offset
        Color(0xFFFFFDD0), // Blanco Papel Pulp
      ],
    ),

    // 5. Batman Dark Deco (Gotham Noir / Frank Miller / Bruce Timm)
    ComicPalette(
      id: 'batman_noir',
      name: 'Gotham Dark Deco',
      origin: 'Batman The Animated / Noir',
      accentColor: Color(0xFFF5B041),
      colors: [
        Color(0xFF1C2833), // Azul Noche Gotham
        Color(0xFF4A5568), // Gris Baticueva
        Color(0xFF111116), // Negro Sombra
        Color(0xFFF5B041), // Amarillo Batiseñal
        Color(0xFFC0392B), // Rojo Joker
        Color(0xFF27AE60), // Verde Enigma
        Color(0xFFE2E8F0), // Blanco Neblina
        Color(0xFF7F8C8D), // Gárgola Piedra
      ],
    ),

    // 6. Webtoon Pastel Romance & Fantasy (Solo Leveling / Lore Olympus)
    ComicPalette(
      id: 'webtoon_pastel',
      name: 'Webtoon Romance',
      origin: 'Manhwa Digital Fantasía',
      accentColor: Color(0xFFFFB7B2),
      colors: [
        Color(0xFF6C5CE7), // Neón Monarca
        Color(0xFFFFB7B2), // Rosa Flor de Cerezo
        Color(0xFFA8E6CF), // Menta Suave
        Color(0xFFFFDAC1), // Durazno Piel
        Color(0xFFFDCB6E), // Oro Corona
        Color(0xFF1E295D), // Azul Noche Manhwa
        Color(0xFFE056FD), // Magia Púrpura
        Color(0xFFFFFFFF), // Blanco Nube
      ],
    ),

    // 7. Manga Trama y Tinta G-Pen (Monocromo Profesional)
    ComicPalette(
      id: 'manga_ink',
      name: 'Manga Tinta y Tramas',
      origin: 'Monocromo Tradicional',
      accentColor: Color(0xFF4A4A4A),
      colors: [
        Color(0xFF0B0B0B), // Negro Tinta G-Pen
        Color(0xFF333333), // Trama 80%
        Color(0xFF555555), // Trama 60%
        Color(0xFF888888), // Trama 40%
        Color(0xFFB0B0B0), // Trama 25%
        Color(0xFFDCDCDC), // Trama 10%
        Color(0xFFF6F6F6), // Papel Kent Manga
        Color(0xFFFFFFFF), // Corrector Blanco
      ],
    ),
  ];
}
