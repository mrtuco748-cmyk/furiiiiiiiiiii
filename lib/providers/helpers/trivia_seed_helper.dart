import 'dart:developer' as developer;
import '../../models/trivia.dart';
import '../../supabase_config.dart';

/// Funciones auxiliares para sembrar y deduplicar el banco de preguntas en Supabase.
class TriviaSeedHelper {
  static const String qTable = 'daily_questions';

  static List<TriviaQuestion> get bankWithIds => [
        for (int i = 0; i < TriviaQuestionBank.all.length; i++)
          TriviaQuestion(
            id: i + 1,
            question: TriviaQuestionBank.all[i].question,
            options: TriviaQuestionBank.all[i].options,
          ),
      ];

  static Future<void> seedIfEmpty() async {
    final res = await SupabaseConfig.client
        .from(qTable)
        .select('id, question, options')
        .limit(1)
        .timeout(const Duration(seconds: 10));
    if (res.isEmpty) {
      final again = await SupabaseConfig.client
          .from(qTable)
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      if (again.isEmpty) {
        await SupabaseConfig.client
            .from(qTable)
            .insert(TriviaQuestionBank.all.map((q) => q.toMap()).toList())
            .timeout(const Duration(seconds: 10));
      }
    } else {
      await completeMissingOptions();
    }
    await dedupeQuestions();
  }

  static Future<void> completeMissingOptions() async {
    try {
      final data = await SupabaseConfig.client
          .from(qTable)
          .select('id, question, options')
          .timeout(const Duration(seconds: 10));
      for (final row in (data as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        if (m['options'] != null) continue;
        final match = TriviaQuestionBank.all
            .where((q) => q.question == m['question'])
            .toList();
        if (match.isEmpty) continue;
        await SupabaseConfig.client
            .from(qTable)
            .update({'options': match.first.options})
            .eq('id', m['id'])
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      developer.log('TriviaSeedHelper.completeMissingOptions error: $e');
    }
  }

  static Future<void> dedupeQuestions() async {
    try {
      final data = await SupabaseConfig.client
          .from(qTable)
          .select('id, question')
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 10));
      final seen = <String, int>{};
      final dupes = <int>[];
      for (final row in (data as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        final id = (m['id'] as num).toInt();
        final q = m['question']?.toString() ?? '';
        if (seen.containsKey(q)) {
          dupes.add(id);
        } else {
          seen[q] = id;
        }
      }
      for (final id in dupes) {
        try {
          await SupabaseConfig.client
              .from(qTable)
              .delete()
              .eq('id', id)
              .timeout(const Duration(seconds: 10));
        } catch (_) {
          return;
        }
      }
    } catch (e) {
      developer.log('TriviaSeedHelper.dedupeQuestions error: $e');
    }
  }
}
