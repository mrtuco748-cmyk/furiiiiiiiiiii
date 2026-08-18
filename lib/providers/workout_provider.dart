import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/workout_challenge.dart';
import '../models/workout_completion.dart';
import '../models/workout_log.dart';
import '../models/workout_routine.dart';
import '../models/workout_social.dart';
import '../models/workout_stats.dart';
import '../supabase_config.dart';

/// Estado de la sección Ejercicios: logs (ejercicios), rutinas con plan
/// semanal, completados por persona y retos con aprobación conjunta.
/// Todo vive en Supabase con realtime; sin cache local (como finanzas).
class WorkoutProvider extends ChangeNotifier {
  static const _logsTable = 'workout_logs';
  static const _routinesTable = 'workout_routines';
  static const _completionsTable = 'workout_completions';
  static const _challengesTable = 'workout_challenges';

  List<WorkoutLog> _logs = [];
  List<WorkoutRoutine> _routines = [];
  List<WorkoutCompletion> _completions = [];
  List<WorkoutChallenge> _challenges = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  bool _realtimeUp = false;

  List<WorkoutLog> get logs => _logs;
  List<WorkoutRoutine> get routines => _routines;
  List<WorkoutCompletion> get completions => _completions;
  List<WorkoutChallenge> get challenges => _challenges;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String get myId => AppState.myId ?? '';
  String get partnerId => AppState.partnerId ?? '';

