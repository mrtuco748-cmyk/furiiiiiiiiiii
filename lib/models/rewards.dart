// Recompensas físicas de pareja + puntos. Modelos y lógica pura testeable.

/// Una recompensa deseada (cajita de deseos) que cuesta puntos y se puede
/// marcar como cumplida.
class CoupleReward {
  final int? id;
  final String title;
  final String emoji;
  final int cost;
  final bool fulfilled;
  final String? createdBy;

  const CoupleReward({
    this.id,
    required this.title,
    required this.emoji,
    required this.cost,
    this.fulfilled = false,
    this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'emoji': emoji,
        'cost': cost,
        'fulfilled': fulfilled,
        if (createdBy != null) 'created_by': createdBy,
      };

  factory CoupleReward.fromMap(Map<String, dynamic> m) => CoupleReward(
        id: _parseInt(m['id']),
        title: m['title']?.toString() ?? '',
        emoji: m['emoji']?.toString() ?? '🎁',
        cost: _parseInt(m['cost']) ?? 0,
        fulfilled: m['fulfilled'] == true,
        createdBy: m['created_by']?.toString(),
      );

  CoupleReward copyWith({int? id, String? title, String? emoji, int? cost, bool? fulfilled}) =>
      CoupleReward(
        id: id ?? this.id,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        cost: cost ?? this.cost,
        fulfilled: fulfilled ?? this.fulfilled,
        createdBy: createdBy,
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

/// Un movimiento en el libro de puntos (deltas positivos suman, negativos gastan).
class PointsEntry {
  final int? id;
  final String userId;
  final String reason;
  final int delta;
  final DateTime? createdAt;

  const PointsEntry({
    this.id,
    required this.userId,
    required this.reason,
    required this.delta,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'reason': reason,
        'delta': delta,
      };

  factory PointsEntry.fromMap(Map<String, dynamic> m) => PointsEntry(
        id: _parseInt(m['id']),
        userId: m['user_id']?.toString() ?? '',
        reason: m['reason']?.toString() ?? '',
        delta: _parseInt(m['delta']) ?? 0,
        createdAt: m['created_at'] is String
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

/// Lógica pura del balance de puntos.
class PointsStats {
  static int balanceOf(Iterable<PointsEntry> entries, String userId) =>
      entries
          .where((e) => e.userId == userId)
          .fold(0, (s, e) => s + e.delta);

  static int total(Iterable<PointsEntry> entries) =>
      entries.fold(0, (s, e) => s + e.delta);

  static int pointsEarned(Iterable<PointsEntry> entries, String userId) =>
      entries
          .where((e) => e.userId == userId && e.delta > 0)
          .fold(0, (s, e) => s + e.delta);
}