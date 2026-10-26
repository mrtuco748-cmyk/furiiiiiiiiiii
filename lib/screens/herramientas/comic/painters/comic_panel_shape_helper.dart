import 'package:flutter/material.dart';
import '../models/comic_panel.dart';

/// Helper de generación y cálculo vectorial para formas dinámicas de viñetas de cómic.
abstract final class ComicPanelShapeHelper {
  static Path getPanelPath(Rect rect, ComicPanel panel) {
    Path p = Path();

    // Si la viñeta tiene vértices poligonales personalizados (ej. corte diagonal)
    if (panel.polygonPoints != null && panel.polygonPoints!.length >= 3) {
      final pts = panel.polygonPoints!;
      p.moveTo(rect.left + pts[0].dx * rect.width, rect.top + pts[0].dy * rect.height);
      for (int i = 1; i < pts.length; i++) {
        p.lineTo(rect.left + pts[i].dx * rect.width, rect.top + pts[i].dy * rect.height);
      }
      p.close();

      if (panel.rotation != 0.0) {
        final matrix = Matrix4.identity()
          ..translateByDouble(rect.center.dx, rect.center.dy, 0.0, 1.0)
          ..rotateZ(panel.rotation)
          ..translateByDouble(-rect.center.dx, -rect.center.dy, 0.0, 1.0);
        p = p.transform(matrix.storage);
      }

      return p;
    }

    final skew = panel.skewX * rect.width;
    final r = panel.borderRadius > 0 ? panel.borderRadius : 14.0;

    switch (panel.panelShape) {
      case ComicPanelShape.rectangle:
        if (panel.borderRadius > 0) {
          p.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(panel.borderRadius)));
        } else {
          p.addRect(rect);
        }
        break;

      case ComicPanelShape.roundedRect:
        p.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
        break;

      case ComicPanelShape.slantedRight:
        final drop = rect.height * 0.18;
        p.moveTo(rect.left + skew, rect.top);
        p.lineTo(rect.right + skew, rect.top + drop);
        p.lineTo(rect.right, rect.bottom);
        p.lineTo(rect.left, rect.bottom - drop);
        p.close();
        break;

      case ComicPanelShape.slantedLeft:
        final drop = rect.height * 0.18;
        p.moveTo(rect.left + skew, rect.top + drop);
        p.lineTo(rect.right + skew, rect.top);
        p.lineTo(rect.right, rect.bottom - drop);
        p.lineTo(rect.left, rect.bottom);
        p.close();
        break;

      case ComicPanelShape.trapezoidTop:
        final inset = rect.width * 0.15;
        p.moveTo(rect.left + inset + skew, rect.top);
        p.lineTo(rect.right - inset + skew, rect.top);
        p.lineTo(rect.right, rect.bottom);
        p.lineTo(rect.left, rect.bottom);
        p.close();
        break;

      case ComicPanelShape.trapezoidBottom:
        final inset = rect.width * 0.15;
        p.moveTo(rect.left + skew, rect.top);
        p.lineTo(rect.right + skew, rect.top);
        p.lineTo(rect.right - inset, rect.bottom);
        p.lineTo(rect.left + inset, rect.bottom);
        p.close();
        break;

      case ComicPanelShape.diamond:
        p.moveTo(rect.center.dx + skew, rect.top);
        p.lineTo(rect.right + skew, rect.center.dy);
        p.lineTo(rect.center.dx, rect.bottom);
        p.lineTo(rect.left, rect.center.dy);
        p.close();
        break;

      case ComicPanelShape.parallelogram:
        final pSkew = rect.width * 0.18;
        p.moveTo(rect.left + pSkew + skew, rect.top);
        p.lineTo(rect.right + skew, rect.top);
        p.lineTo(rect.right - pSkew, rect.bottom);
        p.lineTo(rect.left, rect.bottom);
        p.close();
        break;
    }

    if (panel.rotation != 0.0) {
      final matrix = Matrix4.identity()
        ..translateByDouble(rect.center.dx, rect.center.dy, 0.0, 1.0)
        ..rotateZ(panel.rotation)
        ..translateByDouble(-rect.center.dx, -rect.center.dy, 0.0, 1.0);
      p = p.transform(matrix.storage);
    }

    return p;
  }
}
