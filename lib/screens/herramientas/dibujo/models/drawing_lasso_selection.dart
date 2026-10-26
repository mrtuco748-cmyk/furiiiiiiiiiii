import 'dart:ui';

/// Representa una selección activa realizada con la herramienta de Lazo.
class DrawingLassoSelection {
  final List<Offset> polygonPoints;
  final List<String> selectedStrokeIds;
  final Rect bounds;
  final bool isTransforming;

  const DrawingLassoSelection({
    required this.polygonPoints,
    required this.selectedStrokeIds,
    required this.bounds,
    this.isTransforming = false,
  });

  bool containsPoint(Offset point) {
    if (!bounds.inflate(12.0).contains(point)) return false;
    if (polygonPoints.length < 3) return bounds.contains(point);

    // Algoritmo Ray-casting para punto en polígono
    int intersectCount = 0;
    for (int i = 0; i < polygonPoints.length; i++) {
      final p1 = polygonPoints[i];
      final p2 = polygonPoints[(i + 1) % polygonPoints.length];
      if ((p1.dy > point.dy) != (p2.dy > point.dy)) {
        final atX = (p2.dx - p1.dx) * (point.dy - p1.dy) / (p2.dy - p1.dy) + p1.dx;
        if (point.dx < atX) intersectCount++;
      }
    }
    return (intersectCount % 2) != 0;
  }

  DrawingLassoSelection copyWith({
    List<Offset>? polygonPoints,
    List<String>? selectedStrokeIds,
    Rect? bounds,
    bool? isTransforming,
  }) {
    return DrawingLassoSelection(
      polygonPoints: polygonPoints ?? this.polygonPoints,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      bounds: bounds ?? this.bounds,
      isTransforming: isTransforming ?? this.isTransforming,
    );
  }
}
