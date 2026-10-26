import 'package:flutter/material.dart';

/// Modos de simetría en tiempo real para dibujo profesional y entintado.
enum DrawingSymmetryMode {
  none,
  vertical,
  horizontal,
  radial4,
  kaleidoscope;

  String get displayName {
    switch (this) {
      case DrawingSymmetryMode.none:
        return 'Sin simetría';
      case DrawingSymmetryMode.vertical:
        return 'Vertical';
      case DrawingSymmetryMode.horizontal:
        return 'Horizontal';
      case DrawingSymmetryMode.radial4:
        return 'Radial';
      case DrawingSymmetryMode.kaleidoscope:
        return 'Caleidoscopio';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawingSymmetryMode.none:
        return Icons.close;
      case DrawingSymmetryMode.vertical:
        return Icons.vertical_split;
      case DrawingSymmetryMode.horizontal:
        return Icons.horizontal_split;
      case DrawingSymmetryMode.radial4:
        return Icons.auto_awesome;
      case DrawingSymmetryMode.kaleidoscope:
        return Icons.flare;
    }
  }

  /// Proyecta una lista de puntos según el modo de simetría activo
  /// relativo al centro del lienzo.
  List<List<Offset>> projectPoints(List<Offset> sourcePoints, Size canvasSize) {
    if (this == DrawingSymmetryMode.none || sourcePoints.isEmpty) {
      return const [];
    }
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;

    switch (this) {
      case DrawingSymmetryMode.vertical:
        return [
          sourcePoints.map((p) => Offset(2 * cx - p.dx, p.dy)).toList(),
        ];
      case DrawingSymmetryMode.horizontal:
        return [
          sourcePoints.map((p) => Offset(p.dx, 2 * cy - p.dy)).toList(),
        ];
      case DrawingSymmetryMode.radial4:
        return [
          sourcePoints.map((p) => Offset(2 * cx - p.dx, p.dy)).toList(),
          sourcePoints.map((p) => Offset(p.dx, 2 * cy - p.dy)).toList(),
          sourcePoints.map((p) => Offset(2 * cx - p.dx, 2 * cy - p.dy)).toList(),
        ];
      case DrawingSymmetryMode.kaleidoscope:
        return [
          sourcePoints.map((p) => Offset(2 * cx - p.dx, p.dy)).toList(),
          sourcePoints.map((p) => Offset(p.dx, 2 * cy - p.dy)).toList(),
          sourcePoints.map((p) => Offset(2 * cx - p.dx, 2 * cy - p.dy)).toList(),
          sourcePoints.map((p) => Offset(cx + (p.dy - cy), cy + (p.dx - cx))).toList(),
          sourcePoints.map((p) => Offset(cx - (p.dy - cy), cy + (p.dx - cx))).toList(),
          sourcePoints.map((p) => Offset(cx + (p.dy - cy), cy - (p.dx - cx))).toList(),
          sourcePoints.map((p) => Offset(cx - (p.dy - cy), cy - (p.dx - cx))).toList(),
        ];
      case DrawingSymmetryMode.none:
        return const [];
    }
  }
}
