import 'workout_social.dart';

/// Registro de un ejercicio entrenado (suelto o parte de una rutina).
/// El nombre es obligatorio; el resto de los campos son opcionales.
class WorkoutLog {
  final int? id;
  final String exerciseName;
  final String? muscleGroup;
  final int? series;
  final int? reps;
  final double? weight;
  final int? restSeconds;
  final String? notes;
  final String userId;
  final int? routineId;
  final DateTime loggedOn;
  final WorkoutSocial social;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutLog({
    this.id,
    required this.exerciseName,
    this.muscleGroup,
    this.series,
    this.reps,
    this.weight,
    this.restSeconds,
    this.notes,
    this.userId = '',
    this.routineId,
    DateTime? loggedOn,
    WorkoutSocial? social,
    this.createdAt,
    this.updatedAt,
  })  : loggedOn = loggedOn ?? DateTime.now(),
        social = social ?? const WorkoutSocial();

  bool get isValid => exerciseName.trim().isNotEmpty;

  /// Resumen compacto: "4x10 @ 60kg" con las partes presentes.
  String get summary {
    final parts = <String>[];
    if (series != null && reps != null) {
      parts.add('$series' 'x' '$reps');
    }
    if (weight != null) {
      final w = weight!;
      final txt = w == w.roundToDouble() ? w.round().toString() : '$w';
      parts.add('@ $txt' 'kg');
    }
    return parts.join(' ');
  }

  String? myReactionKey(String userId) => social.myReactionKey(userId);

  WorkoutLog toggleReaction({required String userId, required String key}) {
    final next = social.toggleReaction(userId: userId, key: key);
    if (identical(next, social)) return this;
    return copyWith(social: next);
  }

  WorkoutLog addComment({
    required String id,
    required String userId,
    required String text,
    String? replyToId,
  }) =>
      copyWith(
        social: social.addComment(
          id: id,
          userId: userId,
          text: text,
          replyToId: replyToId,
        ),
      );

  WorkoutLog deleteComment(String commentId) =>
      copyWith(social: social.deleteComment(commentId));

  Map<String, dynamic> toMap() => {
        'exercise_name': exerciseName,
        if (muscleGroup != null) 'muscle_group': muscleGroup,
        if (series != null) 'series': series,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
        if (restSeconds != null) 'rest_seconds': restSeconds,
        if (notes != null) 'notes': notes,
        'user_id': userId,
        if (routineId != null) 'routine_id': routineId,
        'logged_on': _dateOnly(loggedOn),
        'social': social.toMap(),
      };

  factory WorkoutLog.fromMap(Map<String, dynamic> m) => WorkoutLog(
        id: _parseInt(m['id']),
        exerciseName: m['exercise_name']?.toString() ?? '',
        muscleGroup: m['muscle_group']?.toString(),
        series: _parseInt(m['series']),
        reps: _parseInt(m['reps']),
        weight: _parseDouble(m['weight']),
        restSeconds: _parseInt(m['rest_seconds']),
        notes: m['notes']?.toString(),
        userId: m['user_id']?.toString() ?? '',
        routineId: _parseInt(m['routine_id']),
        loggedOn: _parseDate(m['logged_on']),
        social: WorkoutSocial.fromMap(m['social']),
        createdAt: _parseDt(m['created_at']),
        updatedAt: _parseDt(m['updated_at']),
      );

  WorkoutLog copyWith({
    int? id,
    String? exerciseName,
    String? muscleGroup,
    int? series,
    int? reps,
    double? weight,
    int? restSeconds,
    String? notes,
    String? userId,
    int? routineId,
    DateTime? loggedOn,
    WorkoutSocial? social,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearMuscleGroup = false,
    bool clearSeries = false,
    bool clearReps = false,
    bool clearWeight = false,
    bool clearRestSeconds = false,
    bool clearNotes = false,
    bool clearRoutineId = false,
  }) =>
      WorkoutLog(
        id: id ?? this.id,
        exerciseName: exerciseName ?? this.exerciseName,
        muscleGroup:
            clearMuscleGroup ? null : (muscleGroup ?? this.muscleGroup),
        series: clearSeries ? null : (series ?? this.series),
        reps: clearReps ? null : (reps ?? this.reps),
        weight: clearWeight ? null : (weight ?? this.weight),
        restSeconds:
            clearRestSeconds ? null : (restSeconds ?? this.restSeconds),
        notes: clearNotes ? null : (notes ?? this.notes),
        userId: userId ?? this.userId,
        routineId: clearRoutineId ? null : (routineId ?? this.routineId),
        loggedOn: loggedOn ?? this.loggedOn,
        social: social ?? this.social,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
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
