import 'workout_social.dart';

/// Un ejercicio dentro de una rutina. El nombre es obligatorio.
class RoutineItem {
  final String exerciseName;
  final int? series;
  final int? reps;
  final double? weight;
  final int? restSeconds;
  final String? notes;

  const RoutineItem({
    required this.exerciseName,
    this.series,
    this.reps,
    this.weight,
    this.restSeconds,
    this.notes,
  });

  bool get isValid => exerciseName.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'exerciseName': exerciseName,
        if (series != null) 'series': series,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
        if (restSeconds != null) 'restSeconds': restSeconds,
        if (notes != null) 'notes': notes,
      };

  factory RoutineItem.fromMap(Map<String, dynamic> m) => RoutineItem(
        exerciseName: m['exerciseName']?.toString() ?? '',
        series: _parseInt(m['series']),
        reps: _parseInt(m['reps']),
        weight: _parseDouble(m['weight']),
        restSeconds: _parseInt(m['restSeconds']),
        notes: m['notes']?.toString(),
      );

  RoutineItem copyWith({
    String? exerciseName,
    int? series,
    int? reps,
    double? weight,
    int? restSeconds,
    String? notes,
  }) =>
      RoutineItem(
        exerciseName: exerciseName ?? this.exerciseName,
        series: series ?? this.series,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        restSeconds: restSeconds ?? this.restSeconds,
        notes: notes ?? this.notes,
      );

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
}

/// Rutina de entrenamiento. Puede asignarse a un día de la semana
/// (1=lunes ... 7=domingo) para el plan semanal, o quedar sin día.
class WorkoutRoutine {
  final int? id;
  final String name;
  final int? dayOfWeek;
  final List<RoutineItem> items;
  final String userId;
  final WorkoutSocial social;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutRoutine({
    this.id,
    required this.name,
    this.dayOfWeek,
    List<RoutineItem>? items,
    this.userId = '',
    WorkoutSocial? social,
    this.createdAt,
    this.updatedAt,
  })  : items = items ?? const [],
        social = social ?? const WorkoutSocial();

  bool get isValid => name.trim().isNotEmpty;

  String? myReactionKey(String userId) => social.myReactionKey(userId);

  WorkoutRoutine toggleReaction({required String userId, required String key}) {
    final next = social.toggleReaction(userId: userId, key: key);
    if (identical(next, social)) return this;
    return copyWith(social: next);
  }

  WorkoutRoutine addComment({
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

  WorkoutRoutine deleteComment(String commentId) =>
      copyWith(social: social.deleteComment(commentId));

  WorkoutRoutine addItem(RoutineItem item) =>
      copyWith(items: [...items, item]);

  WorkoutRoutine removeItem(int index) =>
      copyWith(items: [...items]..removeAt(index));

  Map<String, dynamic> toMap() => {
        'name': name,
        if (dayOfWeek != null) 'day_of_week': dayOfWeek,
        'items': items.map((i) => i.toMap()).toList(),
        'user_id': userId,
        'social': social.toMap(),
      };

  factory WorkoutRoutine.fromMap(Map<String, dynamic> m) => WorkoutRoutine(
        id: _parseInt(m['id']),
        name: m['name']?.toString() ?? '',
        dayOfWeek: _parseInt(m['day_of_week']),
        items: _parseItems(m['items']),
        userId: m['user_id']?.toString() ?? '',
        social: WorkoutSocial.fromMap(m['social']),
        createdAt: _parseDt(m['created_at']),
        updatedAt: _parseDt(m['updated_at']),
      );

  WorkoutRoutine copyWith({
    int? id,
    String? name,
    int? dayOfWeek,
    List<RoutineItem>? items,
    String? userId,
    WorkoutSocial? social,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDayOfWeek = false,
  }) =>
      WorkoutRoutine(
        id: id ?? this.id,
        name: name ?? this.name,
        dayOfWeek: clearDayOfWeek ? null : (dayOfWeek ?? this.dayOfWeek),
        items: items ?? this.items,
        userId: userId ?? this.userId,
        social: social ?? this.social,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static List<RoutineItem> _parseItems(dynamic raw) {
    if (raw is! List) return [];
    final out = <RoutineItem>[];
    for (final i in raw) {
      if (i is Map) {
        out.add(RoutineItem.fromMap(Map<String, dynamic>.from(i)));
      }
    }
    return out;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
