import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_bubble.dart';
import '../models/comic_panel.dart';
import '../models/comic_sticker.dart';
import '../painters/comic_panel_shape_helper.dart';
import 'comic_selection_handles.dart';

/// Resuelve cajas de transformación geométrica y detección de toques
/// para elementos del lienzo de cómic.
class ComicTransformResolver {
  const ComicTransformResolver._();

  static ComicElementTransform? resolve(ComicController c, Size pageSize) {
    if (c.selectedBubble != null) {
      final b = c.selectedBubble!;
      return ComicElementTransform(
        center: Offset(b.x * pageSize.width, b.y * pageSize.height),
        halfW: b.width / 2,
        halfH: b.height / 2,
        rotation: b.rotation,
      );
    }
    if (c.selectedSfx != null) {
      final s = c.selectedSfx!;
      return ComicElementTransform(
        center: Offset(s.x * pageSize.width, s.y * pageSize.height),
        halfW: math.max(32.0, s.text.length * s.fontSize * 0.32 * s.scale),
        halfH: math.max(22.0, s.fontSize * 0.65 * s.scale),
        rotation: s.rotation,
      );
    }
    if (c.selectedPanel != null) {
      final p = c.selectedPanel!;
      final r = p.normalizedRect;
      return ComicElementTransform(
        center: Offset(
          (r.left + r.width / 2) * pageSize.width,
          (r.top + r.height / 2) * pageSize.height,
        ),
        halfW: (r.width * pageSize.width) / 2,
        halfH: (r.height * pageSize.height) / 2,
        rotation: p.rotation,
      );
    }
    return null;
  }

  static ComicSticker? findTappedSfx(ComicController c, Offset pos, Size pageSize) {
    for (final sfx in c.activePage.sfxStickers.reversed) {
      final center = Offset(sfx.x * pageSize.width, sfx.y * pageSize.height);
      final halfW = math.max(36.0, sfx.text.length * sfx.fontSize * 0.40 * sfx.scale);
      final halfH = math.max(28.0, sfx.fontSize * 0.85 * sfx.scale);
      final diff = pos - center;
      final cosAngle = math.cos(-sfx.rotation);
      final sinAngle = math.sin(-sfx.rotation);
      final localX = diff.dx * cosAngle - diff.dy * sinAngle;
      final localY = diff.dx * sinAngle + diff.dy * cosAngle;
      if (localX.abs() <= halfW + 16 && localY.abs() <= halfH + 16) {
        return sfx;
      }
    }
    return null;
  }

  static ComicBubble? findTappedBubble(ComicController c, Offset pos, Size pageSize) {
    if (c.selectedBubble != null) {
      final b = c.selectedBubble!;
      final center = Offset(b.x * pageSize.width, b.y * pageSize.height);
      final halfW = b.width / 2;
      final halfH = b.height / 2;
      final diff = pos - center;
      final cosAngle = math.cos(-b.rotation);
      final sinAngle = math.sin(-b.rotation);
      final localX = diff.dx * cosAngle - diff.dy * sinAngle;
      final localY = diff.dx * sinAngle + diff.dy * cosAngle;
      if (localX.abs() <= halfW + 36.0 &&
          (localY.abs() <= halfH + 36.0 ||
              (localY >= -halfH - 52.0 && localY <= halfH + 36.0 && localX.abs() <= 32.0))) {
        return b;
      }
    }

    for (final b in c.activePage.bubbles.reversed) {
      final center = Offset(b.x * pageSize.width, b.y * pageSize.height);
      final halfW = b.width / 2;
      final halfH = b.height / 2;
      final diff = pos - center;
      final cosAngle = math.cos(-b.rotation);
      final sinAngle = math.sin(-b.rotation);
      final localX = diff.dx * cosAngle - diff.dy * sinAngle;
      final localY = diff.dx * sinAngle + diff.dy * cosAngle;
      final allowance = b.tailDirection != ComicTailDirection.none ? 44.0 : 32.0;
      if (localX.abs() <= halfW + allowance && localY.abs() <= halfH + allowance) {
        return b;
      }
    }
    return null;
  }

  static ComicPanel? findTappedPanel(ComicController c, Offset pos, Size pageSize) {
    for (final p in c.activePage.panels.reversed) {
      final rect = Rect.fromLTWH(
        p.normalizedRect.left * pageSize.width,
        p.normalizedRect.top * pageSize.height,
        p.normalizedRect.width * pageSize.width,
        p.normalizedRect.height * pageSize.height,
      );
      if (ComicPanelShapeHelper.getPanelPath(rect, p).contains(pos)) {
        return p;
      }
    }
    return null;
  }
}
