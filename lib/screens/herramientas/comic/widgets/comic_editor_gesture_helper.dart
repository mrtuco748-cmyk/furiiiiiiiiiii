import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../helpers/comic_smart_guides_engine.dart';
import '../models/comic_alignment_guide.dart';
import '../models/comic_bubble.dart';
import '../models/comic_panel.dart';
import 'comic_selection_handles.dart';

enum ComicDragMode {
  none,
  rotate,
  scale,
  move,
  resizeTop,
  resizeBottom,
  resizeLeft,
  resizeRight,
  frameContent,
}

/// Helper desacoplado para aplicar transformaciones de gestos (rotar, escalar, mover bordes y encuadrar).
abstract final class ComicEditorGestureHelper {
  static void applyCornerScale({
    required ComicController controller,
    required ComicElementTransform transform,
    required Offset pos,
    required double initialDist,
    required double initialScale,
    required double initialW,
    required double initialH,
    required Size pageSize,
  }) {
    final factor = ((pos - transform.center).distance / initialDist).clamp(0.25, 4.0);
    if (controller.selectedBubble != null) {
      controller.updateBubble(controller.selectedBubble!.copyWith(
        width: (initialW * factor).clamp(60.0, 600.0),
        height: (initialH * factor).clamp(40.0, 500.0),
      ));
    } else if (controller.selectedSfx != null) {
      controller.updateSfx(controller.selectedSfx!.copyWith(scale: (initialScale * factor).clamp(0.35, 4.0)));
    } else if (controller.selectedPanel != null) {
      final newW = ((initialW * factor) / pageSize.width).clamp(0.05, 0.95);
      final newH = ((initialH * factor) / pageSize.height).clamp(0.05, 0.95);
      final newLeft = (transform.center.dx / pageSize.width - newW / 2).clamp(0.0, 1.0 - newW);
      final newTop = (transform.center.dy / pageSize.height - newH / 2).clamp(0.0, 1.0 - newH);
      controller.updatePanelRect(controller.selectedPanel!.id, Rect.fromLTWH(newLeft, newTop, newW, newH));
    }
  }

  static void applyEdgeResize({
    required ComicController controller,
    required ComicDragMode mode,
    required DragUpdateDetails details,
    required Size pageSize,
    required ComicPanel panel,
  }) {
    final r = panel.normalizedRect;
    final dx = details.delta.dx / pageSize.width;
    final dy = details.delta.dy / pageSize.height;
    final updatedRect = switch (mode) {
      ComicDragMode.resizeTop => Rect.fromLTWH(r.left, (r.top + dy).clamp(0.0, r.bottom - 0.05), r.width, r.bottom - (r.top + dy).clamp(0.0, r.bottom - 0.05)),
      ComicDragMode.resizeBottom => Rect.fromLTWH(r.left, r.top, r.width, (r.height + dy).clamp(0.05, 1.0 - r.top)),
      ComicDragMode.resizeLeft => Rect.fromLTWH((r.left + dx).clamp(0.0, r.right - 0.05), r.top, r.right - (r.left + dx).clamp(0.0, r.right - 0.05), r.height),
      ComicDragMode.resizeRight => Rect.fromLTWH(r.left, r.top, (r.width + dx).clamp(0.05, 1.0 - r.left), r.height),
      _ => r,
    };
    controller.updatePanelRect(panel.id, updatedRect);
  }

  static void applyBubbleEdgeResize({
    required ComicController controller,
    required ComicDragMode mode,
    required DragUpdateDetails details,
    required ComicBubble bubble,
  }) {
    final cosAngle = math.cos(-bubble.rotation);
    final sinAngle = math.sin(-bubble.rotation);
    final localDx = details.delta.dx * cosAngle - details.delta.dy * sinAngle;
    final localDy = details.delta.dx * sinAngle + details.delta.dy * cosAngle;

    if (mode == ComicDragMode.resizeLeft || mode == ComicDragMode.resizeRight) {
      final sign = mode == ComicDragMode.resizeRight ? 1.0 : -1.0;
      final newWidth = (bubble.width + localDx * sign * 2.0).clamp(60.0, 600.0);
      controller.updateBubble(bubble.copyWith(width: newWidth));
    } else if (mode == ComicDragMode.resizeTop || mode == ComicDragMode.resizeBottom) {
      final sign = mode == ComicDragMode.resizeBottom ? 1.0 : -1.0;
      final newHeight = (bubble.height + localDy * sign * 2.0).clamp(40.0, 500.0);
      controller.updateBubble(bubble.copyWith(height: newHeight));
    }
  }

