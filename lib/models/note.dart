class Note {
  final int? id;
  final String title;
  final String content;
  final String color;
  final String? createdAt;
  final String? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.color = '#FFF9C4',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'created_at': createdAt ?? '',
      'updated_at': updatedAt ?? '',
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: (map['title'] ?? '') as String,
      content: (map['content'] ?? '') as String,
      color: (map['color'] ?? '#FFF9C4') as String,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Note copyWith({
    String? title,
    String? content,
    String? color,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  String get colorHex => color.replaceFirst('#', '');
}