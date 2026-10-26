import 'package:flutter/material.dart';

/// Herramientas profesionales de dibujo digital y manga.
enum DrawingToolType {
  pen,
  gPen,
  pencil,
  marker,
  airbrush,
  highlighter,
  lasso,
  line,
  rectangle,
  circle,
  trajectory,
  bucketFill,
  gradient,
  eraser,
  smudge;

  String get displayName {
    switch (this) {
      case DrawingToolType.pen:
        return 'Birome';
      case DrawingToolType.gPen:
        return 'Pluma G';
      case DrawingToolType.pencil:
        return 'Lápiz';
      case DrawingToolType.marker:
        return 'Marcador';
      case DrawingToolType.airbrush:
        return 'Aerógrafo';
      case DrawingToolType.highlighter:
        return 'Resaltador';
      case DrawingToolType.lasso:
        return 'Lazo';
      case DrawingToolType.line:
        return 'Línea';
      case DrawingToolType.rectangle:
        return 'Rectángulo';
      case DrawingToolType.circle:
        return 'Círculo';
      case DrawingToolType.trajectory:
        return 'Trayectoria';
      case DrawingToolType.bucketFill:
        return 'Rellenar';
      case DrawingToolType.gradient:
        return 'Degradado';
      case DrawingToolType.eraser:
        return 'Borrador';
      case DrawingToolType.smudge:
        return 'Difuminar';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawingToolType.pen:
        return Icons.edit;
      case DrawingToolType.gPen:
        return Icons.gesture;
      case DrawingToolType.pencil:
        return Icons.border_color;
      case DrawingToolType.marker:
        return Icons.brush;
      case DrawingToolType.airbrush:
        return Icons.blur_on;
      case DrawingToolType.highlighter:
        return Icons.format_paint;
      case DrawingToolType.lasso:
        return Icons.gesture;
      case DrawingToolType.line:
        return Icons.horizontal_rule;
      case DrawingToolType.rectangle:
        return Icons.crop_square;
      case DrawingToolType.circle:
        return Icons.radio_button_unchecked;
      case DrawingToolType.trajectory:
        return Icons.timeline;
      case DrawingToolType.bucketFill:
        return Icons.format_paint;
      case DrawingToolType.gradient:
        return Icons.gradient;
      case DrawingToolType.eraser:
        return Icons.cleaning_services;
      case DrawingToolType.smudge:
        return Icons.blur_linear;
    }
  }

  String get svgAsset {
    switch (this) {
      case DrawingToolType.pen:
      case DrawingToolType.gPen:
        return 'pen_gpen';
      case DrawingToolType.pencil:
        return 'pencil_sketch';
      case DrawingToolType.marker:
        return 'brush_marker';
      case DrawingToolType.airbrush:
      case DrawingToolType.smudge:
        return 'airbrush';
      case DrawingToolType.highlighter:
        return 'highlighter';
      case DrawingToolType.lasso:
        return 'shapes';
      case DrawingToolType.line:
      case DrawingToolType.rectangle:
      case DrawingToolType.circle:
      case DrawingToolType.trajectory:
      case DrawingToolType.gradient:
        return 'shapes';
      case DrawingToolType.bucketFill:
      case DrawingToolType.eraser:
        return 'eraser';
    }
  }

  double get defaultWidth {
    switch (this) {
      case DrawingToolType.pen:
        return 3.0;
      case DrawingToolType.gPen:
        return 4.0;
      case DrawingToolType.pencil:
        return 2.5;
      case DrawingToolType.marker:
        return 10.0;
      case DrawingToolType.airbrush:
        return 28.0;
      case DrawingToolType.highlighter:
        return 24.0;
      case DrawingToolType.lasso:
        return 2.0;
      case DrawingToolType.line:
      case DrawingToolType.rectangle:
      case DrawingToolType.circle:
      case DrawingToolType.trajectory:
        return 3.5;
      case DrawingToolType.bucketFill:
      case DrawingToolType.gradient:
        return 1.0;
      case DrawingToolType.eraser:
        return 24.0;
      case DrawingToolType.smudge:
        return 22.0;
    }
  }

  double get defaultOpacity {
    switch (this) {
      case DrawingToolType.pencil:
        return 0.85;
      case DrawingToolType.highlighter:
        return 0.35;
      case DrawingToolType.airbrush:
      case DrawingToolType.smudge:
        return 0.30;
      default:
        return 1.0;
    }
  }

  bool get isEraser => this == DrawingToolType.eraser;
  bool get isSmudge => this == DrawingToolType.smudge;
  bool get isLasso => this == DrawingToolType.lasso;
  bool get isFill => this == DrawingToolType.bucketFill || this == DrawingToolType.gradient;
  bool get isShape =>
      this == DrawingToolType.line ||
      this == DrawingToolType.rectangle ||
      this == DrawingToolType.circle ||
      this == DrawingToolType.trajectory;
  bool get requiresDragVector => isShape || this == DrawingToolType.gradient;
  bool get showsBrushCursor =>
      this == DrawingToolType.pen ||
      this == DrawingToolType.gPen ||
      this == DrawingToolType.pencil ||
      this == DrawingToolType.marker ||
      this == DrawingToolType.airbrush ||
      this == DrawingToolType.highlighter ||
      this == DrawingToolType.eraser ||
      this == DrawingToolType.smudge;
}
