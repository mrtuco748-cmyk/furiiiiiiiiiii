class ClassSchedule {
  final int? id;
  final int dayOfWeek;
  final int? classTypeId;
  final String startTime;
  final String title;

  ClassSchedule({
    this.id,
    required this.dayOfWeek,
    this.classTypeId,
    required this.startTime,
    required this.title,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'dayOfWeek': dayOfWeek,
    'classTypeId': classTypeId,
    'startTime': startTime,
    'title': title,
  };

  factory ClassSchedule.fromMap(Map<String, dynamic> map) => ClassSchedule(
    id: map['id'] as int?,
    dayOfWeek: map['dayOfWeek'] as int,
    classTypeId: map['classTypeId'] as int?,
    startTime: map['startTime'] as String,
    title: map['title'] as String,
  );
}
