/// Marca de "entrené este día" por persona. Cada usuario completa su propio
/// entrenamiento (badges F/R por día, como el calendario).
class WorkoutCompletion {
  final int? id;
  final String userId;
  final DateTime completedOn;
  final int? routineId;
  final DateTime? createdAt;

  WorkoutCompletion({
    this.id,
    required this.userId,
    DateTime? completedOn,
    this.routineId,
    this.createdAt,
  }) : completedOn = completedOn ?? DateTime.now();

  DateTime get day =>
      DateTime(completedOn.year, completedOn.month, completedOn.day);

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'completed_on': _dateOnly(completedOn),
        if (routineId != null) 'routine_id': routineId,
      };

  factory WorkoutCompletion.fromMap(Map<String, dynamic> m) =>
      WorkoutCompletion(
        id: _parseInt(m['id']),
        userId: m['user_id']?.toString() ?? '',
        completedOn: _parseDate(m['completed_on']),
        routineId: _parseInt(m['routine_id']),
        createdAt: _parseDt(m['created_at']),
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
