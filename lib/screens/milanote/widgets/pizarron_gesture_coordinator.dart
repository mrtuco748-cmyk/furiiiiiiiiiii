import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../models/board_element.dart';
import '../../../providers/board_data_provider.dart';
import '../models/active_text_target.dart';
import 'pizarron_camera_math.dart';

/// Coordinador de gestos multitáctiles para el lienzo infinito del Pizarrón:
/// - 1 dedo: paneo de cámara, arrastre 1:1 de notas, redimensionado por esquina, dibujo de tiza.
/// - 2 dedos: zoom/paneo de lienzo o escalado simétrico de notas.
/// - Detección de tap para seleccionar nota o editar bloque específico (título vs cuerpo).
class PizarronGestureCoordinator {
  final Map<int, Offset> activePointers = {};
  int? singlePointerId;
  Offset? pointerDownScreenPos;
  bool hasExceededTapSlop = false;
  int? touchedNoteId;
  Offset? noteStartWorldPos;
  bool isDraggingNote = false;
  bool isResizingCorner = false;

  bool isTwoFingerGesture = false;
  int? pinchingNoteId;
  double initialPinchDistance = 1.0;
  Offset initialPinchMidScreen = Offset.zero;
  Offset initialCameraPanOnPinch = Offset.zero;
  double initialCameraScaleOnPinch = 1.0;
  Rect? initialNoteRectOnPinch;

  void handlePointerDown({
    required PointerDownEvent event,
    required List<BoardElement> visibleElements,
    required Offset cameraPan,
    required double cameraScale,
    required bool chalkMode,
    required int? editingElementId,
    required BoardDataProvider provider,
    required VoidCallback onStopCameraAnim,
    required void Function(Offset worldPt) onAddLiveChalkPoint,
  }) {
    onStopCameraAnim();
    activePointers[event.pointer] = event.localPosition;

    if (activePointers.length == 1) {
      singlePointerId = event.pointer;
      pointerDownScreenPos = event.localPosition;
      hasExceededTapSlop = false;
      isTwoFingerGesture = false;
      isDraggingNote = false;
      isResizingCorner = false;

      final worldPt = PizarronCameraMath.screenToWorld(
        event.localPosition,
        cameraPan,
        cameraScale,
      );
      final hitEl = PizarronCameraMath.hitTestNoteAtWorld(worldPt, visibleElements);

      if (hitEl != null && hitEl.id != null) {
        touchedNoteId = hitEl.id;
        noteStartWorldPos = Offset(hitEl.x, hitEl.y);
        if (PizarronCameraMath.isPointOnResizeHandle(worldPt, hitEl, cameraScale)) {
          isResizingCorner = true;
        }
      } else {
        touchedNoteId = null;
        noteStartWorldPos = null;
        if (chalkMode && editingElementId == null) {
          onAddLiveChalkPoint(worldPt);
        }
      }
    } else if (activePointers.length == 2) {
      if (touchedNoteId != null && noteStartWorldPos != null && isDraggingNote) {
        provider.updatePositionLocal(
          touchedNoteId!,
          noteStartWorldPos!.dx,
          noteStartWorldPos!.dy,
        );
      }
      isDraggingNote = false;
      isResizingCorner = false;
      isTwoFingerGesture = true;

      final pts = activePointers.values.toList();
      initialPinchDistance = math.max(10.0, (pts[0] - pts[1]).distance);
      initialPinchMidScreen = (pts[0] + pts[1]) * 0.5;
      initialCameraPanOnPinch = cameraPan;
      initialCameraScaleOnPinch = cameraScale;

      final p1World = PizarronCameraMath.screenToWorld(pts[0], cameraPan, cameraScale);
      final p2World = PizarronCameraMath.screenToWorld(pts[1], cameraPan, cameraScale);
      final h1 = PizarronCameraMath.hitTestNoteAtWorld(p1World, visibleElements);
      final h2 = PizarronCameraMath.hitTestNoteAtWorld(p2World, visibleElements);

      if (h1 != null && h2 != null && h1.id != null && h1.id == h2.id) {
        pinchingNoteId = h1.id;
        initialNoteRectOnPinch = Rect.fromLTWH(h1.x, h1.y, h1.width, h1.height);
      } else {
        pinchingNoteId = null;
        initialNoteRectOnPinch = null;
      }
    }
  }

