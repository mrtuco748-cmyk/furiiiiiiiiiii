import '../app_state.dart';

class FavoriteItem {
  final int? id;
  final String? userId;
  final String category;
  final String title;
  final String? critica;
  final String emoji;
  final double ratingFacu;
  final double ratingRocio;
  final bool favorited;
  final DateTime createdAt;

  FavoriteItem({
    this.id,
    required this.category,
    required this.title,
    this.critica,
    this.emoji = '⭐',
    this.ratingFacu = 0,
    this.ratingRocio = 0,
    this.favorited = false,
    this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category': category,
    'title': title,
    'critica': critica,
    'emoji': emoji,
    'rating_facu': ratingFacu,
    'rating_rocio': ratingRocio,
    'favorited': favorited,
    'user_id': userId ?? AppState.myId ?? '',
    'created_at': createdAt.toIso8601String(),
  };

  factory FavoriteItem.fromMap(Map<String, dynamic> m) {
    final ratingFacu = (m['rating_facu'] as num?)?.toDouble()
        ?? (m['rating'] as num?)?.toDouble()
        ?? 0;
    final ratingRocio = (m['rating_rocio'] as num?)?.toDouble() ?? 0;
    return FavoriteItem(
      id: m['id'] as int?,
      category: m['category'] as String? ?? '',
      title: m['title'] as String? ?? '',
      critica: (m['critica'] as String?) ?? (m['subtitle'] as String?),
      emoji: m['emoji'] as String? ?? '⭐',
      ratingFacu: ratingFacu,
      ratingRocio: ratingRocio,
      favorited: m['favorited'] as bool? ?? false,
      userId: m['user_id'] as String?,
      createdAt: m['created_at'] != null
          ? DateTime.parse(m['created_at'] as String)
          : DateTime.now(),
    );
  }

  FavoriteItem copyWith({
    bool? favorited,
    double? ratingFacu,
    double? ratingRocio,
    String? critica,
    String? emoji,
    String? category,
    String? title,
  }) =>
      FavoriteItem(
        id: id,
        category: category ?? this.category,
        title: title ?? this.title,
        critica: critica ?? this.critica,
        emoji: emoji ?? this.emoji,
        ratingFacu: ratingFacu ?? this.ratingFacu,
        ratingRocio: ratingRocio ?? this.ratingRocio,
        favorited: favorited ?? this.favorited,
        userId: userId,
        createdAt: createdAt,
      );

  double ratingFor(String identity) {
    if (identity == 'Facu') return ratingFacu;
    if (identity == 'Rocio') return ratingRocio;
    return 0;
  }

  bool get hasFacuRating => ratingFacu > 0;
  bool get hasRocioRating => ratingRocio > 0;
  bool get hasAnyRating => hasFacuRating || hasRocioRating;
  bool get bothRated => hasFacuRating && hasRocioRating;

  double get averageRating {
    if (bothRated) return (ratingFacu + ratingRocio) / 2;
    if (hasFacuRating) return ratingFacu;
    if (hasRocioRating) return ratingRocio;
    return 0;
  }
}
