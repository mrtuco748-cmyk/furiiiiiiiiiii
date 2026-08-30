import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/trivia.dart';
import '../supabase_config.dart';

/// Trivia de pareja (pregunta del día): siembra el banco de preguntas, expone
/// la pregunta de hoy, guarda respuestas+predictions y calcula el marcador
/// "quién conoce más a quién". Sin cache local (como finanzas/workouts).
class TriviaProvider extends ChangeNotifier {
  static const _qTable = 'daily_questions';
  static const _aTable = 'question_answers';

  List<TriviaQuestion> _questions = [];
  List<TriviaAnswer> _answers = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<TriviaAnswer> get answers => List.unmodifiable(_answers);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  String get myId => AppState.myId ?? '';
  String get partnerId => AppState.partnerId ?? '';

  /// La pregunta de hoy (por índice según el día del año).
  TriviaQuestion? get todayQuestion =>
      TriviaStats.questionForDay(_questions, DateTime.now());

  /// Respuestas de hoy.
  List<TriviaAnswer> get todayAnswers {
    final today = _today();
    return _answers.where((a) => a.date == today).toList();
  }

  List<TriviaQuestion> get questions => List.unmodifiable(_questions);

  /// Mi respuesta de hoy, o null si aún no respondí.
  TriviaAnswer? get myAnswerToday {
    final today = _today();
    for (final a in _answers) {
      if (a.userId == myId && a.date == today) return a;
    }
    return null;
  }

  /// ¿Ambos respondieron la pregunta de hoy?
  bool get bothAnsweredToday {
    final q = todayQuestion;
    if (q?.id == null) return false;
    return TriviaStats.bothAnsweredFor(
        todayAnswers, q!.id!, {myId, partnerId});
  }

  /// Preguntas que YO aún no respondí (para el mazo).
  List<TriviaQuestion> get unansweredQuestions {
    final myAnsweredIds = _answers
        .where((a) => a.userId == myId)
        .map((a) => a.questionId)
        .toSet();
    return _questions.where((q) => q.id != null && !myAnsweredIds.contains(q.id)).toList();
  }

  /// Preguntas que YA respondí (para el historial).
  List<TriviaQuestion> get answeredQuestions {
    final myAnsweredIds = _answers
        .where((a) => a.userId == myId)
        .map((a) => a.questionId)
        .toSet();
    return _questions.where((q) => q.id != null && myAnsweredIds.contains(q.id)).toList();
  }

  int get myScore => TriviaStats.scoreFor(_answers, myId, partnerId);
  int get partnerScore => TriviaStats.scoreFor(_answers, partnerId, myId);

  /// Marcador como texto "X - Y" para el header.
  String get scoreboard => '$myScore - $partnerScore';

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _today() => DateTime.now().toIso8601String().split('T')[0];

