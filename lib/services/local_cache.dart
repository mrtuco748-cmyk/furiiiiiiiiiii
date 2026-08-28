import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local "últimos datos conocidos" por sección, persistido en
/// SharedPreferences como JSON. Pensado para el modelo offline-first: al
/// entrar, mostrás el cache al instante (sin "carga") y después sincronizás
/// con Supabase guardando solo lo nuevo/cambiado. Cada sección usa una key
/// propia (`cache_<tabla>`).
class LocalCache {
  static Future<List<Map<String, dynamic>>?> getList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> setList(
      String key, List<Map<String, dynamic>> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(list));
    } catch (_) {}
  }

  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}