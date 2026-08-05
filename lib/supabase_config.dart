import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://nruyjpvoplkilcxqnees.supabase.co';
  static const String anonKey =
      'sb_publishable_JP4QgTreyVi-Mm3EYyiQtQ_YuvAxguu';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      _initialized = true;
    } catch (e) {
      debugPrint('Supabase init error: $e');
    }
  }

  /// May throw if Supabase is unreachable – callers must catch.
  static SupabaseClient get client => Supabase.instance.client;
}
