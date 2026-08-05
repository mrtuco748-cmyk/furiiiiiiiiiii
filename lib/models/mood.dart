class Mood {
  final int id;
  final String userId;
  final String mood;
  final String? note;
  final String? date;

  Mood({
    required this.id,
    required this.userId,
    required this.mood,
    this.note,
    this.date,
  });

  factory Mood.fromMap(Map<String, dynamic> m) => Mood(
        id: m['id'] as int,
        userId: m['user_id'] as String,
        mood: m['mood'] as String,
        note: m['note'] as String?,
        date: m['date'] as String?,
      );
}
