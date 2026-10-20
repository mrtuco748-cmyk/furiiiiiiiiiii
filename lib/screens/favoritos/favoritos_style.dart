import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Constantes visuales y paleta para la pantalla y widgets de Favoritos.
class FavoritosStyle {
  static const vc = Color(0xFF9D00FF);
  static const bg = Color(0xFF0A0A0A);
  static const panel = Color(0xFF1A0830);
  static const light = Color(0xFFD4A8FF);
  static const fav = Color(0xFFFFD700);
  static const fg = Color(0xFFFFFFFF);
  static const red = Color(0xFFFF0044);
  static const facuT = Color(0xFFFF6B00);
  static const rocioT = Color(0xFFFF1493);

  static const theme = ThemeSet(
    a: Color(0xFF9D00FF),
    b: Color(0xFF6B0FB8),
    c: Color(0xFFFFD700),
    d: Color(0xFFB23BFF),
    e: Color(0xFF7B2D8E),
    dark: Color(0xFF0A0A0A),
    light: Color(0xFFD4A8FF),
    mid: Color(0xFF1A0830),
  );

  static const catLabels = <String, String>{
    'movie': 'Pelis',
    'series': 'Series',
    'game': 'Juegos',
    'music': 'Música',
  };

  static const catMeta = <String, Map<String, dynamic>>{
    'movie': {'icon': Icons.movie, 'color': Color(0xFF9D00FF)},
    'series': {'icon': Icons.tv, 'color': Color(0xFF6B0FB8)},
    'game': {'icon': Icons.sports_esports, 'color': Color(0xFFB23BFF)},
    'music': {'icon': Icons.music_note, 'color': Color(0xFF7B2D8E)},
  };
}
