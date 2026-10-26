import 'dart:math' as math;
import 'dart:ui';
import 'drawing_point.dart';
import 'drawing_tool_type.dart';

/// Representa un trazo individual dibujado en una capa.
/// Almacena los puntos, la herramienta utilizada, color, ancho,
/// opacidad y genera un [Path] interpolado con curvas suaves o formas geométricas.
class DrawingStroke {
  final String id;
  final DrawingToolType tool;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final List<DrawingPoint> points;

  Path? _cachedPath;

  DrawingStroke({
    required this.id,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    required this.points,
    Path? initialPath,
  }) : _cachedPath = initialPath;

  /// Retorna o calcula el [Path] suavizado o la forma geométrica correspondiente.
  Path get path {
    if (_cachedPath != null) return _cachedPath!;
    _cachedPath = _buildPath();
    return _cachedPath!;
  }

  Path _buildPath() {
    final p = Path();
    if (points.isEmpty) return p;

    final first = points.first.offset;
    final last = points.last.offset;

    // Manejo de formas geométricas (Línea, Rectángulo, Círculo, Trayectoria)
    if (tool == DrawingToolType.line) {
      p.moveTo(first.dx, first.dy);
      p.lineTo(last.dx, last.dy);
      return p;
    }

    if (tool == DrawingToolType.rectangle) {
      p.addRect(Rect.fromPoints(first, last));
      return p;
    }

    if (tool == DrawingToolType.circle) {
      p.addOval(Rect.fromPoints(first, last));
      return p;
    }

    if (tool == DrawingToolType.trajectory) {
      p.moveTo(first.dx, first.dy);
      p.lineTo(last.dx, last.dy);
      final dx = last.dx - first.dx;
      final dy = last.dy - first.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len > 5) {
        final angle = math.atan2(dy, dx);
        final arrowLen = (strokeWidth * 3.5).clamp(12.0, 36.0);
        const arrowAngle = 0.45;
        p.moveTo(last.dx, last.dy);
        p.lineTo(last.dx - arrowLen * math.cos(angle - arrowAngle),
            last.dy - arrowLen * math.sin(angle - arrowAngle));
        p.moveTo(last.dx, last.dy);
        p.lineTo(last.dx - arrowLen * math.cos(angle + arrowAngle),
            last.dy - arrowLen * math.sin(angle + arrowAngle));
      }
      return p;
    }

    // Trazo a mano alzada
    if (points.length == 1) {
      p.addOval(Rect.fromCircle(center: first, radius: strokeWidth / 4));
      return p;
    }

    p.moveTo(first.dx, first.dy);

    if (points.length == 2) {
      p.lineTo(last.dx, last.dy);
      return p;
    }

    // Suavizado continuo por puntos medios (Bézier cuadrática)
    for (int i = 1; i < points.length - 1; i++) {
      final current = points[i].offset;
      final next = points[i + 1].offset;
      final midPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      p.quadraticBezierTo(current.dx, current.dy, midPoint.dx, midPoint.dy);
    }

    p.lineTo(last.dx, last.dy);
    return p;
  }

  DrawingStroke copyWith({
    String? id,
    DrawingToolType? tool,
    Color? color,
    double? strokeWidth,
    double? opacity,
    List<DrawingPoint>? points,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      points: points ?? List<DrawingPoint>.from(this.points),
    );
  }
}
