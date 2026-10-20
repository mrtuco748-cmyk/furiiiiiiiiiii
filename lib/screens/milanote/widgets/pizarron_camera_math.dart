import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../models/board_element.dart';
import '../models/note_style_config.dart';
import '../painters/note_shape_utils.dart';

/// Funciones matemáticas puras de cámara y chunks para el Pizarrón.
class PizarronCameraMath {
  static Offset screenToWorld(Offset screenPt, Offset pan, double scale) {
    return (screenPt - pan) / scale;
  }

  static Matrix4 worldToScreenMatrix(Offset pan, double scale) {
    return Matrix4.identity()
      ..translateByDouble(pan.dx, pan.dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  static Rect computeActiveChunkWorldRect(
    Size screenSize,
    Offset pan,
    double scale,
  ) {
    final worldVisibleWidth = screenSize.width / scale;
    final worldVisibleHeight = screenSize.height / scale;
    final worldTopLeft = screenToWorld(Offset.zero, pan, scale);
    final visibleWorldRect = Rect.fromLTWH(
      worldTopLeft.dx,
      worldTopLeft.dy,
      worldVisibleWidth,
      worldVisibleHeight,
    );
    return visibleWorldRect.inflate(
      math.max(worldVisibleWidth * 0.5, 200.0),
    );
  }

  static BoardElement? hitTestNoteAtWorld(
    Offset worldPt,
    List<BoardElement> elements,
  ) {
    for (int i = elements.length - 1; i >= 0; i--) {
      final el = elements[i];
      final rect = Rect.fromLTWH(el.x, el.y, el.width, el.height);
      if (!rect.inflate(8.0).contains(worldPt)) continue;

      final cfg = NoteStyleConfig.fromElement(
        fallbackColor: el.color,
        data: el.data,
      );
      final localPt = worldPt - Offset(el.x, el.y);
      final path = NoteShapeUtils.buildShapePath(
        cfg.shapeType,
        Size(el.width, el.height),
      );
      if (path.contains(localPt) || rect.contains(worldPt)) {
        return el;
      }
    }
    return null;
  }

  static bool isPointOnResizeHandle(
    Offset worldPt,
    BoardElement el,
    double scale,
  ) {
    final cfg = NoteStyleConfig.fromElement(
      fallbackColor: el.color,
      data: el.data,
    );
    final handleLocal = NoteShapeUtils.getResizeHandleCenter(
      cfg.shapeType,
      Size(el.width, el.height),
    );
    final handleWorld = Offset(el.x, el.y) + handleLocal;
    final hitRadius = 22.0 / scale.clamp(0.4, 2.5);
    return (worldPt - handleWorld).distance <= hitRadius;
  }
}