  void handlePointerMove({
    required PointerMoveEvent event,
    required Size screenSize,
    required Offset cameraPan,
    required double cameraScale,
    required double minScale,
    required double maxScale,
    required bool chalkMode,
    required int? editingElementId,
    required BoardDataProvider provider,
    required void Function(Offset newPan, double newScale) onCameraUpdated,
    required void Function(Offset delta) onCameraPanBy,
    required void Function(Offset worldPt) onAddLiveChalkPoint,
  }) {
    if (!activePointers.containsKey(event.pointer)) return;
    final prevScreenPos = activePointers[event.pointer]!;
    activePointers[event.pointer] = event.localPosition;
    final deltaScreen = event.localPosition - prevScreenPos;

    if (activePointers.length >= 2) {
      final pts = activePointers.values.toList();
      final scaleRatio =
          math.max(10.0, (pts[0] - pts[1]).distance) / initialPinchDistance;

      if (pinchingNoteId != null && initialNoteRectOnPinch != null) {
        final base = initialNoteRectOnPinch!;
        final newW = (base.width * scaleRatio).clamp(130.0, 950.0);
        final newH = (base.height * scaleRatio).clamp(110.0, 950.0);
        final center = base.center;
        provider.updateGeometryLocal(
          pinchingNoteId!,
          x: center.dx - newW / 2,
          y: center.dy - newH / 2,
          width: newW,
          height: newH,
        );
      } else {
        final currentMid = (pts[0] + pts[1]) * 0.5;
        final newScale =
            (initialCameraScaleOnPinch * scaleRatio).clamp(minScale, maxScale);
        final focalWorld =
            (initialPinchMidScreen - initialCameraPanOnPinch) / initialCameraScaleOnPinch;
        onCameraUpdated(currentMid - (focalWorld * newScale), newScale);
      }
      return;
    }

    if (isTwoFingerGesture || singlePointerId != event.pointer) return;

    if (!hasExceededTapSlop && pointerDownScreenPos != null) {
      if ((event.localPosition - pointerDownScreenPos!).distance > 6.0) {
        hasExceededTapSlop = true;
      }
    }

    if (isResizingCorner && touchedNoteId != null) {
      final idx = provider.elements.indexWhere((e) => e.id == touchedNoteId);
      if (idx != -1) {
        final el = provider.elements[idx];
        provider.updateGeometryLocal(
          el.id!,
          width: (el.width + deltaScreen.dx / cameraScale).clamp(130.0, 950.0),
          height: (el.height + deltaScreen.dy / cameraScale).clamp(110.0, 950.0),
        );
      }
      return;
    }

    if (touchedNoteId != null) {
      if (editingElementId == touchedNoteId || !hasExceededTapSlop) return;
      isDraggingNote = true;
      final idx = provider.elements.indexWhere((e) => e.id == touchedNoteId);
      if (idx != -1) {
        final el = provider.elements[idx];
        provider.updatePositionLocal(
          el.id!,
          el.x + deltaScreen.dx / cameraScale,
          el.y + deltaScreen.dy / cameraScale,
        );
      }
      return;
    }

    if (chalkMode && editingElementId == null) {
      final pt = PizarronCameraMath.screenToWorld(
        event.localPosition,
        cameraPan,
        cameraScale,
      );
      onAddLiveChalkPoint(pt);
      return;
    }

    if (hasExceededTapSlop) {
      onCameraPanBy(deltaScreen);
    }
  }

  void handlePointerUpOrCancel({
    required PointerEvent event,
    required Size screenSize,
    required Offset cameraPan,
    required double cameraScale,
    required int? editingElementId,
    required BoardDataProvider provider,
    required VoidCallback onChalkStrokeCompleted,
    required void Function(BoardElement el, ActiveTextTarget target) onEditNote,
    required void Function(ActiveTextTarget target) onActiveTargetChanged,
    required VoidCallback onCloseEditMode,
    required VoidCallback onCloseMenus,
  }) {
    activePointers.remove(event.pointer);

    if (activePointers.isEmpty) {
      onChalkStrokeCompleted();
    }

    if (!isTwoFingerGesture && !hasExceededTapSlop && event is PointerUpEvent) {
      if (touchedNoteId != null) {
        final idx = provider.elements.indexWhere((e) => e.id == touchedNoteId);
        if (idx != -1) {
          final tappedEl = provider.elements[idx];
          final worldPt = PizarronCameraMath.screenToWorld(
            event.localPosition,
            cameraPan,
            cameraScale,
          );
          final localY = worldPt.dy - tappedEl.y;
          final target = localY <= 65.0
              ? const ActiveTextTarget.title()
              : const ActiveTextTarget.bodyDefault();

          if (editingElementId != tappedEl.id) {
            onEditNote(tappedEl, target);
          } else {
            onActiveTargetChanged(target);
          }
        }
      } else {
        if (editingElementId != null) {
          onCloseEditMode();
        } else {
          onCloseMenus();
        }
      }
    }

    if (activePointers.isEmpty) {
      singlePointerId = null;
      touchedNoteId = null;
      noteStartWorldPos = null;
      isDraggingNote = false;
      isResizingCorner = false;
      isTwoFingerGesture = false;
      pinchingNoteId = null;
      initialNoteRectOnPinch = null;
    }
  }
}
