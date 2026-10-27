import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../models/drawing_tool_type.dart';
import 'drawing_viewport_math.dart';

/// Coordinador de interacción gestual táctil para el lienzo de dibujo:
/// - Máquina de estados desacoplada para gestos con 1 dedo (trazos) y 2+ dedos (zoom y paneo).
/// - Transformaciones incrementales continuas evitando saltos o teletransportes.
/// - Prevención de inundación accidental del balde al iniciar zoom.
class DrawingViewportGestureCoordinator {
  final DrawingController controller;
  final TransformationController transformController;
  final GlobalKey canvasKey;
  final BuildContext? Function()? getContext;
  final void Function(Offset? cursor, double pressure, bool visible) onCursorUpdate;

  final Map<int, Offset> _activePointers = {};
  bool _isMultiTouchSession = false;
  Offset? _lastFocalPoint;
  double? _lastSpan;
  int? _activeDrawingPointerId;
  bool _isDraggingSelection = false;
  Offset? _lastSelectionPoint;
  Offset? _pendingTapPoint;

  DrawingViewportGestureCoordinator({
    required this.controller,
    required this.transformController,
    required this.canvasKey,
    required this.getContext,
    required this.onCursorUpdate,
  });

  bool get hasActivePointers => _activePointers.isNotEmpty;

  Offset toCanvasCoordinates(Offset globalPosition, Size canvasSize) {
    return DrawingViewportMath.toCanvasCoordinates(
      globalPosition: globalPosition,
      canvasKey: canvasKey,
      context: getContext?.call(),
      transformController: transformController,
      canvasSize: canvasSize,
      isFlippedHorizontal: controller.isFlippedHorizontal,
      isFlippedVertical: controller.isFlippedVertical,
    );
  }

  void handlePointerDown(PointerDownEvent event, Size canvasSize) {
    _activePointers[event.pointer] = event.position;

    if (_isMultiTouchSession) {
      _lastFocalPoint = DrawingViewportMath.calculateFocalPoint(_activePointers.values);
      _lastSpan = _activePointers.length >= 2
          ? DrawingViewportMath.calculateSpan(_activePointers.values)
          : null;
      return;
    }

    if (_activePointers.length >= 2) {
      _isMultiTouchSession = true;
      _pendingTapPoint = null;
      _activeDrawingPointerId = null;
      _isDraggingSelection = false;
      _lastSelectionPoint = null;

      if (controller.activeStroke != null) {
        controller.cancelActiveStroke();
      }
      onCursorUpdate(null, 1.0, false);

      _lastFocalPoint = DrawingViewportMath.calculateFocalPoint(_activePointers.values);
      _lastSpan = DrawingViewportMath.calculateSpan(_activePointers.values);
      return;
    }

    _activeDrawingPointerId = event.pointer;
    final canvasPoint = toCanvasCoordinates(event.position, canvasSize);
    final pressure = event.pressure > 0 ? event.pressure : 1.0;
    onCursorUpdate(canvasPoint, pressure, true);

    if (controller.hasSelection && controller.activeSelection!.containsPoint(canvasPoint)) {
      _isDraggingSelection = true;
      _lastSelectionPoint = canvasPoint;
      return;
    }
    if (controller.hasSelection) {
      controller.clearSelection();
    }

    if (controller.selectedTool == DrawingToolType.bucketFill) {
      _pendingTapPoint = canvasPoint;
      return;
    }

    controller.startStroke(canvasPoint, pressure);
  }

  void handlePointerMove(PointerMoveEvent event, Size canvasSize) {
    _activePointers[event.pointer] = event.position;

    if (_isMultiTouchSession) {
      if (_activePointers.length >= 2) {
        final currentFocalPoint = DrawingViewportMath.calculateFocalPoint(_activePointers.values);
        final currentSpan = DrawingViewportMath.calculateSpan(_activePointers.values);

        double scaleFactor = 1.0;
        if (_lastSpan != null && _lastSpan! > 8.0 && currentSpan > 8.0) {
          scaleFactor = (currentSpan / _lastSpan!).clamp(0.6, 1.6);
        }

        if (_lastFocalPoint != null) {
          final newMatrix = DrawingViewportMath.applyIncrementalTransform(
            currentMatrix: transformController.value,
            prevFocalPoint: _lastFocalPoint!,
            currentFocalPoint: currentFocalPoint,
            scaleFactor: scaleFactor,
          );
          transformController.value = newMatrix;
        }

        _lastFocalPoint = currentFocalPoint;
        _lastSpan = currentSpan;
      } else if (_activePointers.length == 1) {
        final currentFocalPoint = _activePointers.values.first;
        if (_lastFocalPoint != null) {
          final newMatrix = DrawingViewportMath.applyIncrementalTransform(
            currentMatrix: transformController.value,
            prevFocalPoint: _lastFocalPoint!,
            currentFocalPoint: currentFocalPoint,
            scaleFactor: 1.0,
          );
          transformController.value = newMatrix;
        }
        _lastFocalPoint = currentFocalPoint;
        _lastSpan = null;
      }
      return;
    }

    if (event.pointer == _activeDrawingPointerId) {
      final canvasPoint = toCanvasCoordinates(event.position, canvasSize);
      final pressure = event.pressure > 0 ? event.pressure : 1.0;
      onCursorUpdate(canvasPoint, pressure, true);

      if (_isDraggingSelection && _lastSelectionPoint != null) {
        final delta = canvasPoint - _lastSelectionPoint!;
        _lastSelectionPoint = canvasPoint;
        controller.moveSelection(delta);
        return;
      }

      if (_pendingTapPoint != null) {
        if ((canvasPoint - _pendingTapPoint!).distance > 12.0) {
          _pendingTapPoint = null;
        }
        return;
      }

      controller.updateStroke(canvasPoint, pressure);
    }
  }

  void handlePointerUpOrCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);

    if (_activePointers.isEmpty) {
      onCursorUpdate(null, 1.0, false);

      if (_isMultiTouchSession) {
        _isMultiTouchSession = false;
        _lastFocalPoint = null;
        _lastSpan = null;
        _pendingTapPoint = null;
        _activeDrawingPointerId = null;
        return;
      }

      if (_isDraggingSelection) {
        _isDraggingSelection = false;
        _lastSelectionPoint = null;
      } else if (_pendingTapPoint != null) {
        controller.startStroke(_pendingTapPoint!, 1.0);
        _pendingTapPoint = null;
      } else {
        controller.endStroke();
      }

      _activeDrawingPointerId = null;
    } else {
      if (_isMultiTouchSession) {
        _lastFocalPoint = DrawingViewportMath.calculateFocalPoint(_activePointers.values);
        _lastSpan = _activePointers.length >= 2
            ? DrawingViewportMath.calculateSpan(_activePointers.values)
            : null;
      }
    }
  }

  void handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final double dy = event.scrollDelta.dy;
      if (dy == 0) return;
      final double factor = dy < 0 ? 1.12 : 0.89;
      transformController.value = DrawingViewportMath.applyZoomAtPoint(
        currentMatrix: transformController.value,
        focalPoint: event.position,
        scaleFactor: factor,
      );
    }
  }
}
