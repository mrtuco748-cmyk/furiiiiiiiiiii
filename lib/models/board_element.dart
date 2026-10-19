import 'dart:convert';

/// Elemento del Pizarrón infinito (notas, checklists, dibujos).
/// Diseñado para persistencia offline-first en SQLite y sincronización
/// bidireccional en tiempo real con Supabase.
class BoardElement {
  final int? id;
  final int? cloudId;
  final int boardId;
  final String userId;
  final String type; // 'note', 'checklist', 'drawing'
  final String title;
  final String content;
  final String color;
  final double x;
  final double y;
  final double width;
  final double height;
  final Map<String, dynamic> data;
  final int synced;
  final String? createdAt;
  final String? updatedAt;

  BoardElement({
    this.id,
    this.cloudId,
    this.boardId = 1,
    this.userId = '',
    this.type = 'note',
    this.title = '',
    this.content = '',
    this.color = '#9D00FF',
    this.x = 0.0,
    this.y = 0.0,
    this.width = 200.0,
    this.height = 160.0,
    Map<String, dynamic>? data,
    this.synced = 1,
    this.createdAt,
    this.updatedAt,
  }) : data = data ?? const {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cloud_id': cloudId,
      'board_id': boardId,
      'user_id': userId,
      'type': type,
      'title': title,
      'content': content,
      'color': color,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'data': jsonEncode(data),
      'synced': synced,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'board_id': boardId,
      'user_id': userId,
      'type': type,
      'title': title,
      'content': content,
      'color': color,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'data': data,
      'created_at': createdAt,
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory BoardElement.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedData = {};
    if (map['data'] != null) {
      if (map['data'] is Map) {
        parsedData = Map<String, dynamic>.from(map['data'] as Map);
      } else if (map['data'] is String) {
        try {
          parsedData = Map<String, dynamic>.from(
              jsonDecode(map['data'] as String) as Map);
        } catch (_) {
          parsedData = {};
        }
      }
    }

    return BoardElement(
      id: map['id'] as int?,
      cloudId: (map['cloud_id'] ?? map['cloudId']) as int?,
      boardId: (map['board_id'] ?? map['boardId'] ?? 1) as int,
      userId: (map['user_id'] ?? map['userId'] ?? '') as String,
      type: (map['type'] ?? 'note') as String,
      title: (map['title'] ?? '') as String,
      content: (map['content'] ?? '') as String,
      color: (map['color'] ?? '#9D00FF') as String,
      x: ((map['x'] ?? 0.0) as num).toDouble(),
      y: ((map['y'] ?? 0.0) as num).toDouble(),
      width: ((map['width'] ?? 200.0) as num).toDouble(),
      height: ((map['height'] ?? 160.0) as num).toDouble(),
      data: parsedData,
      synced: (map['synced'] ?? 1) as int,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  factory BoardElement.fromCloudRow(Map<String, dynamic> m) {
    Map<String, dynamic> parsedData = {};
    if (m['data'] != null) {
      if (m['data'] is Map) {
        parsedData = Map<String, dynamic>.from(m['data'] as Map);
      } else if (m['data'] is String) {
        try {
          parsedData =
              Map<String, dynamic>.from(jsonDecode(m['data'] as String) as Map);
        } catch (_) {
          parsedData = {};
        }
      }
    }

    return BoardElement(
      cloudId: m['id'] as int?,
      boardId: (m['board_id'] ?? 1) as int,
      userId: m['user_id']?.toString() ?? '',
      type: (m['type'] ?? 'note') as String,
      title: (m['title'] ?? '') as String,
      content: (m['content'] ?? '') as String,
      color: (m['color'] ?? '#9D00FF') as String,
      x: ((m['x'] ?? 0.0) as num).toDouble(),
      y: ((m['y'] ?? 0.0) as num).toDouble(),
      width: ((m['width'] ?? 200.0) as num).toDouble(),
      height: ((m['height'] ?? 160.0) as num).toDouble(),
      data: parsedData,
      synced: 1,
      createdAt: m['created_at']?.toString(),
      updatedAt: m['updated_at']?.toString(),
    );
  }

  BoardElement copyWith({
    int? id,
    int? cloudId,
    int? boardId,
    String? userId,
    String? type,
    String? title,
    String? content,
    String? color,
    double? x,
    double? y,
    double? width,
    double? height,
    Map<String, dynamic>? data,
    int? synced,
    String? createdAt,
    String? updatedAt,
    bool clearCloudId = false,
  }) {
    return BoardElement(
      id: id ?? this.id,
      cloudId: clearCloudId ? null : (cloudId ?? this.cloudId),
      boardId: boardId ?? this.boardId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      data: data ?? this.data,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
