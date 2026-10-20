import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/workout_challenge.dart';
import '../models/workout_completion.dart';
import '../models/workout_log.dart';
import '../models/workout_routine.dart';
import '../models/workout_stats.dart';
import 'helpers/workout_challenges_mixin.dart';
import 'helpers/workout_database_service.dart';
import 'helpers/workout_logs_mixin.dart';
import 'helpers/workout_realtime_handler.dart';
import 'helpers/workout_routines_mixin.dart';

/// Estado de la sección Ejercicios: logs, rutinas, completados y retos.
class WorkoutProvider extends ChangeNotifier
    with WorkoutLogsMixin, WorkoutRoutinesMixin, WorkoutChallengesMixin {
  List<WorkoutCompletion> _completions = [];
  bool _loading = false;
  String? _error;
  final WorkoutRealtimeHandler _realtime = WorkoutRealtimeHandler();

  List<WorkoutCompletion> get completions => _completions;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void setWorkoutError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  @override
  String get myId => AppState.myId ?? '';
  String get partnerId => AppState.partnerId ?? '';

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        WorkoutDatabaseService.fetchLogs(),
        WorkoutDatabaseService.fetchRoutines(),
        WorkoutDatabaseService.fetchCompletions(),
        WorkoutDatabaseService.fetchChallenges(),
      ]);
      setLogs(results[0] as List<WorkoutLog>);
      setRoutines(results[1] as List<WorkoutRoutine>);
      _completions = results[2] as List<WorkoutCompletion>;
      setChallenges(results[3] as List<WorkoutChallenge>);
    } catch (e) {
      _error = 'Error al cargar datos de ejercicios';
      developer.log('WorkoutProvider.load error: $e');
    } finally {
      _loading = false;
      notifyListeners();
      _realtime.subscribe(
        getLogs: () => logs,
        getRoutines: () => routines,
        getCompletions: () => _completions,
        getChallenges: () => challenges,
        onNotify: notifyListeners,
      );
    }
  }

  // ─── COMPLETIONS ──────────────────────────────────────────────

  Future<void> toggleCompletion({required String userId, DateTime? date, int? routineId}) async {
    final day = DateTime((date ?? DateTime.now()).year, (date ?? DateTime.now()).month, (date ?? DateTime.now()).day);
    final existing = _completions.where((c) => c.userId == userId && c.day == day && (c.routineId ?? 0) == (routineId ?? 0)).toList();
    if (existing.isNotEmpty) {
      _completions.removeWhere((c) => existing.contains(c));
      notifyListeners();
      try {
        for (final c in existing) {
          await WorkoutDatabaseService.deleteCompletion(c.id!);
        }
      } catch (e) {
        _error = 'No se pudo desmarcar el día';
        developer.log('WorkoutProvider.toggleCompletion delete error: $e');
        _completions = await WorkoutDatabaseService.fetchCompletions();
        notifyListeners();
      }
    } else {
      final c = WorkoutCompletion(userId: userId, completedOn: day, routineId: routineId);
      try {
        await WorkoutDatabaseService.upsertCompletion(c);
        _completions = await WorkoutDatabaseService.fetchCompletions();
        notifyListeners();
      } catch (e) {
        _error = 'No se pudo marcar el día';
        developer.log('WorkoutProvider.toggleCompletion insert error: $e');
        notifyListeners();
      }
    }
  }

  // ─── GETTERS DE DOMINIO ───────────────────────────────────────

  List<WorkoutLog> logsFor(DateTime day) => logs
      .where((l) => l.loggedOn.year == day.year && l.loggedOn.month == day.month && l.loggedOn.day == day.day)
      .toList();

  List<WorkoutLog> logsForExercise(String name) => logs
      .where((l) => l.exerciseName.trim().toLowerCase() == name.trim().toLowerCase())
      .toList();

  WorkoutRoutine? routineForDay(int dayOfWeek) {
    for (final r in routines) {
      if (r.dayOfWeek == dayOfWeek) return r;
    }
    return null;
  }

  List<WorkoutCompletion> completionsFor(DateTime day) =>
      _completions.where((c) => c.day == DateTime(day.year, day.month, day.day)).toList();

  List<WorkoutCompletion> completionsByUser(String userId) =>
      _completions.where((c) => c.userId == userId).toList();

  bool completedByUser(DateTime day, String userId) =>
      completionsFor(day).any((c) => c.userId == userId);

  int streakFor(String userId) =>
      WorkoutStats.streakFor(completionsByUser(userId).map((c) => c.day));

  int get myStreak => streakFor(myId);
  int get partnerStreak => streakFor(partnerId);

  int get sessionsThisWeek => WorkoutStats.sessionsThisWeek(logs);
  int get sessionsLastWeek => WorkoutStats.sessionsLastWeek(logs);
  Set<String> get distinctExerciseNames => WorkoutStats.distinctExerciseNames(logs);
  Map<String, int> get muscleGroupCounts => WorkoutStats.muscleGroupCounts(logs);

  @override
  void dispose() {
    _realtime.dispose();
    super.dispose();
  }
}
