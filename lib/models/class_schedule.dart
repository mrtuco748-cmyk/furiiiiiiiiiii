class ClassSchedule {
  final int? id;
  final int? cloudId;
  final int dayOfWeek;
  final int? classTypeId;
  final String startTime;
  final String title;
  final String endTime;
  final String professor;
  final String userId;
  final int color;

  ClassSchedule({
    this.id,
    this.cloudId,
    required this.dayOfWeek,
    this.classTypeId,
    required this.startTime,
    required this.title,
    this.endTime = '',
    this.professor = '',
    this.userId = '',
    this.color = 0xFF7B2D8E,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    if (cloudId != null) 'cloudId': cloudId,
    'dayOfWeek': dayOfWeek,
    'classTypeId': classTypeId,
    'startTime': startTime,
    'title': title,
    'endTime': endTime,
    'professor': professor,
    'userId': userId,
    'color': color,
  };

  factory ClassSchedule.fromMap(Map<String, dynamic> map) => ClassSchedule(
    id: map['id'] as int?,
    cloudId: map['cloudId'] as int?,
    dayOfWeek: map['dayOfWeek'] as int,
    classTypeId: map['classTypeId'] as int?,
    startTime: map['startTime'] as String,
    title: map['title'] as String,
    endTime: (map['endTime'] as String?) ?? '',
    professor: (map['professor'] as String?) ?? '',
    userId: (map['userId'] as String?) ?? '',
    color: (map['color'] as int?) ?? 0xFF7B2D8E,
  );

  /// Fila de Supabase: el id del servidor pasa a ser el cloudId.
  factory ClassSchedule.fromCloudRow(Map<String, dynamic> row) => ClassSchedule(
    cloudId: row['id'] as int?,
    dayOfWeek: row['day_of_week'] as int,
    classTypeId: row['class_type_id'] as int?,
    startTime: row['start_time'] as String,
    title: row['title'] as String,
    endTime: (row['end_time'] as String?) ?? '',
    professor: (row['professor'] as String?) ?? '',
    userId: (row['user_id'] as String?) ?? '',
    color: (row['color'] as int?) ?? 0xFF7B2D8E,
  );

  ClassSchedule copyWith({
    int? id,
    int? cloudId,
    int? dayOfWeek,
    int? classTypeId,
    String? startTime,
    String? title,
    String? endTime,
    String? professor,
    String? userId,
    int? color,
  }) => ClassSchedule(
    id: id ?? this.id,
    cloudId: cloudId ?? this.cloudId,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    classTypeId: classTypeId ?? this.classTypeId,
    startTime: startTime ?? this.startTime,
    title: title ?? this.title,
    endTime: endTime ?? this.endTime,
    professor: professor ?? this.professor,
    userId: userId ?? this.userId,
    color: color ?? this.color,
  );

  Map<String, dynamic> toSupabaseMap() => {
    'day_of_week': dayOfWeek,
    'class_type_id': classTypeId,
    'start_time': startTime,
    'title': title,
    'end_time': endTime,
    'professor': professor,
    'user_id': userId,
    'color': color,
  };
}