  static List<ComicAlignmentGuide> applyMoveWithSnap({
    required ComicController controller,
    required DragUpdateDetails details,
    required Size pageSize,
  }) {
    if (controller.selectedBubble != null) {
      final b = controller.selectedBubble!;
      final nextCenter = Offset(
        (b.x * pageSize.width) + details.delta.dx,
        (b.y * pageSize.height) + details.delta.dy,
      );
      final candRect = Rect.fromCenter(center: nextCenter, width: b.width, height: b.height);
      final snap = ComicSmartGuidesEngine.snap(
        pageSize: pageSize,
        candidateRect: candRect,
        controller: controller,
        currentElementId: b.id,
      );
      final snappedX = (snap.snappedCenter.dx / pageSize.width).clamp(0.02, 0.98);
      final snappedY = (snap.snappedCenter.dy / pageSize.height).clamp(0.02, 0.98);
      controller.moveBubble(b.id, snappedX, snappedY);
      return snap.guides;
    } else if (controller.selectedSfx != null) {
      final s = controller.selectedSfx!;
      final nextCenter = Offset(
        (s.x * pageSize.width) + details.delta.dx,
        (s.y * pageSize.height) + details.delta.dy,
      );
      final candRect = Rect.fromCenter(center: nextCenter, width: 60.0 * s.scale, height: 40.0 * s.scale);
      final snap = ComicSmartGuidesEngine.snap(
        pageSize: pageSize,
        candidateRect: candRect,
        controller: controller,
        currentElementId: s.id,
      );
      final snappedX = (snap.snappedCenter.dx / pageSize.width).clamp(0.02, 0.98);
      final snappedY = (snap.snappedCenter.dy / pageSize.height).clamp(0.02, 0.98);
      controller.moveSfx(s.id, snappedX, snappedY);
      return snap.guides;
    } else if (controller.selectedPanel != null) {
      final p = controller.selectedPanel!;
      final r = p.normalizedRect;
      final currentRect = Rect.fromLTWH(
        r.left * pageSize.width,
        r.top * pageSize.height,
        r.width * pageSize.width,
        r.height * pageSize.height,
      );
      final nextRect = currentRect.shift(details.delta);
      final snap = ComicSmartGuidesEngine.snap(
        pageSize: pageSize,
        candidateRect: nextRect,
        controller: controller,
        currentElementId: p.id,
      );
      final delta = snap.snappedCenter - currentRect.center;
      final dx = delta.dx / pageSize.width;
      final dy = delta.dy / pageSize.height;
      controller.movePanel(p.id, dx, dy);
      return snap.guides;
    }
    return const [];
  }

  static void applyMove({
    required ComicController controller,
    required Offset pos,
    required DragUpdateDetails details,
    required Size pageSize,
  }) {
    applyMoveWithSnap(controller: controller, details: details, pageSize: pageSize);
  }

  static void applyFramePan({
    required ComicController controller,
    required DragUpdateDetails details,
  }) {
    final p = controller.selectedPanel;
    if (p == null) return;
    controller.setPanelTransform(
      p.id,
      dx: p.offsetX + details.delta.dx,
      dy: p.offsetY + details.delta.dy,
    );
  }

  static void finishDrawPanel({
    required ComicController controller,
    required Offset? start,
    required Offset? current,
    required Size pageSize,
  }) {
    if (start == null || current == null) return;
    final r = Rect.fromPoints(start, current);
    if (r.width >= 24 && r.height >= 24) {
      controller.addPanelFromRect(Rect.fromLTWH(
        (r.left / pageSize.width).clamp(0.02, 0.90),
        (r.top / pageSize.height).clamp(0.02, 0.90),
        (r.width / pageSize.width).clamp(0.05, 0.95),
        (r.height / pageSize.height).clamp(0.05, 0.95),
      ));
    }
  }

  static void finishSlicePanel({
    required ComicController controller,
    required Offset? start,
    required Offset? current,
    required Size pageSize,
  }) {
    if (start == null || current == null || controller.selectedPanelId == null) return;
    controller.slicePanelWithLine(
      controller.selectedPanelId!,
      Offset(start.dx / pageSize.width, start.dy / pageSize.height),
      Offset(current.dx / pageSize.width, current.dy / pageSize.height),
    );
  }
}
