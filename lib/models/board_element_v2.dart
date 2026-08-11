import '../app_state.dart';

/// Tipos de elementos del pizarrón v2.
class BoardElementType {
  static const String note = 'note';
  static const String checklist = 'checklist';
  static const String drawing = 'drawing';
  static const String video = 'video';
  static const String audio = 'audio';
  static const String connector = 'connector';
  static const String subBoard = 'sub_board';
  static const String separator = 'separator';
}

/// Estado visual de un elemento.
class BoardElementStatus {
  static const String draft = 'draft';
  static const String inProgress = 'in_progress';
  static const String finalized = 'finalized';
}

/// Prioridad de un elemento.
class BoardElementPriority {
  static const String normal = 'normal';
  static const String important = 'important';
  static const String urgent = 'urgent';
}

/// Elemento del pizarrón v2 — completo y serializable.
class BoardElementV2 {
  final int? id;
  final String type;
  final String title;
  final String content;
  final double x, y;
  final double? width; // null = auto-size
  final double? height; // null = auto-size
  final double rotation;
  final String? color; // hex background
  final String? textColor; // hex text color
  final String? fontFamily;
  final double? fontSize;
  final String textAlign; // left, center, right, justify
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final String? emojiHeader;
  final List<String> tags;
  final String priority; // normal, important, urgent
  final String? assignedTo; // 'facu' | 'rocio'
  final String? userId; // autor
  final String status; // draft, in_progress, finalized
  final bool isCollapsed;
  final bool isLocked;
  final bool isArchived;
  final int boardId;
  final int z;
  final Map<String, dynamic> data; // flexible: connectors, checklist items, etc.
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isNew; // badge NUEVO

