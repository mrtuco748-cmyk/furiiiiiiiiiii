import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app_state.dart';
import '../../../services/local_cache.dart';
import '../../../supabase_config.dart';

class LettersService {
  static RealtimeChannel subscribeToChanges(VoidCallback onReload) {
    return SupabaseConfig.client
        .channel('cartas_loca_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'letters',
          callback: (_) => onReload(),
        )
        .subscribe();
  }

  static Future<List<Map<String, dynamic>>> loadInbox() async {
    final data = await SupabaseConfig.client
        .from('letters')
        .select('*')
        .eq('to_user', AppState.myId ?? '')
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> loadSent() async {
    final data = await SupabaseConfig.client
        .from('letters')
        .select('*')
        .eq('from_user', AppState.myId ?? '')
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> sendLetter({
    required String title,
    required String body,
    DateTime? scheduledOpen,
  }) async {
    await SupabaseConfig.client.from('letters').insert({
      'from_user': AppState.myId,
      'to_user': AppState.partnerId,
      'title': title,
      'content': body,
      if (scheduledOpen != null)
        'scheduled_open': scheduledOpen.toUtc().toIso8601String(),
    });
  }

  static Future<void> updateLetter({
    required int id,
    required String title,
    required String content,
  }) async {
    await SupabaseConfig.client.from('letters').update({
      'title': title,
      'content': content,
      'is_edited': true,
    }).eq('id', id);
  }

  static Future<List<Map<String, dynamic>>> getCachedInbox() async {
    try {
      return await LocalCache.getList('cache_letters_inbox');
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCachedSent() async {
    try {
      return await LocalCache.getList('cache_letters_sent');
    } catch (_) {
      return [];
    }
  }

  static Future<void> cacheLetters({
    required List<Map<String, dynamic>> inbox,
    required List<Map<String, dynamic>> sent,
  }) async {
    await LocalCache.setList('cache_letters_inbox', inbox);
    await LocalCache.setList('cache_letters_sent', sent);
  }
}
