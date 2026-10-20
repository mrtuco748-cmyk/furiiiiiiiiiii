import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase_config.dart';

class NosotrosService {
  static Future<List<Map<String, dynamic>>> loadChallenges({
    required String myId,
    required String? partnerId,
  }) async {
    final filters = partnerId != null
        ? 'couple_id.eq.$myId,couple_id.eq.$partnerId'
        : 'couple_id.eq.$myId';
    final data = await SupabaseConfig.client
        .from('challenges')
        .select('*')
        .or(filters)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>?> loadPartnerLetter({
    required String myId,
    required String? partnerId,
  }) async {
    if (partnerId == null) return null;
    final data = await SupabaseConfig.client
        .from('letters')
        .select('*')
        .eq('from_user', partnerId)
        .order('created_at', ascending: false)
        .limit(1);
    if (data.isEmpty) return null;
    final letter = data[0];

    final openRaw = letter['scheduled_open'];
    final openAt = openRaw == null ? null : DateTime.tryParse(openRaw.toString());
    if (openAt != null && openAt.isAfter(DateTime.now())) return null;

    final seen = (letter['seen_by'] as List?)?.contains(myId) ?? false;
    if (seen) return null;
    await markSeen(letter, 'letters', myId);
    return letter;
  }

  static Future<void> markSeen(
    Map<String, dynamic> record,
    String table,
    String myId,
  ) async {
    final list = (record['seen_by'] as List?)?.cast<String>() ?? <String>[];
    if (list.contains(myId)) return;
    list.add(myId);
    record['seen_by'] = list;
    try {
      await SupabaseConfig.client
          .from(table)
          .update({'seen_by': list})
          .eq('id', record['id']);
    } catch (e) {
      developer.log('NosotrosService.markSeen error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadTodayMoods(String? partnerId) async {
    if (partnerId == null) return [];
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await SupabaseConfig.client
        .from('moods')
        .select('*')
        .eq('date', today)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> loadAllQuestions({
    required String myId,
    required String? partnerId,
  }) async {
    if (partnerId == null) return [];
    final data = await SupabaseConfig.client
        .from('custom_questions')
        .select('*')
        .or('from_user.eq.$myId,to_user.eq.$myId')
        .order('created_at', ascending: false)
        .limit(30);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addMood({
    required String myId,
    required String emoji,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await SupabaseConfig.client.from('moods').insert({
      'user_id': myId,
      'mood': emoji,
      'date': today,
    });
  }

  static Future<void> deleteMood(dynamic id) async {
    await SupabaseConfig.client.from('moods').delete().eq('id', id);
  }

  static Future<void> answerQuestion({
    required dynamic questionId,
    required String answer,
  }) async {
    await SupabaseConfig.client.from('custom_questions').update({
      'answer': answer,
      'answered_at': DateTime.now().toIso8601String(),
    }).eq('id', questionId);
  }

  static Future<void> sendNewQuestion({
    required String myId,
    required String partnerId,
    required String text,
  }) async {
    await SupabaseConfig.client.from('custom_questions').insert({
      'from_user': myId,
      'to_user': partnerId,
      'question': text.trim(),
    });
  }

  static Future<void> deleteQuestion(dynamic id) async {
    await SupabaseConfig.client.from('custom_questions').delete().eq('id', id);
  }

  static RealtimeChannel subscribeRealtime(VoidCallback onReload) {
    return SupabaseConfig.client
        .channel('nosotros_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'challenges',
          callback: (_) => onReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'letters',
          callback: (_) => onReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'moods',
          callback: (_) => onReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'custom_questions',
          callback: (_) => onReload(),
        )
        .subscribe();
  }
}
