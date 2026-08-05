class Anniversary {
  final int id;
  final String coupleId;
  final String title;
  final String date;
  final int reminderDaysBefore;

  Anniversary({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.date,
    this.reminderDaysBefore = 7,
  });

  factory Anniversary.fromMap(Map<String, dynamic> m) => Anniversary(
        id: m['id'] as int,
        coupleId: m['couple_id'] as String,
        title: m['title'] as String,
        date: m['date'] as String,
        reminderDaysBefore: m['reminder_days_before'] as int? ?? 7,
      );
}
