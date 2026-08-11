/// Modelos de datos específicos por tipo de elemento.
/// Cada modelo serializa/deserializa al campo `data` de BoardElementV2.

// ==================== CHECKLIST ====================

class ChecklistItem {
  final String id;
  String text;
  String state; // 'pending', 'in_progress', 'done'
  String? assignedTo;

  ChecklistItem({
    required this.id,
    required this.text,
    this.state = 'pending',
    this.assignedTo,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'state': state,
        if (assignedTo != null) 'assignedTo': assignedTo,
      };

  factory ChecklistItem.fromMap(Map<String, dynamic> m) => ChecklistItem(
        id: m['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        text: m['text'] as String? ?? '',
        state: m['state'] as String? ?? 'pending',
        assignedTo: m['assignedTo'] as String?,
      );

  ChecklistItem copyWith({
    String? text,
    String? state,
    String? assignedTo,
  }) =>
      ChecklistItem(
        id: id,
        text: text ?? this.text,
        state: state ?? this.state,
        assignedTo: assignedTo ?? this.assignedTo,
      );
}

class ChecklistData {
  final List<ChecklistItem> items;

  ChecklistData({this.items = const []});

  Map<String, dynamic> toMap() => {
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory ChecklistData.fromMap(Map<String, dynamic> m) {
    final raw = m['items'];
    if (raw is List) {
      return ChecklistData(
        items: raw
            .map((i) => ChecklistItem.fromMap(Map<String, dynamic>.from(i as Map)))
            .toList(),
      );
    }
    return ChecklistData();
  }

  ChecklistData copyWith({List<ChecklistItem>? items}) =>
      ChecklistData(items: items ?? this.items);
}

// ==================== CONNECTOR ====================

class ConnectorData {
  final int? fromId;
  final int? toId;
  final List<Map<String, double>> curvePoints; // control points for bezier
  final String? label;
  final String style; // 'straight', 'bezier', 'dashed'
  final String color;
  final double strokeWidth;

  ConnectorData({
    this.fromId,
    this.toId,
    this.curvePoints = const [],
    this.label,
    this.style = 'bezier',
    this.color = '#39FF14',
    this.strokeWidth = 3.0,
  });

  Map<String, dynamic> toMap() => {
        if (fromId != null) 'fromId': fromId,
        if (toId != null) 'toId': toId,
        'curvePoints': curvePoints,
        if (label != null) 'label': label,
        'style': style,
        'color': color,
        'strokeWidth': strokeWidth,
      };

  factory ConnectorData.fromMap(Map<String, dynamic> m) => ConnectorData(
        fromId: m['fromId'] as int?,
        toId: m['toId'] as int?,
        curvePoints: m['curvePoints'] is List
            ? List<Map<String, double>>.from(
                (m['curvePoints'] as List).map(
                  (p) => Map<String, double>.from(p as Map),
                ),
              )
            : [],
        label: m['label'] as String?,
        style: m['style'] as String? ?? 'bezier',
        color: m['color'] as String? ?? '#39FF14',
        strokeWidth: (m['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      );

  ConnectorData copyWith({
    int? fromId,
    int? toId,
    List<Map<String, double>>? curvePoints,
    String? label,
    String? style,
    String? color,
    double? strokeWidth,
  }) =>
      ConnectorData(
        fromId: fromId ?? this.fromId,
        toId: toId ?? this.toId,
        curvePoints: curvePoints ?? this.curvePoints,
        label: label ?? this.label,
        style: style ?? this.style,
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
      );
}

// ==================== VIDEO ====================

class VideoData {
  final String url;
  final String? thumbnailUrl;
  final String? title;
  final String provider; // 'youtube', 'tiktok', 'other'

  VideoData({
    this.url = '',
    this.thumbnailUrl,
    this.title,
    this.provider = 'other',
  });

  Map<String, dynamic> toMap() => {
        'url': url,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (title != null) 'title': title,
        'provider': provider,
      };

  factory VideoData.fromMap(Map<String, dynamic> m) => VideoData(
        url: m['url'] as String? ?? '',
        thumbnailUrl: m['thumbnailUrl'] as String?,
        title: m['title'] as String?,
        provider: m['provider'] as String? ?? 'other',
      );

  VideoData copyWith({
    String? url,
    String? thumbnailUrl,
    String? title,
    String? provider,
  }) =>
      VideoData(
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        title: title ?? this.title,
        provider: provider ?? this.provider,
      );

  /// Extracts video ID from YouTube URL.
  String? get youtubeId {
    if (provider != 'youtube') return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    }
    return null;
  }
}

// ==================== AUDIO ====================

class AudioData {
  final String? storagePath; // path in Supabase Storage
  final double duration; // in seconds
  final List<double> waveform; // array of amplitude values
  final String? localPath; // local file path for playback

  AudioData({
    this.storagePath,
    this.duration = 0,
    this.waveform = const [],
    this.localPath,
  });

  Map<String, dynamic> toMap() => {
        if (storagePath != null) 'storagePath': storagePath,
        'duration': duration,
        'waveform': waveform,
        if (localPath != null) 'localPath': localPath,
      };

  factory AudioData.fromMap(Map<String, dynamic> m) => AudioData(
        storagePath: m['storagePath'] as String?,
        duration: (m['duration'] as num?)?.toDouble() ?? 0,
        waveform: m['waveform'] is List
            ? List<double>.from(
                (m['waveform'] as List).map((v) => (v as num).toDouble()),
              )
            : [],
        localPath: m['localPath'] as String?,
      );

  AudioData copyWith({
    String? storagePath,
    double? duration,
    List<double>? waveform,
    String? localPath,
  }) =>
      AudioData(
        storagePath: storagePath ?? this.storagePath,
        duration: duration ?? this.duration,
        waveform: waveform ?? this.waveform,
        localPath: localPath ?? this.localPath,
      );
}

// ==================== DRAWING ====================

class DrawingData {
  final String? imagePath; // path to rendered image in Storage
  final List<DrawingStroke> strokes; // raw stroke data (for editing)
  final double width;
  final double height;

  DrawingData({
    this.imagePath,
    this.strokes = const [],
    this.width = 300,
    this.height = 200,
  });

  Map<String, dynamic> toMap() => {
        if (imagePath != null) 'imagePath': imagePath,
        'strokes': strokes.map((s) => s.toMap()).toList(),
        'width': width,
        'height': height,
      };

  factory DrawingData.fromMap(Map<String, dynamic> m) => DrawingData(
        imagePath: m['imagePath'] as String?,
        strokes: m['strokes'] is List
            ? List<DrawingStroke>.from(
                (m['strokes'] as List).map(
                  (s) => DrawingStroke.fromMap(Map<String, dynamic>.from(s as Map)),
                ),
              )
            : [],
        width: (m['width'] as num?)?.toDouble() ?? 300,
        height: (m['height'] as num?)?.toDouble() ?? 200,
      );

  DrawingData copyWith({
    String? imagePath,
    List<DrawingStroke>? strokes,
    double? width,
    double? height,
  }) =>
      DrawingData(
        imagePath: imagePath ?? this.imagePath,
        strokes: strokes ?? this.strokes,
        width: width ?? this.width,
        height: height ?? this.height,
      );
}

class DrawingStroke {
  final List<Map<String, double>> points; // [{x, y}]
  final String color;
  final double width;
  final String type; // 'brush', 'eraser', 'line', 'rectangle', 'circle'

  DrawingStroke({
    this.points = const [],
    this.color = '#FFFFFF',
    this.width = 3.0,
    this.type = 'brush',
  });

  Map<String, dynamic> toMap() => {
        'points': points,
        'color': color,
        'width': width,
        'type': type,
      };

  factory DrawingStroke.fromMap(Map<String, dynamic> m) => DrawingStroke(
        points: m['points'] is List
            ? List<Map<String, double>>.from(
                (m['points'] as List).map(
                  (p) => Map<String, double>.from(p as Map),
                ),
              )
            : [],
        color: m['color'] as String? ?? '#FFFFFF',
        width: (m['width'] as num?)?.toDouble() ?? 3.0,
        type: m['type'] as String? ?? 'brush',
      );

  DrawingStroke copyWith({
    List<Map<String, double>>? points,
    String? color,
    double? width,
    String? type,
  }) =>
      DrawingStroke(
        points: points ?? this.points,
        color: color ?? this.color,
        width: width ?? this.width,
        type: type ?? this.type,
      );
}

// ==================== SEPARATOR ====================

class SeparatorData {
  final String orientation; // 'horizontal', 'vertical'
  final String? label;
  final String color;

  SeparatorData({
    this.orientation = 'horizontal',
    this.label,
    this.color = '#333333',
  });

  Map<String, dynamic> toMap() => {
        'orientation': orientation,
        if (label != null) 'label': label,
        'color': color,
      };

  factory SeparatorData.fromMap(Map<String, dynamic> m) => SeparatorData(
        orientation: m['orientation'] as String? ?? 'horizontal',
        label: m['label'] as String?,
        color: m['color'] as String? ?? '#333333',
      );
}

// ==================== SUB-BOARD ====================

class SubBoardData {
  final int? boardId;
  final String? thumbnailPath;

  SubBoardData({
    this.boardId,
    this.thumbnailPath,
  });

  Map<String, dynamic> toMap() => {
        if (boardId != null) 'boardId': boardId,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
      };

  factory SubBoardData.fromMap(Map<String, dynamic> m) => SubBoardData(
        boardId: m['boardId'] as int?,
        thumbnailPath: m['thumbnailPath'] as String?,
      );
}

// ==================== HELPERS ====================

/// Parsea el campo `data` de un elemento al modelo específico.
T parseElementData<T>(Map<String, dynamic> data, T Function(Map<String, dynamic>) fromMap) {
  final typeData = data['typeData'];
  if (typeData is Map) {
    return fromMap(Map<String, dynamic>.from(typeData));
  }
  // Fallback: usar todo el data
  return fromMap(data);
}
