import 'dart:ui';
import '../helpers/comic_polygon_cutter.dart';
import '../models/comic_page.dart';
import '../models/comic_panel.dart';

/// Operaciones estructurales avanzadas sobre viñetas:
/// - División matemática (split)
/// - Corte gestual por línea/cuchillo (slice diagonal, vertical y horizontal)
/// - Creación a medida desde rect trazado por el usuario
/// - Redimensionamiento independiente y estilización de bordes
abstract final class ComicPanelOperations {
  /// Divide una viñeta horizontal o verticalmente en dos paneles proporcionales.
  static (ComicPage, String)? splitPanel(ComicPage page, String panelId, {bool vertical = false}) {
    final target = page.panels.where((p) => p.id == panelId).firstOrNull;
    if (target == null) return null;

    final r = target.normalizedRect;
    final ts = DateTime.now().microsecondsSinceEpoch;
    ComicPanel p1, p2;

    if (vertical) {
      final h = (r.height - 0.02) / 2;
      p1 = target.copyWith(normalizedRect: Rect.fromLTWH(r.left, r.top, r.width, h));
      p2 = ComicPanel(id: 'panel_${ts}_split', normalizedRect: Rect.fromLTWH(r.left, r.top + h + 0.02, r.width, h));
    } else {
      final w = (r.width - 0.02) / 2;
      p1 = target.copyWith(normalizedRect: Rect.fromLTWH(r.left, r.top, w, r.height));
      p2 = ComicPanel(id: 'panel_${ts}_split', normalizedRect: Rect.fromLTWH(r.left + w + 0.02, r.top, w, r.height));
    }

    final updatedPanels = page.panels.map((p) => p.id == panelId ? p1 : p).toList()..add(p2);
    return (page.copyWith(panels: updatedPanels), p2.id);
  }

  /// Corta una viñeta a lo largo de un vector de corte trazado con el dedo (soporta cortes diagonales, verticales u horizontales).
  static (ComicPage, String)? slicePanelWithLine(
    ComicPage page,
    String panelId,
    Offset p1Norm,
    Offset p2Norm,
  ) {
    final target = page.panels.where((p) => p.id == panelId).firstOrNull;
    if (target == null) return null;

    final result = ComicPolygonCutter.slicePanel(target, p1Norm, p2Norm);
    if (result == null) return null;

    final part1 = result.$1;
    final part2 = result.$2;

    final updatedPanels = page.panels.map((p) => p.id == panelId ? part1 : p).toList()..add(part2);
    return (page.copyWith(panels: updatedPanels), part2.id);
  }

  /// Agrega una viñeta desde un rectángulo normalizado trazado directamente por el usuario.
  static (ComicPage, ComicPanel) addPanelFromRect(
    ComicPage page,
    Rect normalizedRect, {
    ComicPanelShape shape = ComicPanelShape.rectangle,
  }) {
    final left = normalizedRect.left.clamp(0.01, 0.90);
    final top = normalizedRect.top.clamp(0.01, 0.90);
    final width = normalizedRect.width.clamp(0.05, 1.0 - left);
    final height = normalizedRect.height.clamp(0.05, 1.0 - top);

    final panel = ComicPanel(
      id: 'panel_${DateTime.now().microsecondsSinceEpoch}',
      normalizedRect: Rect.fromLTWH(left, top, width, height),
      panelShape: shape,
    );

    final updated = List<ComicPanel>.from(page.panels)..add(panel);
    return (page.copyWith(panels: updated), panel);
  }

  /// Modifica las dimensiones independientes de un panel (bordes o esquinas).
  static ComicPage updatePanelRect(ComicPage page, String panelId, Rect newRect) {
    final left = newRect.left.clamp(0.0, 0.95);
    final top = newRect.top.clamp(0.0, 0.95);
    final width = newRect.width.clamp(0.04, 1.0 - left);
    final height = newRect.height.clamp(0.04, 1.0 - top);
    final clamped = Rect.fromLTWH(left, top, width, height);

    final updated = page.panels.map((p) => p.id == panelId ? p.copyWith(normalizedRect: clamped) : p).toList();
    return page.copyWith(panels: updated);
  }

  /// Personaliza el borde (grosor, color, esquinas) de una viñeta en 1 toque.
  static ComicPage updatePanelBorder(
    ComicPage page,
    String panelId, {
    double? borderWidth,
    Color? borderColor,
    double? borderRadius,
  }) {
    final updated = page.panels.map((p) {
      if (p.id != panelId) return p;
      return p.copyWith(
        borderWidth: borderWidth ?? p.borderWidth,
        borderColor: borderColor ?? p.borderColor,
        borderRadius: borderRadius ?? p.borderRadius,
      );
    }).toList();
    return page.copyWith(panels: updated);
  }

  /// Desplaza una viñeta dentro de los límites de la página.
  static ComicPage movePanel(ComicPage page, String panelId, double dxNorm, double dyNorm) {
    final updated = page.panels.map((p) {
      if (p.id != panelId) return p;
      final r = p.normalizedRect;
      final left = (r.left + dxNorm).clamp(0.0, 1.0 - r.width);
      final top = (r.top + dyNorm).clamp(0.0, 1.0 - r.height);
      return p.copyWith(normalizedRect: Rect.fromLTWH(left, top, r.width, r.height));
    }).toList();
    return page.copyWith(panels: updated);
  }

  /// Aplica transformaciones de escala y traslación interna al panel.
  static ComicPage setPanelTransform(ComicPage page, String panelId, {double? scale, double? dx, double? dy}) {
    final updated = page.panels.map((p) => p.id == panelId
        ? p.copyWith(scale: scale ?? p.scale, offsetX: dx ?? p.offsetX, offsetY: dy ?? p.offsetY)
        : p).toList();
    return page.copyWith(panels: updated);
  }
}
