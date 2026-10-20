import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/trivia.dart';
import '../services/local_cache.dart';
import '../supabase_config.dart';
import 'helpers/trivia_network_service.dart';
import 'helpers/trivia_seed_helper.dart';

/// Trivia de pareja (pregunta del día): siembra el banco de preguntas, expone
/// la pregunta de hoy, guarda respuestas+predictions y calcula el marcador
/// "quién conoce más a quién". Con cache local offline-first para entrada instantánea.
class TriviaProvider extends ChangeNotifier {
  List<TriviaQuestion> _questions = TriviaSeedHelper.bankWithIds;
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

  TriviaQuestion? get todayQuestion =>
      TriviaStats.questionForDay(_questions, DateTime.now());

  List<TriviaAnswer> get todayAnswers {
    final today = _today();
    return _answers.where((a) => a.date == today).toList();
  }

  List<TriviaQuestion> get questions => List.unmodifiable(_questions);

  TriviaAnswer? getMyAnswerForQuestion(int questionId) {
    for (final a in _answers) {
      if (a.userId == myId && a.questionId == questionId) return a;
    }
    return null;
  }

  TriviaAnswer? getPartnerAnswerForQuestion(int questionId) {
    for (final a in _answers) {
      if (a.userId == partnerId && a.questionId == questionId) return a;
    }
    return null;
  }

  TriviaAnswer? get myAnswerToday {
    final q = todayQuestion;
    if (q?.id == null) return null;
    return getMyAnswerForQuestion(q!.id!);
  }

  bool get bothAnsweredToday {
    final q = todayQuestion;
    if (q?.id == null) return false;
    return TriviaStats.bothAnsweredFor(
        todayAnswers, q!.id!, {myId, partnerId});
  }

  List<TriviaQuestion> get unansweredQuestions {
    final myAnsweredIds = _answers
        .where((a) => a.userId == myId)
        .map((a) => a.questionId)
        .toSet();
    return _questions
        .where((q) => q.id != null && !myAnsweredIds.contains(q.id))
        .toList();
  }

  List<TriviaQuestion> get answeredQuestions {
    final myAnsweredIds = _answers
        .where((a) => a.userId == myId)
        .map((a) => a.questionId)
        .toSet();
    return _questions
        .where((q) => q.id != null && myAnsweredIds.contains(q.id))
        .toList();
  }

  int get myScore => TriviaStats.scoreFor(_answers, myId, partnerId);
  int get partnerScore => TriviaStats.scoreFor(_answers, partnerId, myId);

  String get scoreboard => '$myScore - $partnerScore';

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _today() => DateTime.now().toIso8601String().split('T')[0];

  Future<void> load({bool force = false}) async {
    if (_questions.isEmpty) {
      _loading = true;
      notifyListeners();
    }
    _error = null;
    try {
      await Future.wait([_loadQuestions(), _loadAnswers()]);
      if (_questions.isEmpty) {
        await TriviaSeedHelper.seedIfEmpty();
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

  Future<void> _loadQuestions() async {
    try {
      final list = await TriviaNetworkService.fetchQuestions();
      if (list.isNotEmpty) {
        _questions = list;
        await LocalCache.setList('cache_trivia_questions',
            _questions.map((q) => q.toMap()).toList());
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
      final list = await TriviaNetworkService.fetchAnswers();
      _answers = list;
      await LocalCache.setList(
          'cache_trivia_answers', _answers.map((a) => a.toMap()).toList());
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

  Future<bool> submit({
    required int questionId,
    required String answer,
    required String guess,
  }) async {
    _error = null;
    final optimisticAnswer = TriviaAnswer(
      questionId: questionId,
      userId: myId,
      answer: answer,
      guess: guess,
      date: _today(),
    );
    _answers
        .removeWhere((a) => a.userId == myId && a.questionId == questionId);
    _answers.add(optimisticAnswer);
    notifyListeners();
    await LocalCache.setList(
        'cache_trivia_answers', _answers.map((a) => a.toMap()).toList());

    try {
      await TriviaNetworkService.upsertAnswer(optimisticAnswer);
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

  Future<bool> addQuestion({
    required String question,
    required List<String> options,
  }) async {
    _error = null;
    try {
      final cleaned = options.where((o) => o.trim().isNotEmpty).toList();
      if (question.trim().isEmpty || cleaned.length < 2) return false;
      final newQ = await TriviaNetworkService.insertQuestion(
        question: question,
        options: cleaned,
      );
      if (newQ != null) {
        _questions.add(newQ);
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

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('trivia_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: TriviaNetworkService.aTable,
          callback: (_) => _reloadAnswers(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: TriviaNetworkService.qTable,
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
