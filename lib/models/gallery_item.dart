import '../app_state.dart';

class GalleryComment {
  final int? id;
  final int? galleryId;
  final String? userId;
  final String content;
  final DateTime createdAt;

  GalleryComment({
    this.id,
    this.galleryId,
    this.userId,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GalleryComment.fromMap(Map<String, dynamic> m) => GalleryComment(
    id: m['id'] as int?,
    galleryId: m['gallery_id'] as int?,
    userId: m['user_id'] as String?,
    content: m['content'] as String? ?? '',
    createdAt: m['created_at'] != null
        ? DateTime.tryParse(m['created_at'] as String)
        : DateTime.now(),
  );
}

class GalleryItem {
  final int? id;
  final String? userId;
  final String url;
  final String? thumbnail;
  final String type;
  final String? album;
  final String? label;
  final String? description;
  final Map<String, List<String>> reactions;
  final double rotation;
  final double size;
  final DateTime createdAt;

  GalleryItem({
    this.id,
    required this.url,
    this.thumbnail,
    this.type = 'photo',
    this.album,
    this.label,
    this.description,
    this.rotation = 0,
    this.size = 1.0,
    this.userId,
    Map<String, List<String>>? reactions,
    DateTime? createdAt,
  })  : reactions = reactions ?? const {},
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'url': url,
    'thumbnail': thumbnail,
    'type': type,
    'album': album,
    'label': label,
    'description': description,
    'reactions': reactions,
    'rotation': rotation,
    'size': size,
    'user_id': AppState.myId ?? '',
    'created_at': createdAt.toIso8601String(),
  };

  factory GalleryItem.fromMap(Map<String, dynamic> m) => GalleryItem(
    id: m['id'] as int?,
    url: m['url'] as String? ?? '',
    thumbnail: m['thumbnail'] as String?,
    type: m['type'] as String? ?? 'photo',
    album: m['album'] as String?,
    label: m['label'] as String?,
    description: m['description'] as String?,
    reactions: parseReactions(m['reactions']),
    rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
    size: (m['size'] as num?)?.toDouble() ?? 1.0,
    userId: m['user_id'] as String?,
    createdAt: m['created_at'] != null
        ? DateTime.parse(m['created_at'] as String)
        : DateTime.now(),
  );

  GalleryItem copyWith({
    String? url,
    String? thumbnail,
    String? description,
    Map<String, List<String>>? reactions,
  }) =>
      GalleryItem(
        id: id,
        userId: userId,
        url: url ?? this.url,
        thumbnail: thumbnail ?? this.thumbnail,
        type: type,
        album: album,
        label: label,
        description: description ?? this.description,
        reactions: reactions ?? this.reactions,
        rotation: rotation,
        size: size,
        createdAt: createdAt,
      );

  static Map<String, List<String>> parseReactions(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    final out = <String, List<String>>{};
    raw.forEach((k, v) {
      final key = k.toString();
      if (v is List) out[key] = v.map((e) => e.toString()).toList();
    });
    return out;
  }
}
