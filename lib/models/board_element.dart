import '../app_state.dart';

/// Tipos de elementos soportados por el pizarron estilo Milanote.
/// - `note` / `postit`: notas de texto con color de fondo.
/// - `arrow`: flecha simple (legacy).
/// - `image`: imagen subida a Supabase Storage (`content` = URL).
/// - `link`: card de enlace con preview (`content` = URL, `data` = metadatos).
/// - `connector`: linea/flecha que une dos elementos (`data.fromId` / `data.toId`).
class BoardElement {
  final int? id;
  final String type;
  final String content;
  final double x, y, width, height, rotation;
  final String? color;
  final String? userId;
  final int z;
  final int boardId;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  BoardElement({
    this.id,
    required this.type,
    this.content = '',
    this.x = 20,
    this.y = 20,
    this.width = 100,
    this.height = 80,
    this.rotation = 0,
    this.color,
    this.userId,
    this.z = 0,
    this.boardId = 1,
    this.data = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'content': content,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'color': color,
        'z': z,
        'data': data,
        'board_id': boardId,
        'user_id': AppState.myId ?? '',
        'created_at': createdAt.toIso8601String(),
      };

  factory BoardElement.fromMap(Map<String, dynamic> m) => BoardElement(
        id: m['id'] as int?,
        type: m['type'] as String? ?? 'note',
        content: m['content'] as String? ?? '',
        x: (m['x'] as num?)?.toDouble() ?? 20,
        y: (m['y'] as num?)?.toDouble() ?? 20,
        width: (m['width'] as num?)?.toDouble() ?? 100,
        height: (m['height'] as num?)?.toDouble() ?? 80,
        rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
        color: m['color'] as String?,
        z: (m['z'] as num?)?.toInt() ?? 0,
        data: m['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(m['data'] as Map)
            : {},
        boardId: (m['board_id'] as num?)?.toInt() ?? 1,
        userId: m['user_id'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : DateTime(0),
      );

  BoardElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? content,
    Map<String, dynamic>? data,
    int? z,
    int? boardId,
  }) =>
      BoardElement(
        id: id,
        type: type,
        content: content ?? this.content,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        rotation: rotation ?? this.rotation,
        color: color,
        userId: userId,
        z: z ?? this.z,
        boardId: boardId ?? this.boardId,
        data: data ?? this.data,
        createdAt: createdAt,
      );

  bool get isMine => userId == AppState.myId;

  bool get isDone => type == 'task' && data['done'] == true;

  Offset2D get center => Offset2D(x + width / 2, y + height / 2);
}

/// Punto 2D simple (evita importar Flutter en tests de lógica puras).
class Offset2D {
  final double dx, dy;
  const Offset2D(this.dx, this.dy);
}