  BoardElementV2({
    this.id,
    required this.type,
    this.title = '',
    this.content = '',
    this.x = 0,
    this.y = 0,
    this.width,
    this.height,
    this.rotation = 0,
    this.color,
    this.textColor,
    this.fontFamily,
    this.fontSize,
    this.textAlign = 'left',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.emojiHeader,
    this.tags = const [],
    this.priority = BoardElementPriority.normal,
    this.assignedTo,
    this.userId,
    this.status = BoardElementStatus.draft,
    this.isCollapsed = false,
    this.isLocked = false,
    this.isArchived = false,
    this.boardId = 1,
    this.z = 0,
    this.data = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isNew = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'title': title,
        'content': content,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'color': color,
        'text_color': textColor,
        'font_family': fontFamily,
        'font_size': fontSize,
        'text_align': textAlign,
        'is_bold': isBold,
        'is_italic': isItalic,
        'is_underline': isUnderline,
        'emoji_header': emojiHeader,
        'tags': tags,
        'priority': priority,
        'assigned_to': assignedTo,
        'user_id': userId ?? AppState.myId ?? '',
        'status': status,
        'is_collapsed': isCollapsed,
        'is_locked': isLocked,
        'is_archived': isArchived,
        'board_id': boardId,
        'z': z,
        'data': data,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_new': isNew,
      };

  factory BoardElementV2.fromMap(Map<String, dynamic> m) => BoardElementV2(
        id: m['id'] as int?,
        type: m['type'] as String? ?? 'note',
        title: m['title'] as String? ?? '',
        content: m['content'] as String? ?? '',
        x: (m['x'] as num?)?.toDouble() ?? 0,
        y: (m['y'] as num?)?.toDouble() ?? 0,
        width: (m['width'] as num?)?.toDouble(),
        height: (m['height'] as num?)?.toDouble(),
        rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
        color: m['color'] as String?,
        textColor: m['text_color'] as String?,
        fontFamily: m['font_family'] as String?,
        fontSize: (m['font_size'] as num?)?.toDouble(),
        textAlign: m['text_align'] as String? ?? 'left',
        isBold: m['is_bold'] == true,
        isItalic: m['is_italic'] == true,
        isUnderline: m['is_underline'] == true,
        emojiHeader: m['emoji_header'] as String?,
        tags: m['tags'] is List
            ? List<String>.from(m['tags'] as List)
            : <String>[],
        priority: m['priority'] as String? ?? BoardElementPriority.normal,
        assignedTo: m['assigned_to'] as String?,
        userId: m['user_id'] as String?,
        status: m['status'] as String? ?? BoardElementStatus.draft,
        isCollapsed: m['is_collapsed'] == true,
        isLocked: m['is_locked'] == true,
        isArchived: m['is_archived'] == true,
        boardId: (m['board_id'] as num?)?.toInt() ?? 1,
        z: (m['z'] as num?)?.toInt() ?? 0,
        data: m['data'] is Map
            ? Map<String, dynamic>.from(m['data'] as Map)
            : {},
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : DateTime.now(),
        updatedAt: m['updated_at'] != null
            ? DateTime.parse(m['updated_at'] as String)
            : DateTime.now(),
        isNew: m['is_new'] == true,
      );

  BoardElementV2 copyWith({
    int? id,
    bool clearId = false,
    String? type,
    String? title,
    String? content,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? color,
    String? textColor,
    String? fontFamily,
    double? fontSize,
    String? textAlign,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    String? emojiHeader,
    List<String>? tags,
    String? priority,
    String? assignedTo,
    String? userId,
    String? status,
    bool? isCollapsed,
    bool? isLocked,
    bool? isArchived,
    int? boardId,
    int? z,
    Map<String, dynamic>? data,
    DateTime? updatedAt,
    bool? isNew,
  }) =>
      BoardElementV2(
        id: clearId ? null : (id ?? this.id),
        type: type ?? this.type,
        title: title ?? this.title,
        content: content ?? this.content,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        rotation: rotation ?? this.rotation,
        color: color ?? this.color,
        textColor: textColor ?? this.textColor,
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
        textAlign: textAlign ?? this.textAlign,
        isBold: isBold ?? this.isBold,
        isItalic: isItalic ?? this.isItalic,
        isUnderline: isUnderline ?? this.isUnderline,
        emojiHeader: emojiHeader ?? this.emojiHeader,
        tags: tags ?? this.tags,
        priority: priority ?? this.priority,
        assignedTo: assignedTo ?? this.assignedTo,
        userId: userId ?? this.userId,
        status: status ?? this.status,
        isCollapsed: isCollapsed ?? this.isCollapsed,
        isLocked: isLocked ?? this.isLocked,
        isArchived: isArchived ?? this.isArchived,
        boardId: boardId ?? this.boardId,
        z: z ?? this.z,
        data: data ?? this.data,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isNew: isNew ?? this.isNew,
      );

  bool get isMine => userId == AppState.myId;

  String get authorInitial {
    final uid = userId ?? '';
    if (uid.toLowerCase().contains('facu')) return 'F';
    if (uid.toLowerCase().contains('rocio')) return 'R';
    return uid.substring(0, 1).toUpperCase();
  }

  /// Crea una nota básica en el centro del viewport.
  factory BoardElementV2.newNote({
    required double x,
    required double y,
    String? userId,
  }) =>
      BoardElementV2(
        type: BoardElementType.note,
        title: 'Nueva nota',
        content: '',
        x: x,
        y: y,
        userId: userId ?? AppState.myId,
        isNew: true,
      );
}

/// Punto 2D simple.
class Point2D {
  final double dx, dy;
  const Point2D(this.dx, this.dy);
}

/// Registro de actividad del pizarrón.
class BoardActivity {
  final String userId;
  final String action; // 'created', 'moved', 'edited', 'deleted'
  final int? elementId;
  final String elementType;
  final String description;
  final DateTime timestamp;

  const BoardActivity({
    required this.userId,
    required this.action,
    this.elementId,
    required this.elementType,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'action': action,
        'element_id': elementId,
        'element_type': elementType,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BoardActivity.fromMap(Map<String, dynamic> m) => BoardActivity(
        userId: m['user_id'] as String? ?? '',
        action: m['action'] as String? ?? '',
        elementId: m['element_id'] as int?,
        elementType: m['element_type'] as String? ?? '',
        description: m['description'] as String? ?? '',
        timestamp: m['timestamp'] != null
            ? DateTime.parse(m['timestamp'] as String)
            : DateTime.now(),
      );
}
