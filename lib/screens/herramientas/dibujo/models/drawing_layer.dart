import 'drawing_stroke.dart';

/// Representa una capa de dibujo independiente dentro del lienzo multicapa.
class DrawingLayer {
  final String id;
  final String name;
  final bool isVisible;
  final bool isLocked;
  final double opacity;
  final List<DrawingStroke> strokes;

  DrawingLayer({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    required this.strokes,
  });

  DrawingLayer copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    List<DrawingStroke>? strokes,
  }) {
    return DrawingLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      strokes: strokes ?? List<DrawingStroke>.from(this.strokes),
    );
  }
}
