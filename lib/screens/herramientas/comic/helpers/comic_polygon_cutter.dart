import 'dart:math' as math;
import 'dart:ui';
import '../models/comic_panel.dart';

/// Motor geométrico de corte poligonal para viñetas de cómic y manga.
/// Permite cortar cualquier viñeta (rectangular, trapezoidal o poligonal)
/// a lo largo de un vector dirigido en cualquier ángulo (vertical, horizontal o diagonal)
/// generando dos paneles complementarios separados por un canal de viñeta (gutter).
abstract final class ComicPolygonCutter {
  /// Obtiene los vértices de un panel en coordenadas absolutas de la página [0.0..1.0].
  static List<Offset> getPanelVerticesPage(ComicPanel panel) {
    final r = panel.normalizedRect;
    if (panel.polygonPoints != null && panel.polygonPoints!.length >= 3) {
      return panel.polygonPoints!
          .map((p) => Offset(r.left + p.dx * r.width, r.top + p.dy * r.height))
          .toList();
    }

    final localVertices = getShapeVerticesLocal(panel.panelShape, skewX: panel.skewX);
    return localVertices
        .map((p) => Offset(r.left + p.dx * r.width, r.top + p.dy * r.height))
        .toList();
  }

  /// Retorna los vértices normalizados en [0..1, 0..1] para cada forma predefinida.
  static List<Offset> getShapeVerticesLocal(ComicPanelShape shape, {double skewX = 0.0}) {
    switch (shape) {
      case ComicPanelShape.rectangle:
      case ComicPanelShape.roundedRect:
        return const [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)];

      case ComicPanelShape.slantedRight:
        const drop = 0.18;
        return [
          Offset(skewX, 0),
          Offset(1.0 + skewX, drop),
          const Offset(1.0, 1.0),
          Offset(0.0, 1.0 - drop),
        ];

      case ComicPanelShape.slantedLeft:
        const drop = 0.18;
        return [
          Offset(skewX, drop),
          Offset(1.0 + skewX, 0),
          Offset(1.0, 1.0 - drop),
          const Offset(0.0, 1.0),
        ];

      case ComicPanelShape.trapezoidTop:
        const inset = 0.15;
        return [
          Offset(inset + skewX, 0),
          Offset(1.0 - inset + skewX, 0),
          const Offset(1.0, 1.0),
          const Offset(0.0, 1.0),
        ];

      case ComicPanelShape.trapezoidBottom:
        const inset = 0.15;
        return [
          Offset(skewX, 0),
          Offset(1.0 + skewX, 0),
          const Offset(1.0 - inset, 1.0),
          const Offset(inset, 1.0),
        ];

      case ComicPanelShape.diamond:
        return [
          Offset(0.5 + skewX, 0),
          Offset(1.0 + skewX, 0.5),
          const Offset(0.5, 1.0),
          const Offset(0.0, 0.5),
        ];

      case ComicPanelShape.parallelogram:
        const pSkew = 0.18;
        return [
          Offset(pSkew + skewX, 0),
          Offset(1.0 + skewX, 0),
          const Offset(1.0 - pSkew, 1.0),
          const Offset(0.0, 1.0),
        ];
    }
  }

  /// Corta el panel a lo largo de la línea infinita que pasa por p1 y p2.
  static (ComicPanel, ComicPanel)? slicePanel(
    ComicPanel target,
    Offset p1,
    Offset p2, {
    double gutter = 0.012,
  }) {
    final vertices = getPanelVerticesPage(target);
    if (vertices.length < 3) return null;

    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-4) return null;

    final dir = Offset(dx / len, dy / len);
    final normal = Offset(-dir.dy, dir.dx);

    final r = target.normalizedRect;
    final minDim = math.min(r.width, r.height);
    final effectiveGutter = math.min(gutter, minDim * 0.20);

    // Intentar cortar con el gutter preferido
    var poly1 = _clipPolygonHalfPlane(vertices, p1, normal, effectiveGutter / 2);
    var poly2 = _clipPolygonHalfPlane(vertices, p1, -normal, effectiveGutter / 2);

    // Si con gutter preferido alguna parte quedó muy reducida, usar gutter mínimo
    if (poly1.length < 3 || poly2.length < 3 || _calculateArea(poly1) < 1e-4 || _calculateArea(poly2) < 1e-4) {
      final fallbackGutter = math.min(0.003, minDim * 0.05);
      poly1 = _clipPolygonHalfPlane(vertices, p1, normal, fallbackGutter / 2);
      poly2 = _clipPolygonHalfPlane(vertices, p1, -normal, fallbackGutter / 2);

      if (poly1.length < 3 || poly2.length < 3 || _calculateArea(poly1) < 1e-5 || _calculateArea(poly2) < 1e-5) {
        return null;
      }
    }

    return _buildPanels(target, poly1, poly2);
  }

  /// Algoritmo de Sutherland-Hodgman para recortar un polígono contra un semiplano:
  /// (Q - (lineOrigin + normal * offset)) · normal >= 0
  static List<Offset> _clipPolygonHalfPlane(
    List<Offset> poly,
    Offset lineOrigin,
    Offset normal,
    double offsetAlongNormal,
  ) {
    final result = <Offset>[];
    if (poly.isEmpty) return result;

    final origin = lineOrigin + normal * offsetAlongNormal;
    double dist(Offset q) => (q.dx - origin.dx) * normal.dx + (q.dy - origin.dy) * normal.dy;

    for (int i = 0; i < poly.length; i++) {
      final current = poly[i];
      final next = poly[(i + 1) % poly.length];

      final dCurrent = dist(current);
      final dNext = dist(next);

      final currentInside = dCurrent >= -1e-7;
      final nextInside = dNext >= -1e-7;

      if (currentInside && nextInside) {
        result.add(next);
      } else if (currentInside && !nextInside) {
        final denom = dCurrent - dNext;
        if (denom.abs() > 1e-9) {
          final t = (dCurrent / denom).clamp(0.0, 1.0);
          result.add(current + (next - current) * t);
        }
      } else if (!currentInside && nextInside) {
        final denom = dCurrent - dNext;
        if (denom.abs() > 1e-9) {
          final t = (dCurrent / denom).clamp(0.0, 1.0);
          result.add(current + (next - current) * t);
        }
        result.add(next);
      }
    }

    return _removeDuplicates(result);
  }

  static List<Offset> _removeDuplicates(List<Offset> pts) {
    if (pts.length <= 1) return pts;
    final cleaned = <Offset>[pts.first];
    for (int i = 1; i < pts.length; i++) {
      if ((pts[i] - cleaned.last).distance > 1e-5) {
        cleaned.add(pts[i]);
      }
    }
    if (cleaned.length > 2 && (cleaned.first - cleaned.last).distance <= 1e-5) {
      cleaned.removeLast();
    }
    return cleaned;
  }

  static (ComicPanel, ComicPanel) _buildPanels(
    ComicPanel target,
    List<Offset> poly1,
    List<Offset> poly2,
  ) {
    final bbox1 = _calculateBoundingBox(poly1);
    final bbox2 = _calculateBoundingBox(poly2);

    final normPts1 = poly1.map((p) => Offset(
      (p.dx - bbox1.left) / (bbox1.width > 0 ? bbox1.width : 1.0),
      (p.dy - bbox1.top) / (bbox1.height > 0 ? bbox1.height : 1.0),
    )).toList();

    final normPts2 = poly2.map((p) => Offset(
      (p.dx - bbox2.left) / (bbox2.width > 0 ? bbox2.width : 1.0),
      (p.dy - bbox2.top) / (bbox2.height > 0 ? bbox2.height : 1.0),
    )).toList();

    final ts = DateTime.now().microsecondsSinceEpoch;

    final part1 = target.copyWith(
      normalizedRect: bbox1,
      polygonPoints: normPts1,
    );

    final part2 = ComicPanel(
      id: 'panel_${ts}_cut',
      normalizedRect: bbox2,
      polygonPoints: normPts2,
      borderWidth: target.borderWidth,
      borderColor: target.borderColor,
      backgroundColor: target.backgroundColor,
      borderRadius: target.borderRadius,
    );

    return (part1, part2);
  }

  static double _calculateArea(List<Offset> poly) {
    if (poly.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < poly.length; i++) {
      final j = (i + 1) % poly.length;
      area += poly[i].dx * poly[j].dy - poly[j].dx * poly[i].dy;
    }
    return (area / 2.0).abs();
  }

  static Rect _calculateBoundingBox(List<Offset> poly) {
    double minX = poly.first.dx, maxX = poly.first.dx;
    double minY = poly.first.dy, maxY = poly.first.dy;
    for (final p in poly) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
