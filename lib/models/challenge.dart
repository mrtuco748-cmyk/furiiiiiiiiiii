class Challenge {
  final int id;
  final String coupleId;
  final String title;
  final int? durationDays;
  final int currentDay;
  final bool started;
  final bool completed;

  Challenge({
    required this.id,
    required this.coupleId,
    required this.title,
    this.durationDays,
    this.currentDay = 0,
    this.started = false,
    this.completed = false,
  });

  factory Challenge.fromMap(Map<String, dynamic> m) => Challenge(
        id: m['id'] as int,
        coupleId: m['couple_id'] as String,
        title: m['title'] as String,
        durationDays: m['duration_days'] as int?,
        currentDay: m['current_day'] as int? ?? 0,
        started: m['started'] as bool? ?? false,
        completed: m['completed'] as bool? ?? false,
      );
}
