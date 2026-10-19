import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/trivia.dart';
import '../services/local_cache.dart';
import '../supabase_config.dart';

/// Trivia de pareja (pregunta del día): siembra el banco de preguntas, expone
/// la pregunta de hoy, guarda respuestas+predictions y calcula el marcador
/// "quién conoce más a quién". Con cache local offline-first para entrada instantánea.
class TriviaProvider extends ChangeNotifier {
  static const _qTable = 'daily_questions';
  static const _aTable = 'question_answers';

  static List<TriviaQuestion> get _bankWithIds => [
    for (int i = 0; i < TriviaQuestionBank.all.length; i++)
      TriviaQuestion(
        id: i + 1,
        question: TriviaQuestionBank.all[i].question,
        options: TriviaQuestionBank.all[i].options,
      ),
  ];

  List<TriviaQuestion> _questions = _bankWithIds;
  List<TriviaAnswer> _answers = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  TriviaProvider() {
    _initFromCache();
  }

  Future<void> _initFromCache() async {
    try {
      final cachedQ = await LocalCache.getList('cache_trivia_questions');
      if (cachedQ.isNotEmpty) {
        _questions = cachedQ
            .map((m) => TriviaQuestion.fromMap(m))
            .toList();
      }
      final cachedA = await LocalCache.getList('cache_trivia_answers');
      if (cachedA.isNotEmpty) {
        final rawCached = cachedA
            .map((m) => TriviaAnswer.fromMap(m))
            .toList();
        final uniqueMap = <String, TriviaAnswer>{};
        for (final a in rawCached) {
          uniqueMap['${a.userId}_${a.questionId}'] = a;
        }
        _answers = uniqueMap.values.toList();
      }
      notifyListeners();
    } catch (_) {}
  }

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

  /// Mi respuesta para una pregunta específica, o null si aún no respondí.
  TriviaAnswer? getMyAnswerForQuestion(int questionId) {
    for (final a in _answers) {
      if (a.userId == myId && a.questionId == questionId) return a;
    }
    return null;
  }

  /// Respuesta de mi pareja para una pregunta específica.
  TriviaAnswer? getPartnerAnswerForQuestion(int questionId) {
    for (final a in _answers) {
      if (a.userId == partnerId && a.questionId == questionId) return a;
    }
    return null;
  }

  /// Mi respuesta de hoy para la pregunta del día, o null si aún no respondí.
  TriviaAnswer? get myAnswerToday {
    final q = todayQuestion;
    if (q?.id == null) return null;
    return getMyAnswerForQuestion(q!.id!);
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

  Future<void> load({bool force = false}) async {
    // Si ya tenemos preguntas disponibles en memoria/cache, no bloqueamos la UI con _loading = true.
    // Solo se activa _loading si la lista está completamente vacía.
    if (_questions.isEmpty) {
      _loading = true;
      notifyListeners();
    }
    _error = null;
    try {
      await Future.wait([_loadQuestions(), _loadAnswers()]);
      if (_questions.isEmpty) {
        await _seedIfEmpty();
        await _loadQuestions();
      }
      _loading = false;
      notifyListeners();
      _subscribeRealtime();
    } catch (e) {
      _loading = false;
      if (_questions.isEmpty) {
        _error = 'No se pudo cargar la trivia';
      }
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
    try {
      final data = await SupabaseConfig.client
          .from(_qTable)
          .select()
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 12));
      final list = (data as List)
          .map((r) => TriviaQuestion.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
      if (list.isNotEmpty) {
        _questions = list;
        await LocalCache.setList('cache_trivia_questions', _questions.map((q) => q.toMap()).toList());
      }
    } catch (e) {
      developer.log('TriviaProvider._loadQuestions error: $e');
      if (_questions.isEmpty) {
        final cached = await LocalCache.getList('cache_trivia_questions');
        if (cached.isNotEmpty) {
          _questions = cached.map((m) => TriviaQuestion.fromMap(m)).toList();
        }
      }
    }
  }

  Future<void> _loadAnswers() async {
    try {
      final data = await SupabaseConfig.client
          .from(_aTable)
          .select()
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 12));
      final rawList = (data as List)
          .map((r) => TriviaAnswer.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();

      // Deduplicar en memoria dejando la respuesta más reciente por (userId, questionId)
      final uniqueMap = <String, TriviaAnswer>{};
      for (final a in rawList) {
        uniqueMap['${a.userId}_${a.questionId}'] = a;
      }
      _answers = uniqueMap.values.toList();
      await LocalCache.setList('cache_trivia_answers', _answers.map((a) => a.toMap()).toList());
    } catch (e) {
      developer.log('TriviaProvider._loadAnswers error: $e');
      if (_answers.isEmpty) {
        final cached = await LocalCache.getList('cache_trivia_answers');
        if (cached.isNotEmpty) {
          final uniqueMap = <String, TriviaAnswer>{};
          for (final m in cached) {
            final a = TriviaAnswer.fromMap(m);
            uniqueMap['${a.userId}_${a.questionId}'] = a;
          }
          _answers = uniqueMap.values.toList();
        }
      }
    }
  }

  // ─── ENVÍO ────────────────────────────────────────────────────

  /// Guarda (o reemplaza) mi respuesta y predicción para una pregunta específica.
  /// Mantiene todas las respuestas guardadas en el historial y evita que vuelvan a aparecer.
  Future<bool> submit({required int questionId, required String answer, required String guess}) async {
    _error = null;
    final optimisticAnswer = TriviaAnswer(
      questionId: questionId,
      userId: myId,
      answer: answer,
      guess: guess,
      date: _today(),
    );
    // Optimistic update: reemplaza solo la respuesta para esta pregunta específica
    _answers.removeWhere((a) => a.userId == myId && a.questionId == questionId);
    _answers.add(optimisticAnswer);
    notifyListeners();
    await LocalCache.setList('cache_trivia_answers', _answers.map((a) => a.toMap()).toList());

    try {
      // Upsert atómico sobre (user_id, question_id): persistente, cada pregunta queda guardada
      // en el historial y no vuelve a aparecer en el mazo de pendientes.
      await SupabaseConfig.client
          .from(_aTable)
          .upsert(
            optimisticAnswer.toMap(),
            onConflict: 'user_id,question_id',
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
    try {
      await _loadQuestions();
      notifyListeners();
    } catch (e) {
      developer.log('TriviaProvider._reloadQuestions error: $e');
    }
  }

  Future<void> _reloadAnswers() async {
    try {
      await _loadAnswers();
      notifyListeners();
    } catch (e) {
      developer.log('TriviaProvider._reloadAnswers error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}