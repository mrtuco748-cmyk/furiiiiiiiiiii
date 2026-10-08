class Note {
  final int? id;
  final int? cloudId;
  final String userId;
  final String title;
  final String content;
  final String color;
  final String? createdAt;
  final String? updatedAt;

  Note({
    this.id,
    this.cloudId,
    this.userId = '',
    required this.title,
    required this.content,
    this.color = '#FFF9C4',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cloudId': cloudId,
      'userId': userId,
      'title': title,
      'content': content,
      'color': color,
      'created_at': createdAt ?? '',
      'updated_at': updatedAt ?? '',
    };
  }

  /// Mapeo hacia la tabla cloud `notes` (user_id snake_case, sin id local).
  Map<String, dynamic> toSupabaseMap() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'color': color,
      'created_at': createdAt,
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      cloudId: (map['cloudId'] ?? map['cloud_id']) as int?,
      userId: (map['userId'] ?? map['user_id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      content: (map['content'] ?? '') as String,
      color: (map['color'] ?? '#FFF9C4') as String,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Deserializa una fila de la nube (el id es el cloudId; sin id local).
  factory Note.fromCloudRow(Map<String, dynamic> m) {
    return Note(
      cloudId: m['id'] as int?,
      userId: m['user_id']?.toString() ?? '',
      title: (m['title'] ?? '') as String,
      content: (m['content'] ?? '') as String,
      color: (m['color'] ?? '#FFF9C4') as String,
      createdAt: m['created_at']?.toString(),
      updatedAt: m['updated_at']?.toString(),
    );
  }

  Note copyWith({
    int? cloudId,
    String? userId,
    String? title,
    String? content,
    String? color,
    bool clearCloudId = false,
  }) {
    return Note(
      id: id,
      cloudId: clearCloudId ? null : (cloudId ?? this.cloudId),
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  String get colorHex => color.replaceFirst('#', '');
}