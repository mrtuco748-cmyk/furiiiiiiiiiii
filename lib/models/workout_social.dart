/// Reacciones y comentarios embebidos en el campo `social` JSONB de las
/// entidades de Ejercicios. Mismo formato que el chat y el pizarrón:
/// reacciones `{key: [userIds]}`, max 5 keys, 1 por usuario por key.
class WorkoutComment {
  final String id;
  final String userId;
  final String text;
  final DateTime? createdAt;
  final String? replyToId;

  const WorkoutComment({
    required this.id,
    required this.userId,
    required this.text,
    this.createdAt,
    this.replyToId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'text': text,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (replyToId != null) 'replyToId': replyToId,
      };

  factory WorkoutComment.fromMap(Map<String, dynamic> m) => WorkoutComment(
        id: m['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: m['userId']?.toString() ?? '',
        text: m['text']?.toString() ?? '',
        createdAt: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt'].toString())
            : null,
        replyToId: m['replyToId']?.toString(),
      );
}

class WorkoutSocial {
  static const int maxReactionKeys = 5;

  final Map<String, List<String>> reactions;
  final List<WorkoutComment> comments;

  const WorkoutSocial({this.reactions = const {}, this.comments = const []});


  /// Agrega o quita la reacción del usuario. Si se alcanza el límite de 5
  /// keys, devuelve la MISMA instancia (el caller puede detectarlo con
  /// `identical`) para dar feedback visual.
  WorkoutSocial toggleReaction({required String userId, required String key}) {
    final next = <String, List<String>>{};
    for (final e in reactions.entries) {
      next[e.key] = List<String>.from(e.value);
    }

    final alreadyThis = next[key]?.contains(userId) ?? false;

    for (final k in next.keys.toList()) {
      next[k] = next[k]!.where((id) => id != userId).toList();
      if (next[k]!.isEmpty) next.remove(k);
    }

    if (alreadyThis) {
      return WorkoutSocial(reactions: next, comments: comments);
    }

    if (!next.containsKey(key) && next.length >= maxReactionKeys) {
      return this;
    }

    next.putIfAbsent(key, () => <String>[]).add(userId);
    return WorkoutSocial(reactions: next, comments: comments);
  }

  String? myReactionKey(String userId) {
    for (final entry in reactions.entries) {
      if (entry.value.contains(userId)) return entry.key;
    }
    return null;
  }

  WorkoutSocial addComment({
    required String id,
    required String userId,
    required String text,
    String? replyToId,
  }) {
    final next = List<WorkoutComment>.from(comments)
      ..add(WorkoutComment(
        id: id,
        userId: userId,
        text: text,
        createdAt: DateTime.now(),
        replyToId: replyToId,
      ));
    return WorkoutSocial(reactions: reactions, comments: next);
  }

  /// Borra el comentario y sus respuestas en cascada (evita huérfanos).
  WorkoutSocial deleteComment(String commentId) {
    final next = comments
        .where((c) => c.id != commentId && c.replyToId != commentId)
        .toList();
    return WorkoutSocial(reactions: reactions, comments: next);
  }

  Map<String, dynamic> toMap() => {
        'reactions': reactions,
        'comments': comments.map((c) => c.toMap()).toList(),
      };

  /// Unión de user_ids por key (sin duplicados). El campo social se envía
  /// completo en cada update; al mergear en el realtime, dos reacciones
  /// concurrentes se preservan en vez de pisarse.
  static Map<String, List<String>> mergeReactions(
    Map<String, List<String>> a,
    Map<String, List<String>> b,
  ) {
    final out = <String, List<String>>{};
    for (final e in [...a.entries, ...b.entries]) {
      final list = out.putIfAbsent(e.key, () => <String>[]);
      for (final uid in e.value) {
        if (!list.contains(uid)) list.add(uid);
      }
    }
    return out;
  }

  /// Unión por id de comentario (append-only: los comentarios no se editan).
  static List<WorkoutComment> mergeComments(
    List<WorkoutComment> a,
    List<WorkoutComment> b,
  ) {
    final byId = <String, WorkoutComment>{};
    for (final c in [...a, ...b]) {
      byId[c.id] = c;
    }
    return byId.values.toList();
  }

  factory WorkoutSocial.fromMap(dynamic raw) {
    if (raw is! Map) return const WorkoutSocial();
    final outReactions = <String, List<String>>{};
    final rawReactions = raw['reactions'];
    if (rawReactions is Map) {
      rawReactions.forEach((k, v) {
        final key = k.toString();
        if (v is List) {
          outReactions[key] = v.map((e) => e.toString()).toList();
        }
      });
    }
    final outComments = <WorkoutComment>[];
    final rawComments = raw['comments'];
    if (rawComments is List) {
      for (final c in rawComments) {
        if (c is Map) {
          outComments
              .add(WorkoutComment.fromMap(Map<String, dynamic>.from(c)));
        }
      }
    }
    return WorkoutSocial(reactions: outReactions, comments: outComments);
  }
}
