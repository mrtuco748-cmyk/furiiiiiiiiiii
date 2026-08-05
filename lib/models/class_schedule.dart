class ClassSchedule {
  final int? id;
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
    dayOfWeek: map['dayOfWeek'] as int,
    classTypeId: map['classTypeId'] as int?,
    startTime: map['startTime'] as String,
    title: map['title'] as String,
    endTime: (map['endTime'] as String?) ?? '',
    professor: (map['professor'] as String?) ?? '',
    userId: (map['userId'] as String?) ?? '',
    color: (map['color'] as int?) ?? 0xFF7B2D8E,
  );
}
