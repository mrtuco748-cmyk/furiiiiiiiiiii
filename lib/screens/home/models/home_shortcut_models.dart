import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ShortcutDef {
  final String label;
  final IconData icon;
  final String action;
  const ShortcutDef(this.label, this.icon, this.action);
}

const List<ShortcutDef> homeShortcuts = [
  ShortcutDef('Cartas', Icons.mail_rounded, 'open_letters'),
  ShortcutDef('Escribir Carta', Icons.edit_note_rounded, 'write_letter'),
  ShortcutDef('Agendar Escuela', Icons.school_rounded, 'schedule_school'),
  ShortcutDef('Música', Icons.headphones_rounded, 'open_music'),
  ShortcutDef('Playlists', Icons.queue_music_rounded, 'open_playlists'),
  ShortcutDef('Buscar Música', Icons.youtube_searched_for_rounded, 'search_music'),
  ShortcutDef('Actualizar GPS', Icons.my_location_rounded, 'update_gps'),
  ShortcutDef('Ver Mapa', Icons.map_rounded, 'open_map'),
  ShortcutDef('Metas', Icons.emoji_events_rounded, 'open_metas'),
  ShortcutDef('Retos', Icons.flag_rounded, 'open_retos'),
  ShortcutDef('Recompensas', Icons.card_giftcard_rounded, 'open_rewards'),
  ShortcutDef('Logros', Icons.military_tech_rounded, 'open_achievements'),
  ShortcutDef('Nuevo Ejercicio', Icons.fitness_center_rounded, 'log_workout'),
];

Color shortcutColor(ThemeSet t, int i) {
  final palette = [t.a, t.b, t.c, t.d, t.e];
  return palette[i % palette.length];
}
