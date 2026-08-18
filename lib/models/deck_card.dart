import '../app_state.dart';

class DeckReaction {
  static const encanta = 'encanta';
  static const meGusta = 'me_gusta';
  static const meh = 'meh';
  static const noMeGusta = 'no_me_gusta';

  static const all = [encanta, meGusta, meh, noMeGusta];
}

class DeckCategory {
  static const ideas = 'ideas';
  static const chistes = 'chistes';
  static const poemas = 'poemas';
  static const recetas = 'recetas';
  static const retos = 'retos';
  static const random = 'random';
  static const sueno = 'sueno';
  static const mePaso = 'me_paso';

  static const all = [
    ideas, chistes, poemas, recetas, retos, random, sueno, mePaso,
  ];
}

class DeckCard {
  final int? id;
  final String category;
  final String content;
  final String? createdBy;
  final Map<String, String> reactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeckCard({
    this.id,
    String? category,
    String? content,
    this.createdBy,
    Map<String, String>? reactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : category = category ?? DeckCategory.random,
        content = content ?? '',
        reactions = reactions ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category': category,
        'content': content,
        'created_by': createdBy ?? AppState.myId ?? '',
        'reactions': reactions,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DeckCard.fromMap(Map<String, dynamic> m) {
    final raw = m['reactions'];
    final Map<String, String> reactions = {};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is String) reactions[k] = v;
      });
    }
    return DeckCard(
      id: m['id'] as int?,
      category: m['category'] as String? ?? DeckCategory.random,
      content: m['content'] as String? ?? '',
      createdBy: m['created_by'] as String?,
      reactions: reactions,
      createdAt: _parseDate(m['created_at']),
      updatedAt: _parseDate(m['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is String && v.isNotEmpty) return DateTime.parse(v);
    if (v is DateTime) return v;
    return null;
  }

  String? reactionOf(String? userId) =>
      userId == null ? null : reactions[userId];

  DeckCard withReaction(String userId, String reaction) => DeckCard(
        id: id,
        category: category,
        content: content,
        createdBy: createdBy,
        reactions: {...reactions, userId: reaction},
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, String> mergedReactions(Map<String, String> cloud) =>
      {...cloud, ...reactions};

  DeckCard mergedFromCloud(DeckCard cloud) => DeckCard(
        id: cloud.id ?? id,
        category: cloud.category,
        content: cloud.content,
        createdBy: cloud.createdBy ?? createdBy,
        reactions: mergedReactions(cloud.reactions),
        createdAt: cloud.createdAt,
        updatedAt: cloud.updatedAt.isAfter(updatedAt)
            ? cloud.updatedAt
            : updatedAt,
      );

  bool get isMatch =>
      reactions.length >= 2 &&
      reactions.values.every((r) => r == DeckReaction.encanta);
}
