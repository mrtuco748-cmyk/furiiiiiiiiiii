class Letter {
  final int id;
  final String fromUser;
  final String toUser;
  final String title;
  final String content;
  final bool isOpened;
  final DateTime? scheduledOpen;
  final DateTime? createdAt;

  Letter({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.title,
    required this.content,
    this.isOpened = false,
    this.scheduledOpen,
    this.createdAt,
  });

  factory Letter.fromMap(Map<String, dynamic> m) => Letter(
        id: m['id'] as int,
        fromUser: m['from_user'] as String,
        toUser: m['to_user'] as String,
        title: m['title'] as String,
        content: m['content'] as String,
        isOpened: m['is_opened'] as bool? ?? false,
        scheduledOpen: m['scheduled_open'] != null
            ? DateTime.tryParse(m['scheduled_open'] as String)
            : null,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );
}
