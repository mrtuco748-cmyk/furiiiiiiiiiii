/// Modelo de comentario colaborativo en una canción de música.
class MusicComment {
  final int? id;
  final int? cloudId;
  final int trackId;
  final String userId; // 'Facu' o 'Rocio'
  final String content;
  final String createdAt;

  MusicComment({
    this.id,
    this.cloudId,
    required this.trackId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cloud_id': cloudId,
      'track_id': trackId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'track_id': trackId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt,
    };
  }

  factory MusicComment.fromMap(Map<String, dynamic> map) {
    return MusicComment(
      id: map['id'] as int?,
      cloudId: (map['cloud_id'] ?? map['cloudId']) as int?,
      trackId: (map['track_id'] ?? map['trackId'] ?? 0) as int,
      userId: (map['user_id'] ?? map['userId'] ?? '') as String,
      content: (map['content'] ?? '') as String,
      createdAt: (map['created_at'] ?? '') as String,
    );
  }

  factory MusicComment.fromCloudRow(Map<String, dynamic> m) {
    return MusicComment(
      cloudId: m['id'] as int?,
      trackId: (m['track_id'] ?? 0) as int,
      userId: (m['user_id'] ?? '') as String,
      content: (m['content'] ?? '') as String,
      createdAt: m['created_at']?.toString() ?? '',
    );
  }

  MusicComment copyWith({
    int? id,
    int? cloudId,
    int? trackId,
    String? userId,
    String? content,
    String? createdAt,
  }) {
    return MusicComment(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      trackId: trackId ?? this.trackId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
