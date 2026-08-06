class Message {
  static const int maxReactions = 5;
  static const List<String> defaultReactionEmojis = [
    '🥰',
    '😘',
    '😍',
    ':v',
    'xD',
    ':0',
  ];
  static const Set<String> mediaTypes = {
    'image',
    'video',
    'voice',
    'gif',
    'document',
  };

  final int id;
  final String fromUser;
  final String toUser;
  final String content;
  final bool read;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final int? replyToId;
  final String? replyContent;
  final String messageType;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMime;
  final int? attachmentSize;
  final bool cloudDeleted;
  final bool starred;
  final bool edited;
  final Map<String, List<String>> reactions;
  final String? localPath;

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
    this.attachmentName,
    this.attachmentMime,
    this.attachmentSize,
    this.cloudDeleted = false,
    this.starred = false,
    this.edited = false,
    Map<String, List<String>>? reactions,
    this.localPath,
  }) : reactions = reactions ?? const {};

  bool get isMedia => mediaTypes.contains(messageType);

  bool get needsCloudDownload =>
      isMedia &&
      !cloudDeleted &&
      attachmentUrl != null &&
      attachmentUrl!.isNotEmpty &&
      (localPath == null || localPath!.isEmpty);

  bool get hasLocalMedia => localPath != null && localPath!.isNotEmpty;

  int get reactionCount => reactions.length;

  bool canAddReactionKey(String key) =>
      reactions.containsKey(key) || reactions.length < maxReactions;

  String? myReactionKey(String userId) {
    for (final entry in reactions.entries) {
      if (entry.value.contains(userId)) return entry.key;
    }
    return null;
  }

  String get previewText {
    switch (messageType) {
      case 'image':
        return content.trim().isEmpty ? 'Imagen' : content;
      case 'video':
        return content.trim().isEmpty ? 'Video' : content;
      case 'voice':
        return content.trim().isEmpty ? 'Audio' : content;
      case 'gif':
        return content.trim().isEmpty ? 'GIF' : content;
      case 'document':
        if (attachmentName != null && attachmentName!.isNotEmpty) {
          return attachmentName!;
        }
        return content.trim().isEmpty ? 'Archivo' : content;
      default:
        return content;
    }
  }

  Message toggleReaction({required String userId, required String key}) {
    final next = <String, List<String>>{};
    for (final e in reactions.entries) {
      next[e.key] = List<String>.from(e.value);
    }

    final alreadyThis = next[key]?.contains(userId) ?? false;

    for (final k in next.keys.toList()) {
      next[k] = next[k]!.where((id) => id != userId).toList();
      if (next[k]!.isEmpty) next.remove(k);
    }

    if (alreadyThis) {
      return copyWith(reactions: next);
    }

    if (!next.containsKey(key) && next.length >= maxReactions) {
      return this;
    }

    next.putIfAbsent(key, () => <String>[]).add(userId);
    return copyWith(reactions: next);
  }

  factory Message.fromMap(Map<String, dynamic> m, {String? localPath}) {
    return Message(
      id: _parseId(m['id']) ?? 0,
      fromUser: m['from_user']?.toString() ?? '',
      toUser: m['to_user']?.toString() ?? '',
      content: m['content']?.toString() ?? '',
      read: m['read'] as bool? ?? false,
      createdAt: _parseDt(m['created_at']),
      deliveredAt: _parseDt(m['delivered_at']),
      readAt: _parseDt(m['read_at']),
      replyToId: _parseId(m['reply_to_id']),
      replyContent: m['reply_content'] as String?,
      messageType: m['message_type'] as String? ?? 'text',
      attachmentUrl: m['attachment_url'] as String?,
      attachmentName: m['attachment_name'] as String?,
      attachmentMime: m['attachment_mime'] as String?,
      attachmentSize: _parseId(m['attachment_size']),
      cloudDeleted: m['cloud_deleted'] as bool? ?? false,
      starred: m['starred'] as bool? ?? false,
      edited: m['edited'] as bool? ?? false,
      reactions: parseReactions(m['reactions']),
      localPath: localPath,
    );
  }

  Map<String, dynamic> toMap() => {
        'from_user': fromUser,
        'to_user': toUser,
        'content': content,
        'read': read,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (deliveredAt != null)
          'delivered_at': deliveredAt!.toIso8601String(),
        if (readAt != null) 'read_at': readAt!.toIso8601String(),
        if (replyToId != null) 'reply_to_id': replyToId,
        if (replyContent != null) 'reply_content': replyContent,
        'message_type': messageType,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        if (attachmentName != null) 'attachment_name': attachmentName,
        if (attachmentMime != null) 'attachment_mime': attachmentMime,
        if (attachmentSize != null) 'attachment_size': attachmentSize,
        'cloud_deleted': cloudDeleted,
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
    int? replyToId,
    String? replyContent,
    String? messageType,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentMime,
    int? attachmentSize,
    bool? cloudDeleted,
    bool? starred,
    bool? edited,
    Map<String, List<String>>? reactions,
    String? localPath,
    bool clearAttachmentUrl = false,
    bool clearLocalPath = false,
    bool clearReply = false,
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
        replyToId: clearReply ? null : (replyToId ?? this.replyToId),
        replyContent:
            clearReply ? null : (replyContent ?? this.replyContent),
        messageType: messageType ?? this.messageType,
        attachmentUrl: clearAttachmentUrl
            ? null
            : (attachmentUrl ?? this.attachmentUrl),
        attachmentName: attachmentName ?? this.attachmentName,
        attachmentMime: attachmentMime ?? this.attachmentMime,
        attachmentSize: attachmentSize ?? this.attachmentSize,
        cloudDeleted: cloudDeleted ?? this.cloudDeleted,
        starred: starred ?? this.starred,
        edited: edited ?? this.edited,
        reactions: reactions ?? this.reactions,
        localPath: clearLocalPath ? null : (localPath ?? this.localPath),
      );

  static Map<String, List<String>> parseReactions(dynamic raw) {
    if (raw == null) return {};
    if (raw is! Map) return {};
    final out = <String, List<String>>{};
    raw.forEach((k, v) {
      final key = k.toString();
      if (v is List) {
        out[key] = v.map((e) => e.toString()).toList();
      }
    });
    return out;
  }

  static int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
