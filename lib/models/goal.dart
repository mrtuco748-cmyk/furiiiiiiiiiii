class Goal {
  final int id;
  final String coupleId;
  final String title;
  final String? description;
  final bool completed;

  Goal({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    this.completed = false,
  });

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: m['id'] as int,
        coupleId: m['couple_id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        completed: m['completed'] as bool? ?? false,
      );
}
