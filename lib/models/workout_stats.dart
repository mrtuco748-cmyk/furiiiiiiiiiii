import 'workout_log.dart';

/// Un punto de la evolución del peso de un ejercicio.
class WeightEntry {
  final DateTime date;
  final double weight;

  const WeightEntry({required this.date, required this.weight});
}

/// Lógica pura de estadísticas de Ejercicios (testeable sin Supabase).
class WorkoutStats {
  /// Días consecutivos entrenados terminando en hoy (o ayer, si hoy
  /// todavía no se entrenó).
  static int streakFor(Iterable<DateTime> days, {DateTime? today}) {
    final now = _dateOnly(today ?? DateTime.now());
    final set = days.map(_dateOnly).toSet();
    var cursor = set.contains(now)
        ? now
        : now.subtract(const Duration(days: 1));
    var streak = 0;
    while (set.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Historial de pesos de un ejercicio, ordenado por fecha ascendente.
  /// Solo incluye registros con peso.
  static List<WeightEntry> weightHistoryFor(
    List<WorkoutLog> logs,
    String exerciseName,
  ) {
    final out = <WeightEntry>[];
    for (final l in logs) {
      if (l.weight == null) continue;
      if (l.exerciseName.trim().toLowerCase() !=
          exerciseName.trim().toLowerCase()) {
        continue;
      }
      out.add(WeightEntry(date: _dateOnly(l.loggedOn), weight: l.weight!));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// Último peso registrado de un ejercicio, o null si nunca se registró.
  static double? lastWeightFor(List<WorkoutLog> logs, String exerciseName) {
    final history = weightHistoryFor(logs, exerciseName);
    if (history.isEmpty) return null;
    return history.last.weight;
  }

  /// Sesiones (logs) de la semana de `now` (lunes a domingo).
  static int sessionsThisWeek(List<WorkoutLog> logs, {DateTime? now}) {
    final monday = _mondayOf(now ?? DateTime.now());
    final nextMonday = monday.add(const Duration(days: 7));
    return logs.where((l) {
      final d = _dateOnly(l.loggedOn);
      return !d.isBefore(monday) && d.isBefore(nextMonday);
    }).length;
  }

  /// Sesiones (logs) de la semana anterior a la de `now`.
  static int sessionsLastWeek(List<WorkoutLog> logs, {DateTime? now}) {
    final monday = _mondayOf(now ?? DateTime.now());
    final prevMonday = monday.subtract(const Duration(days: 7));
    return logs.where((l) {
      final d = _dateOnly(l.loggedOn);
      return !d.isBefore(prevMonday) && d.isBefore(monday);
    }).length;
  }

  /// Nombres de ejercicios únicos registrados.
  static Set<String> distinctExerciseNames(List<WorkoutLog> logs) =>
      logs.map((l) => l.exerciseName.trim()).where((n) => n.isNotEmpty).toSet();

  /// Cantidad de logs por grupo muscular (ignora nulos/vacíos).
  static Map<String, int> muscleGroupCounts(List<WorkoutLog> logs) {
    final out = <String, int>{};
    for (final l in logs) {
      final g = l.muscleGroup?.trim() ?? '';
      if (g.isEmpty) continue;
      out[g] = (out[g] ?? 0) + 1;
    }
    return out;
  }

  static DateTime _mondayOf(DateTime d) {
    final day = _dateOnly(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