  // ─── CARGA ────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _seedIfEmpty();
      await Future.wait([_loadQuestions(), _loadAnswers()]);
      _loading = false;
      notifyListeners();
      _subscribeRealtime();
    } catch (e) {
      _loading = false;
      _error = 'No se pudo cargar la trivia';
      developer.log('TriviaProvider.load error: $e');
      notifyListeners();
    }
  }

  Future<void> _seedIfEmpty() async {
    final res = await SupabaseConfig.client
        .from(_qTable)
        .select('id, question, options')
        .limit(1)
        .timeout(const Duration(seconds: 10));
    if (res.isEmpty) {
      // Re-check inmediato antes de insertar: si la pareja abrió la pantalla
      // al mismo tiempo con la tabla vacía, ambos verían vacío y sembrarían
      // el banco duplicado. El doble chequeo cierra casi toda la ventana.
      final again = await SupabaseConfig.client
          .from(_qTable)
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      if (again.isEmpty) {
        await SupabaseConfig.client
            .from(_qTable)
            .insert(TriviaQuestionBank.all.map((q) => q.toMap()).toList())
            .timeout(const Duration(seconds: 10));
      }
    } else {
      // Si ya hay preguntas sin opciones (schema viejo), completarlas.
      await _completeMissingOptions();
    }
    // Limpieza idempotente: si por una carrera histórica quedó el banco
    // duplicado, dejar una fila por pregunta (el id más bajo).
    await _dedupeQuestions();
  }

  /// Completa `options` de filas viejas que no lo tienen, matcheando por
  /// texto de pregunta contra el banco.
  Future<void> _completeMissingOptions() async {
    try {
      final data = await SupabaseConfig.client
          .from(_qTable)
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
            .from(_qTable)
            .update({'options': match.first.options})
            .eq('id', m['id'])
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      developer.log('TriviaProvider._completeMissingOptions error: $e');
    }
  }

  /// Borra duplicados por texto (queda el id más bajo por pregunta).
  Future<void> _dedupeQuestions() async {
    try {
      final data = await SupabaseConfig.client
          .from(_qTable)
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
              .from(_qTable)
              .delete()
              .eq('id', id)
              .timeout(const Duration(seconds: 10));
        } catch (_) {
          return;
        }
      }
    } catch (e) {
      developer.log('TriviaProvider._dedupeQuestions error: $e');
    }
  }

  Future<void> _loadQuestions() async {
    final data = await SupabaseConfig.client
        .from(_qTable)
        .select()
        .order('id', ascending: true)
        .timeout(const Duration(seconds: 10));
    _questions = (data as List)
        .map((r) => TriviaQuestion.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> _loadAnswers() async {
    final data = await SupabaseConfig.client
        .from(_aTable)
        .select()
        .order('created_at', ascending: true)
        .timeout(const Duration(seconds: 10));
    _answers = (data as List)
        .map((r) => TriviaAnswer.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  // ─── ENVÍO ────────────────────────────────────────────────────

  /// Guarda (o reemplaza) mi respuesta y predicción de hoy.
  Future<bool> submit({required int questionId, required String answer, required String guess}) async {
    _error = null;
    try {
      // Upsert atómico sobre (user_id, date): idempotente, re-responder el día
      // reemplaza la anterior en un solo paso. Evita el delete-then-insert del
      // enfoque viejo, que podía perder la respuesta si el insert fallaba tras el delete.
      await SupabaseConfig.client
          .from(_aTable)
          .upsert(
            TriviaAnswer(
              questionId: questionId,
              userId: myId,
              answer: answer,
              guess: guess,
              date: _today(),
            ).toMap(),
            onConflict: 'user_id,date',
          )
          .timeout(const Duration(seconds: 10));
      await _loadAnswers();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la respuesta';
      developer.log('TriviaProvider.submit error: $e');
      notifyListeners();
      return false;
    }
  }

  // ─── CREAR PREGUNTA ───────────────────────────────────────────

  /// Crea una pregunta nueva en el banco (la pareja la ve en tiempo real).
  Future<bool> addQuestion({
    required String question,
    required List<String> options,
  }) async {
    _error = null;
    try {
      final cleaned = options.where((o) => o.trim().isNotEmpty).toList();
      if (question.trim().isEmpty || cleaned.length < 2) return false;
      final res = await SupabaseConfig.client
          .from(_qTable)
          .insert({
            'question': question.trim(),
            'options': cleaned.map((o) => o.trim()).toList(),
          })
          .select()
          .timeout(const Duration(seconds: 10));
      if (res.isNotEmpty) {
        _questions.add(
          TriviaQuestion.fromMap(Map<String, dynamic>.from(res.first as Map)),
        );
        _questions.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      } else {
        await _loadQuestions();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se pudo crear la pregunta';
      developer.log('TriviaProvider.addQuestion error: $e');
      notifyListeners();
      return false;
    }
  }

  // ─── REALTIME ─────────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('trivia_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _aTable,
          callback: (_) => _reloadAnswers(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _qTable,
          callback: (_) => _reloadQuestions(),
        )
        .subscribe();
  }

  Future<void> _reloadQuestions() async {
    await _loadQuestions();
    notifyListeners();
  }

  Future<void> _reloadAnswers() async {
    await _loadAnswers();
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}