  // ─── CARGA ────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.wait([
      _loadLogs(),
      _loadRoutines(),
      _loadCompletions(),
      _loadChallenges(),
    ]);
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  Future<void> _loadLogs() async {
    try {
      final data = await SupabaseConfig.client
          .from(_logsTable)
          .select()
          .order('logged_on', ascending: false)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      _logs = (data as List)
          .map((r) => WorkoutLog.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      _error = 'No se pudieron cargar los ejercicios';
      developer.log('WorkoutProvider._loadLogs error: $e');
    }
  }

  Future<void> _loadRoutines() async {
    try {
      final data = await SupabaseConfig.client
          .from(_routinesTable)
          .select()
          .order('day_of_week', ascending: true)
          .timeout(const Duration(seconds: 10));
      _routines = (data as List)
          .map((r) =>
              WorkoutRoutine.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      _error = 'No se pudieron cargar las rutinas';
      developer.log('WorkoutProvider._loadRoutines error: $e');
    }
  }

  Future<void> _loadCompletions() async {
    try {
      final data = await SupabaseConfig.client
          .from(_completionsTable)
          .select()
          .order('completed_on', ascending: false)
          .timeout(const Duration(seconds: 10));
      _completions = (data as List)
          .map((r) =>
              WorkoutCompletion.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      _error = 'No se pudieron cargar los entrenamientos';
      developer.log('WorkoutProvider._loadCompletions error: $e');
    }
  }

  Future<void> _loadChallenges() async {
    try {
      final data = await SupabaseConfig.client
          .from(_challengesTable)
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      _challenges = (data as List)
          .map((r) => WorkoutChallenge.fromMap(
              Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      _error = 'No se pudieron cargar los retos';
      developer.log('WorkoutProvider._loadChallenges error: $e');
    }
  }

  // ─── REALTIME ─────────────────────────────────────────────────

  void _subscribeRealtime() {
    if (_realtimeUp) return;
    _realtimeUp = true;
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('workouts_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _logsTable,
          callback: _onLogEvent,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _routinesTable,
          callback: _onRoutineEvent,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _completionsTable,
          callback: _onCompletionEvent,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _challengesTable,
          callback: _onChallengeEvent,
        )
        .subscribe();
  }

  void _onLogEvent(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = _parseId(payload.oldRecord['id']);
        _logs.removeWhere((l) => l.id == id);
      } else {
        final cloud = WorkoutLog.fromMap(payload.newRecord);
        final idx = _logs.indexWhere((l) => l.id == cloud.id);
        if (idx == -1) {
          _logs.insert(0, cloud);
        } else {
          _logs[idx] = _mergeLog(_logs[idx], cloud);
        }
      }
      notifyListeners();
    } catch (e) {
      developer.log('WorkoutProvider realtime logs: $e');
    }
  }

  void _onRoutineEvent(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = _parseId(payload.oldRecord['id']);
        _routines.removeWhere((r) => r.id == id);
      } else {
        final cloud = WorkoutRoutine.fromMap(payload.newRecord);
        final idx = _routines.indexWhere((r) => r.id == cloud.id);
        if (idx == -1) {
          _routines.add(cloud);
        } else {
          _routines[idx] = _mergeRoutine(_routines[idx], cloud);
        }
      }
      notifyListeners();
    } catch (e) {
      developer.log('WorkoutProvider realtime routines: $e');
    }
  }

  void _onCompletionEvent(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = _parseId(payload.oldRecord['id']);
        _completions.removeWhere((c) => c.id == id);
      } else {
        final cloud = WorkoutCompletion.fromMap(payload.newRecord);
        final idx = _completions.indexWhere((c) => c.id == cloud.id);
        if (idx == -1) {
          _completions.add(cloud);
        } else {
          _completions[idx] = cloud;
        }
      }
      notifyListeners();
    } catch (e) {
      developer.log('WorkoutProvider realtime completions: $e');
    }
  }

  void _onChallengeEvent(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = _parseId(payload.oldRecord['id']);
        _challenges.removeWhere((c) => c.id == id);
      } else {
        final cloud = WorkoutChallenge.fromMap(payload.newRecord);
        final idx = _challenges.indexWhere((c) => c.id == cloud.id);
        if (idx == -1) {
          _challenges.insert(0, cloud);
        } else {
          _challenges[idx] = _mergeChallenge(_challenges[idx], cloud);
        }
      }
      notifyListeners();
    } catch (e) {
      developer.log('WorkoutProvider realtime challenges: $e');
    }
  }

  /// Mergea reacciones/comentarios por unión (el campo social se envía entero
  /// en cada update; sin merge, dos updates concurrentes se pisan).
  WorkoutLog _mergeLog(WorkoutLog local, WorkoutLog cloud) => cloud.copyWith(
        social: WorkoutSocial(
          reactions: WorkoutSocial.mergeReactions(
              local.social.reactions, cloud.social.reactions),
          comments: WorkoutSocial.mergeComments(
              local.social.comments, cloud.social.comments),
        ),
      );

  WorkoutRoutine _mergeRoutine(WorkoutRoutine local, WorkoutRoutine cloud) =>
      cloud.copyWith(
        social: WorkoutSocial(
          reactions: WorkoutSocial.mergeReactions(
              local.social.reactions, cloud.social.reactions),
          comments: WorkoutSocial.mergeComments(
              local.social.comments, cloud.social.comments),
        ),
      );

  WorkoutChallenge _mergeChallenge(
    WorkoutChallenge local,
    WorkoutChallenge cloud,
  ) =>
      cloud.copyWith(
        social: WorkoutSocial(
          reactions: WorkoutSocial.mergeReactions(
              local.social.reactions, cloud.social.reactions),
          comments: WorkoutSocial.mergeComments(
              local.social.comments, cloud.social.comments),
        ),
      );

  // ─── LOGS (ejercicios) ────────────────────────────────────────

  Future<void> addLog(WorkoutLog log) async {
    final l = log.copyWith(userId: myId);
    _error = null;
    try {
      await SupabaseConfig.client
          .from(_logsTable)
          .insert(l.toMap())
          .timeout(const Duration(seconds: 10));
      await _loadLogs();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo registrar el ejercicio';
      developer.log('WorkoutProvider.addLog error: $e');
      notifyListeners();
    }
  }

  Future<void> updateLog(WorkoutLog log) async {
    if (log.id == null) return;
    _error = null;
    try {
      await SupabaseConfig.client
          .from(_logsTable)
          .update(log.toMap())
          .eq('id', log.id!)
          .timeout(const Duration(seconds: 10));
      await _loadLogs();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo actualizar el ejercicio';
      developer.log('WorkoutProvider.updateLog error: $e');
      notifyListeners();
    }
  }

  Future<void> deleteLog(int id) async {
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_logsTable)
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar el ejercicio';
      developer.log('WorkoutProvider.deleteLog error: $e');
      await _loadLogs();
      notifyListeners();
    }
  }

  Future<bool> toggleLogReaction(int id, String key) async {
    final idx = _logs.indexWhere((l) => l.id == id);
    if (idx == -1) return false;
    final next = _logs[idx].toggleReaction(userId: myId, key: key);
    if (identical(next, _logs[idx])) return false;
    return _saveLog(next, idx);
  }

  Future<bool> _saveLog(WorkoutLog next, int idx) async {
    final prev = _logs[idx];
    _logs[idx] = next;
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_logsTable)
          .update(next.toMap())
          .eq('id', next.id!)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      _logs[idx] = prev;
      _error = 'No se pudo guardar la reacción';
      developer.log('WorkoutProvider._saveLog error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> addLogComment(int id, String text, {String? replyToId}) async {
    final idx = _logs.indexWhere((l) => l.id == id);
    if (idx == -1 || text.trim().isEmpty) return;
    final next = _logs[idx].addComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: myId,
      text: text.trim(),
      replyToId: replyToId,
    );
    await _saveLog(next, idx);
  }

  Future<void> deleteLogComment(int id, String commentId) async {
    final idx = _logs.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    final next = _logs[idx].deleteComment(commentId);
    await _saveLog(next, idx);
  }

  // ─── RUTINAS ──────────────────────────────────────────────────

  Future<void> addRoutine(WorkoutRoutine routine) async {
    final r = routine.copyWith(userId: myId);
    _error = null;
    try {
      await SupabaseConfig.client
          .from(_routinesTable)
          .insert(r.toMap())
          .timeout(const Duration(seconds: 10));
      await _loadRoutines();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo crear la rutina';
      developer.log('WorkoutProvider.addRoutine error: $e');
      notifyListeners();
    }
  }

  Future<void> updateRoutine(WorkoutRoutine routine) async {
    if (routine.id == null) return;
    _error = null;
    try {
      await SupabaseConfig.client
          .from(_routinesTable)
          .update(routine.toMap())
          .eq('id', routine.id!)
          .timeout(const Duration(seconds: 10));
      await _loadRoutines();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo actualizar la rutina';
      developer.log('WorkoutProvider.updateRoutine error: $e');
      notifyListeners();
    }
  }

  Future<void> deleteRoutine(int id) async {
    _routines.removeWhere((r) => r.id == id);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_routinesTable)
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar la rutina';
      developer.log('WorkoutProvider.deleteRoutine error: $e');
      await _loadRoutines();
      notifyListeners();
    }
  }

  Future<bool> toggleRoutineReaction(int id, String key) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx == -1) return false;
    final next = _routines[idx].toggleReaction(userId: myId, key: key);
    if (identical(next, _routines[idx])) return false;
    final prev = _routines[idx];
    _routines[idx] = next;
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_routinesTable)
          .update(next.toMap())
          .eq('id', next.id!)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      _routines[idx] = prev;
      _error = 'No se pudo guardar la reacción';
      developer.log('WorkoutProvider.toggleRoutineReaction error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> addRoutineComment(int id, String text) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx == -1 || text.trim().isEmpty) return;
    final next = _routines[idx].addComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: myId,
      text: text.trim(),
    );
    await _saveRoutineSocial(next, idx);
  }

  Future<void> deleteRoutineComment(int id, String commentId) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final next = _routines[idx].deleteComment(commentId);
    await _saveRoutineSocial(next, idx);
  }

  Future<void> _saveRoutineSocial(WorkoutRoutine next, int idx) async {
    final prev = _routines[idx];
    _routines[idx] = next;
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_routinesTable)
          .update(next.toMap())
          .eq('id', next.id!)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _routines[idx] = prev;
      _error = 'No se pudo guardar el comentario';
      developer.log('WorkoutProvider._saveRoutineSocial error: $e');
      notifyListeners();
    }
  }

  // ─── COMPLETIONS (marcar el día) ──────────────────────────────

  Future<void> toggleCompletion({
    required String userId,
    DateTime? date,
    int? routineId,
  }) async {
    final day = DateTime(
      (date ?? DateTime.now()).year,
      (date ?? DateTime.now()).month,
      (date ?? DateTime.now()).day,
    );
    final existing = _completions
        .where((c) =>
            c.userId == userId && c.day == day && c.routineId == routineId)
        .toList();
    if (existing.isNotEmpty) {
      _completions.removeWhere((c) => existing.contains(c));
      notifyListeners();
      try {
        for (final c in existing) {
          await SupabaseConfig.client
              .from(_completionsTable)
              .delete()
              .eq('id', c.id!)
              .timeout(const Duration(seconds: 10));
        }
      } catch (e) {
        _error = 'No se pudo desmarcar el día';
        developer.log('WorkoutProvider.toggleCompletion delete error: $e');
        await _loadCompletions();
        notifyListeners();
      }
    } else {
      final c = WorkoutCompletion(
        userId: userId,
        completedOn: day,
        routineId: routineId,
      );
      try {
        await SupabaseConfig.client
            .from(_completionsTable)
            .insert(c.toMap())
            .timeout(const Duration(seconds: 10));
        await _loadCompletions();
        notifyListeners();
      } catch (e) {
        _error = 'No se pudo marcar el día';
        developer.log('WorkoutProvider.toggleCompletion insert error: $e');
        notifyListeners();
      }
    }
  }

  // ─── RETOS ────────────────────────────────────────────────────

  Future<void> addChallenge(WorkoutChallenge challenge) async {
    final c = challenge.copyWith(createdBy: myId);
    _error = null;
    try {
      await SupabaseConfig.client
          .from(_challengesTable)
          .insert(c.toMap())
          .timeout(const Duration(seconds: 10));
      await _loadChallenges();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo crear el reto';
      developer.log('WorkoutProvider.addChallenge error: $e');
      notifyListeners();
    }
  }

  Future<void> deleteChallenge(int id) async {
    _challenges.removeWhere((c) => c.id == id);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_challengesTable)
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar el reto';
      developer.log('WorkoutProvider.deleteChallenge error: $e');
      await _loadChallenges();
      notifyListeners();
    }
  }

  Future<void> toggleChallengeApproval(int id) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final next = _challenges[idx].toggleApproval(myId);
    await _saveChallenge(next, idx);
  }

  Future<void> toggleChallengeCompletion(int id) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final next = _challenges[idx].toggleCompletion(myId);
    await _saveChallenge(next, idx);
  }

  Future<bool> toggleChallengeReaction(int id, String key) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    final next = _challenges[idx].toggleReaction(userId: myId, key: key);
    if (identical(next, _challenges[idx])) return false;
    return _saveChallenge(next, idx, rollback: true);
  }

  Future<void> addChallengeComment(int id, String text) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1 || text.trim().isEmpty) return;
    final next = _challenges[idx].addComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: myId,
      text: text.trim(),
    );
    await _saveChallenge(next, idx);
  }

  Future<void> deleteChallengeComment(int id, String commentId) async {
    final idx = _challenges.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final next = _challenges[idx].deleteComment(commentId);
    await _saveChallenge(next, idx);
  }

  Future<bool> _saveChallenge(
    WorkoutChallenge next,
    int idx, {
    bool rollback = false,
  }) async {
    final prev = _challenges[idx];
    _challenges[idx] = next;
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_challengesTable)
          .update(next.toMap())
          .eq('id', next.id!)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      if (rollback) _challenges[idx] = prev;
      _error = 'No se pudo guardar el reto';
      developer.log('WorkoutProvider._saveChallenge error: $e');
      notifyListeners();
      return false;
    }
  }

  // ─── GETTERS DE DOMINIO ───────────────────────────────────────

  List<WorkoutLog> logsFor(DateTime day) => _logs
      .where((l) =>
          l.loggedOn.year == day.year &&
          l.loggedOn.month == day.month &&
          l.loggedOn.day == day.day)
      .toList();

  List<WorkoutLog> logsForExercise(String name) => _logs
      .where((l) => l.exerciseName.trim().toLowerCase() == name.trim().toLowerCase())
      .toList();

  WorkoutRoutine? routineForDay(int dayOfWeek) {
    for (final r in _routines) {
      if (r.dayOfWeek == dayOfWeek) return r;
    }
    return null;
  }

  List<WorkoutCompletion> completionsFor(DateTime day) => _completions
      .where((c) => c.day == DateTime(day.year, day.month, day.day))
      .toList();

  List<WorkoutCompletion> completionsByUser(String userId) =>
      _completions.where((c) => c.userId == userId).toList();

  bool completedByUser(DateTime day, String userId) => completionsFor(day)
      .any((c) => c.userId == userId);

  int streakFor(String userId) => WorkoutStats.streakFor(
      completionsByUser(userId).map((c) => c.day));

  int get myStreak => streakFor(myId);
  int get partnerStreak => streakFor(partnerId);

  int get sessionsThisWeek => WorkoutStats.sessionsThisWeek(_logs);
  int get sessionsLastWeek => WorkoutStats.sessionsLastWeek(_logs);
  Set<String> get distinctExerciseNames =>
      WorkoutStats.distinctExerciseNames(_logs);
  Map<String, int> get muscleGroupCounts =>
      WorkoutStats.muscleGroupCounts(_logs);

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  static int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
