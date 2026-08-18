import 'workout_social.dart';

/// Reto de ejercicio con aprobación y completado conjuntos: ambos usuarios
/// deben aprobar para que quede activo, y ambos deben marcarlo completado.
class WorkoutChallenge {
  static const int approvalsNeeded = 2;

  final int? id;
  final String title;
  final String? description;
  final String createdBy;
  final List<String> approvedBy;
  final List<String> completedBy;
  final WorkoutSocial social;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutChallenge({
    this.id,
    required this.title,
    this.description,
    this.createdBy = '',
    List<String>? approvedBy,
    List<String>? completedBy,
    WorkoutSocial? social,
    this.createdAt,
    this.updatedAt,
  })  : approvedBy = approvedBy ?? const [],
        completedBy = completedBy ?? const [],
        social = social ?? const WorkoutSocial();

  bool get isValid => title.trim().isNotEmpty;

  bool get isApproved => approvedBy.length >= approvalsNeeded;
  bool get isCompleted => completedBy.length >= approvalsNeeded;

  bool approvedByUser(String userId) => approvedBy.contains(userId);
  bool completedByUser(String userId) => completedBy.contains(userId);

  /// Agrega o quita la aprobación del usuario (sin duplicados).
  WorkoutChallenge toggleApproval(String userId) {
    final next = List<String>.from(approvedBy);
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    return copyWith(approvedBy: next);
  }

  /// Agrega o quita el completado del usuario (sin duplicados).
  WorkoutChallenge toggleCompletion(String userId) {
    final next = List<String>.from(completedBy);
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    return copyWith(completedBy: next);
  }

  String? myReactionKey(String userId) => social.myReactionKey(userId);

  WorkoutChallenge toggleReaction({
    required String userId,
    required String key,
  }) {
    final next = social.toggleReaction(userId: userId, key: key);
    if (identical(next, social)) return this;
    return copyWith(social: next);
  }

  WorkoutChallenge addComment({
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

  WorkoutChallenge deleteComment(String commentId) =>
      copyWith(social: social.deleteComment(commentId));

  Map<String, dynamic> toMap() => {
        'title': title,
        if (description != null) 'description': description,
        'created_by': createdBy,
        'approved_by': approvedBy,
        'completed_by': completedBy,
        'social': social.toMap(),
      };

  factory WorkoutChallenge.fromMap(Map<String, dynamic> m) =>
      WorkoutChallenge(
        id: _parseInt(m['id']),
        title: m['title']?.toString() ?? '',
        description: m['description']?.toString(),
        createdBy: m['created_by']?.toString() ?? '',
        approvedBy: _parseStringList(m['approved_by']),
        completedBy: _parseStringList(m['completed_by']),
        social: WorkoutSocial.fromMap(m['social']),
        createdAt: _parseDt(m['created_at']),
        updatedAt: _parseDt(m['updated_at']),
      );

  WorkoutChallenge copyWith({
    int? id,
    String? title,
    String? description,
    String? createdBy,
    List<String>? approvedBy,
    List<String>? completedBy,
    WorkoutSocial? social,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
  }) =>
      WorkoutChallenge(
        id: id ?? this.id,
        title: title ?? this.title,
        description: clearDescription ? null : (description ?? this.description),
        createdBy: createdBy ?? this.createdBy,
        approvedBy: approvedBy ?? this.approvedBy,
        completedBy: completedBy ?? this.completedBy,
        social: social ?? this.social,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
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
