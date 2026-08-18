class Schedule {
  final int? id;
  final int? cloudId;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String instructor;
  final String type;
  final int color;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    this.id,
    this.cloudId,
    required this.title,
    this.description = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.instructor = '',
    this.type = 'Clase',
    this.color = 0xFF7B2D8E,
    this.userId = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Mapa para SQLite local (camelCase, con cloudId).
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (cloudId != null) 'cloudId': cloudId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'instructor': instructor,
      'type': type,
      'color': color,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Mapa para Supabase (mismas columnas de la tabla cloud:
  /// user_id snake_case, sin id ni cloudId — el id lo asigna el servidor).
  Map<String, dynamic> toSupabaseMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String().substring(0, 10),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'instructor': instructor,
      'type': type,
      'color': color,
      'user_id': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as int?,
      cloudId: map['cloudId'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      location: map['location'] as String? ?? '',
      instructor: map['instructor'] as String? ?? '',
      type: map['type'] as String? ?? 'Clase',
      color: map['color'] as int? ?? 0xFF7B2D8E,
      userId: (map['userId'] ?? map['user_id']) as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Fila de Supabase: el id del servidor pasa a ser el cloudId.
  factory Schedule.fromCloudRow(Map<String, dynamic> row) {
    return Schedule(
      cloudId: row['id'] as int?,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      date: DateTime.parse(row['date'] as String),
      startTime: row['startTime'] as String,
      endTime: row['endTime'] as String,
      location: row['location'] as String? ?? '',
      instructor: row['instructor'] as String? ?? '',
      type: row['type'] as String? ?? 'Clase',
      color: row['color'] as int? ?? 0xFF7B2D8E,
      userId: (row['user_id'] ?? row['userId']) as String? ?? '',
      createdAt: DateTime.parse(row['createdAt'] as String),
      updatedAt: DateTime.parse(row['updatedAt'] as String),
    );
  }

  Schedule copyWith({
    int? id,
    int? cloudId,
    String? title,
    String? description,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    String? instructor,
    String? type,
    int? color,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      instructor: instructor ?? this.instructor,
      type: type ?? this.type,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
