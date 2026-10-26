import 'dart:convert';
import 'dart:ui';
import '../models/drawing_layer.dart';
import '../models/drawing_point.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_tool_type.dart';

/// Representa un proyecto o lienzo de dibujo guardado con todas sus capas editables.
class DrawingProject {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double canvasWidth;
  final double canvasHeight;
  final List<DrawingLayer> layers;
  final String? thumbnailBase64;

  DrawingProject({
    required this.id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.canvasWidth = 2000.0,
    this.canvasHeight = 2000.0,
    required this.layers,
    this.thumbnailBase64,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DrawingProject copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? canvasWidth,
    double? canvasHeight,
    List<DrawingLayer>? layers,
    String? thumbnailBase64,
  }) {
    return DrawingProject(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      layers: layers ?? this.layers,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'thumbnailBase64': thumbnailBase64,
      'layers': layers.map((l) => {
        'id': l.id,
        'name': l.name,
        'isVisible': l.isVisible,
        'isLocked': l.isLocked,
        'opacity': l.opacity,
        'strokes': l.strokes.map((s) => {
          'id': s.id,
          'tool': s.tool.name,
          'color': s.color.toARGB32(),
          'strokeWidth': s.strokeWidth,
          'opacity': s.opacity,
          'points': s.points.map((p) => {
            'dx': p.offset.dx,
            'dy': p.offset.dy,
            'pressure': p.pressure,
          }).toList(),
        }).toList(),
      }).toList(),
    };
  }

  factory DrawingProject.fromMap(Map<String, dynamic> map) {
    final layersData = (map['layers'] as List<dynamic>?) ?? [];
    final layers = layersData.map((l) {
      final strokesData = (l['strokes'] as List<dynamic>?) ?? [];
      final strokes = strokesData.map((s) {
        final toolName = s['tool'] as String? ?? 'pen';
        final tool = DrawingToolType.values.firstWhere(
          (t) => t.name == toolName,
          orElse: () => DrawingToolType.pen,
        );
        final colorValue = s['color'] as int? ?? 0xFF000000;
        final pointsData = (s['points'] as List<dynamic>?) ?? [];
        final points = pointsData.map((p) {
          return DrawingPoint(
            offset: Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()),
            pressure: (p['pressure'] as num?)?.toDouble() ?? 1.0,
          );
        }).toList();

        return DrawingStroke(
          id: s['id'] as String? ?? 'stroke_${DateTime.now().microsecondsSinceEpoch}',
          tool: tool,
          color: Color(colorValue),
          strokeWidth: (s['strokeWidth'] as num?)?.toDouble() ?? 3.0,
          opacity: (s['opacity'] as num?)?.toDouble() ?? 1.0,
          points: points,
        );
      }).toList();

      return DrawingLayer(
        id: l['id'] as String? ?? 'layer_${DateTime.now().microsecondsSinceEpoch}',
        name: l['name'] as String? ?? 'Capa',
        isVisible: l['isVisible'] as bool? ?? true,
        isLocked: l['isLocked'] as bool? ?? false,
        opacity: (l['opacity'] as num?)?.toDouble() ?? 1.0,
        strokes: strokes,
      );
    }).toList();

    return DrawingProject(
      id: map['id'] as String? ?? 'proj_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? 'Sin Título',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      canvasWidth: (map['canvasWidth'] as num?)?.toDouble() ?? 2000.0,
      canvasHeight: (map['canvasHeight'] as num?)?.toDouble() ?? 2000.0,
      layers: layers,
      thumbnailBase64: map['thumbnailBase64'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DrawingProject.fromJson(String source) => DrawingProject.fromMap(jsonDecode(source));
}
