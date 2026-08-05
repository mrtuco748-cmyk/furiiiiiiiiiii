class Message {
  final int id;
  final String fromUser;
  final String toUser;
  final String content;
  final bool read;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? replyToId;
  final String? replyContent;
  final String messageType;
  final String? attachmentUrl;
  final bool starred;
  final bool edited;
  final Map<String, List<String>>? reactions;

  Message({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.content,
    this.read = false,
    this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.replyToId,
    this.replyContent,
    this.messageType = 'text',
    this.attachmentUrl,
    this.starred = false,
    this.edited = false,
    this.reactions,
  });

  factory Message.fromMap(Map<String, dynamic> m) => Message(
        id: m['id'] as int,
        fromUser: m['from_user'] as String,
        toUser: m['to_user'] as String,
        content: m['content'] as String,
        read: m['read'] as bool? ?? false,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
        deliveredAt: m['delivered_at'] != null
            ? DateTime.tryParse(m['delivered_at'] as String)
            : null,
        readAt: m['read_at'] != null
            ? DateTime.tryParse(m['read_at'] as String)
            : null,
        replyToId: m['reply_to_id'] as String?,
        replyContent: m['reply_content'] as String?,
        messageType: m['message_type'] as String? ?? 'text',
        attachmentUrl: m['attachment_url'] as String?,
        starred: m['starred'] as bool? ?? false,
        edited: m['edited'] as bool? ?? false,
        reactions: m['reactions'] != null
            ? (m['reactions'] as Map).map(
                (k, v) => MapEntry(k as String, (v as List).cast<String>()))
            : null,
      );

  Map<String, dynamic> toMap() => {
        'from_user': fromUser,
        'to_user': toUser,
        'content': content,
        'read': read,
        'created_at': createdAt?.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
        'reply_to_id': replyToId,
        'reply_content': replyContent,
        'message_type': messageType,
        'attachment_url': attachmentUrl,
        'starred': starred,
        'edited': edited,
        'reactions': reactions,
      };

  Message copyWith({
    int? id,
    String? fromUser,
    String? toUser,
    String? content,
    bool? read,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? replyToId,
    String? replyContent,
    String? messageType,
    String? attachmentUrl,
    bool? starred,
    bool? edited,
    Map<String, List<String>>? reactions,
  }) =>
      Message(
        id: id ?? this.id,
        fromUser: fromUser ?? this.fromUser,
        toUser: toUser ?? this.toUser,
        content: content ?? this.content,
        read: read ?? this.read,
        createdAt: createdAt ?? this.createdAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        readAt: readAt ?? this.readAt,
        replyToId: replyToId ?? this.replyToId,
        replyContent: replyContent ?? this.replyContent,
        messageType: messageType ?? this.messageType,
        attachmentUrl: attachmentUrl ?? this.attachmentUrl,
        starred: starred ?? this.starred,
        edited: edited ?? this.edited,
        reactions: reactions ?? this.reactions,
      );
}
