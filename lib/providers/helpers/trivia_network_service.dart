import '../../models/trivia.dart';
import '../../supabase_config.dart';

/// Operaciones de red para preguntas y respuestas de trivia en Supabase.
class TriviaNetworkService {
  static const String qTable = 'daily_questions';
  static const String aTable = 'question_answers';

  static Future<List<TriviaQuestion>> fetchQuestions() async {
    final data = await SupabaseConfig.client
        .from(qTable)
        .select()
        .order('id', ascending: true)
        .timeout(const Duration(seconds: 12));
    return (data as List)
        .map((r) => TriviaQuestion.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<List<TriviaAnswer>> fetchAnswers() async {
    final data = await SupabaseConfig.client
        .from(aTable)
        .select()
        .order('id', ascending: true)
        .timeout(const Duration(seconds: 12));
    final rawList = (data as List)
        .map((r) => TriviaAnswer.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();

    final uniqueMap = <String, TriviaAnswer>{};
    for (final a in rawList) {
      uniqueMap['${a.userId}_${a.questionId}'] = a;
    }
    return uniqueMap.values.toList();
  }

  static Future<void> upsertAnswer(TriviaAnswer answer) async {
    await SupabaseConfig.client
        .from(aTable)
        .upsert(
          answer.toMap(),
          onConflict: 'user_id,question_id',
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<TriviaQuestion?> insertQuestion({
    required String question,
    required List<String> options,
  }) async {
    final res = await SupabaseConfig.client
        .from(qTable)
        .insert({
          'question': question.trim(),
          'options': options.map((o) => o.trim()).toList(),
        })
        .select()
        .timeout(const Duration(seconds: 10));
    if (res.isNotEmpty) {
      return TriviaQuestion.fromMap(
          Map<String, dynamic>.from(res.first as Map));
    }
    return null;
  }
}
