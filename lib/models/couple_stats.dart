/// Cada registro de actividad de un miembro de la pareja en un día.
/// Se construye desde las tablas que tienen `user_id` y fecha (`moods`,
/// `workout_completions`, ...) para saber quién estuvo "activo" cada día.
class CoupleActivity {
  final String userId;
  final DateTime day;

  const CoupleActivity({required this.userId, required this.day});

  DateTime get dayOnly => DateTime(day.year, day.month, day.day);

  factory CoupleActivity.fromMap(Map<String, dynamic> m) {
    final raw = m['date'] ?? m['completed_on'] ?? m['created_at'];
    return CoupleActivity(
      userId: m['user_id']?.toString() ?? '',
      day: DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Lógica pura de la "racha de pareja": días consecutivos en que AMBOS
/// miembros de la pareja estuvieron activos. Testeable sin Supabase,
/// espejando `WorkoutStats`.
class CoupleStats {
  /// Agrupa actividades por día, devolviendo el conjunto de usuarios activos
  /// ese día.
  static Map<DateTime, Set<String>> activeByDay(
    Iterable<CoupleActivity> activities,
  ) {
    final out = <DateTime, Set<String>>{};
    for (final a in activities) {
      (out[a.dayOnly] ??= <String>{}).add(a.userId);
    }
    return out;
  }

  /// Días en que TODOS los miembros del set `members` estuvieron activos.
  static Set<DateTime> bothActiveDays(
    Map<DateTime, Set<String>> activeByDay, {
    required Set<String> members,
  }) {
    return activeByDay.entries
        .where((e) => members.every(e.value.contains))
        .map((e) => e.key)
        .toSet();
  }

  /// Racha actual: días consecutivos en que ambos estuvieron activos,
  /// terminando en hoy (o ayer si hoy todavía no está completo).
  static int streakFor(Set<DateTime> bothDays, {DateTime? today}) {
    final now = _dateOnly(today ?? DateTime.now());
    var cursor = bothDays.contains(now)
        ? now
        : now.subtract(const Duration(days: 1));
    var streak = 0;
    while (bothDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Racha más larga registrada.
  static int bestStreak(Set<DateTime> bothDays) {
    if (bothDays.isEmpty) return 0;
    final sorted = bothDays.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      run = sorted[i].difference(sorted[i - 1]).inDays == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }
    return best;
  }

  /// Dice si el día dado fue un día activo de ambos.
  static bool isBothActiveOn(Set<DateTime> bothDays, DateTime day) =>
      bothDays.contains(_dateOnly(day));

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}