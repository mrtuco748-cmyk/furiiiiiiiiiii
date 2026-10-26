import 'package:flutter/material.dart';

/// Formas geométricas y estilos dinámicos para viñetas de manga y cómic.
enum ComicPanelShape {
  rectangle,
  slantedRight,
  slantedLeft,
  trapezoidTop,
  trapezoidBottom,
  roundedRect,
  diamond,
  parallelogram;

  String get displayName {
    switch (this) {
      case ComicPanelShape.rectangle:
        return 'Rectangular Clásico';
      case ComicPanelShape.slantedRight:
        return 'Corte Shonen Diagonal';
      case ComicPanelShape.slantedLeft:
        return 'Corte Shonen Inverso';
      case ComicPanelShape.trapezoidTop:
        return 'Trapecio Perspectiva';
      case ComicPanelShape.trapezoidBottom:
        return 'Trapecio Inverso';
      case ComicPanelShape.roundedRect:
        return 'Webtoon Redondeado';
      case ComicPanelShape.diamond:
        return 'Rombo de Acción';
      case ComicPanelShape.parallelogram:
        return 'Paralelogramo Velocidad';
    }
  }

  IconData get icon {
    switch (this) {
      case ComicPanelShape.rectangle:
        return Icons.crop_square;
      case ComicPanelShape.slantedRight:
        return Icons.call_missed_outgoing;
      case ComicPanelShape.slantedLeft:
        return Icons.call_missed;
      case ComicPanelShape.trapezoidTop:
        return Icons.change_history;
      case ComicPanelShape.trapezoidBottom:
        return Icons.details;
      case ComicPanelShape.roundedRect:
        return Icons.crop_square_rounded;
      case ComicPanelShape.diamond:
        return Icons.diamond_outlined;
      case ComicPanelShape.parallelogram:
        return Icons.view_stream;
    }
  }
}

/// Representa una viñeta/panel individual en una hoja de cómic con geometría dinámica.
class ComicPanel {
  final String id;
  final Rect normalizedRect; // Coordenadas relativas (0.0 a 1.0) en la hoja
  final ComicPanelShape panelShape;
  final double rotation; // En radianes
  final double skewX; // Inclinación horizontal (-0.5 a 0.5)
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color backgroundColor;
  final String? drawingProjectId;
  final String? drawingPngBase64;
  final double scale;
  final double offsetX;
  final double offsetY;
  final List<Offset>? polygonPoints;

  ComicPanel({
    required this.id,
    required this.normalizedRect,
    this.panelShape = ComicPanelShape.rectangle,
    this.rotation = 0.0,
    this.skewX = 0.0,
    this.borderRadius = 0.0,
    this.borderWidth = 3.0,
    this.borderColor = const Color(0xFF111111),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.drawingProjectId,
    this.drawingPngBase64,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.polygonPoints,
  });

  ComicPanel copyWith({
    String? id,
    Rect? normalizedRect,
    ComicPanelShape? panelShape,
    double? rotation,
    double? skewX,
    double? borderRadius,
    double? borderWidth,
    Color? borderColor,
    Color? backgroundColor,
    String? drawingProjectId,
    String? drawingPngBase64,
    double? scale,
    double? offsetX,
    double? offsetY,
    List<Offset>? polygonPoints,
    bool clearDrawing = false,
    bool clearPolygonPoints = false,
  }) {
    return ComicPanel(
      id: id ?? this.id,
      normalizedRect: normalizedRect ?? this.normalizedRect,
      panelShape: panelShape ?? this.panelShape,
      rotation: rotation ?? this.rotation,
      skewX: skewX ?? this.skewX,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      drawingProjectId: clearDrawing ? null : (drawingProjectId ?? this.drawingProjectId),
      drawingPngBase64: clearDrawing ? null : (drawingPngBase64 ?? this.drawingPngBase64),
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      polygonPoints: clearPolygonPoints ? null : (polygonPoints ?? this.polygonPoints),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'left': normalizedRect.left,
    'top': normalizedRect.top,
    'width': normalizedRect.width,
    'height': normalizedRect.height,
    'panelShape': panelShape.name,
    'rotation': rotation,
    'skewX': skewX,
    'borderRadius': borderRadius,
    'borderWidth': borderWidth,
    'borderColor': borderColor.toARGB32(),
    'backgroundColor': backgroundColor.toARGB32(),
    'drawingProjectId': drawingProjectId,
    'drawingPngBase64': drawingPngBase64,
    'scale': scale,
    'offsetX': offsetX,
    'offsetY': offsetY,
    'polygonPoints': polygonPoints?.map((p) => [p.dx, p.dy]).toList(),
  };

  factory ComicPanel.fromMap(Map<String, dynamic> map) {
    final left = (map['left'] as num?)?.toDouble() ?? 0.0;
    final top = (map['top'] as num?)?.toDouble() ?? 0.0;
    final width = (map['width'] as num?)?.toDouble() ?? 1.0;
    final height = (map['height'] as num?)?.toDouble() ?? 1.0;

    return ComicPanel(
      id: map['id'] as String? ?? 'panel_${DateTime.now().microsecondsSinceEpoch}',
      normalizedRect: Rect.fromLTWH(left, top, width, height),
      panelShape: ComicPanelShape.values.firstWhere(
        (s) => s.name == (map['panelShape'] as String?),
        orElse: () => ComicPanelShape.rectangle,
      ),
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      skewX: (map['skewX'] as num?)?.toDouble() ?? 0.0,
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 0.0,
      borderWidth: (map['borderWidth'] as num?)?.toDouble() ?? 3.0,
      borderColor: Color(map['borderColor'] as int? ?? 0xFF111111),
      backgroundColor: Color(map['backgroundColor'] as int? ?? 0xFFFFFFFF),
      drawingProjectId: map['drawingProjectId'] as String?,
      drawingPngBase64: map['drawingPngBase64'] as String?,
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (map['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (map['offsetY'] as num?)?.toDouble() ?? 0.0,
      polygonPoints: (map['polygonPoints'] as List<dynamic>?)
          ?.map((pt) => Offset((pt[0] as num).toDouble(), (pt[1] as num).toDouble()))
          .toList(),
    );
  }
}
