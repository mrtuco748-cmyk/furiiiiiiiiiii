import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Funciones matemáticas y de transformación para el viewport del lienzo de dibujo.
abstract final class DrawingViewportMath {
  static void fitToScreen({
    required Size viewportSize,
    required Size canvasSize,
    required TransformationController transformController,
  }) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;
    final double paddingW = viewportSize.width * 0.90;
    final double paddingH = viewportSize.height * 0.76;
    final double scaleW = paddingW / canvasSize.width;
    final double scaleH = paddingH / canvasSize.height;
    final double scale = math.min(scaleW, scaleH).clamp(0.12, 3.0);

    final double tx = (viewportSize.width - canvasSize.width * scale) / 2;
    final double ty = (viewportSize.height - canvasSize.height * scale) / 2;

    transformController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  static Offset toCanvasCoordinates({
    required Offset globalPosition,
    required GlobalKey canvasKey,
    required BuildContext context,
    required TransformationController transformController,
    required Size canvasSize,
    required bool isFlippedHorizontal,
    required bool isFlippedVertical,
  }) {
    Offset rawPoint = globalPosition;
    final RenderBox? canvasBox = canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox != null) {
      rawPoint = canvasBox.globalToLocal(globalPosition);
    } else {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final localInViewport = box.globalToLocal(globalPosition);
        final Matrix4 inverted = Matrix4.inverted(transformController.value);
        rawPoint = MatrixUtils.transformPoint(inverted, localInViewport);
      }
    }

    double x = rawPoint.dx;
    double y = rawPoint.dy;
    if (isFlippedHorizontal) x = canvasSize.width - x;
    if (isFlippedVertical) y = canvasSize.height - y;
    return Offset(x, y);
  }

  static Offset calculateFocalPoint(Iterable<Offset> pointers) {
    if (pointers.isEmpty) return Offset.zero;
    double x = 0;
    double y = 0;
    for (final pos in pointers) {
      x += pos.dx;
      y += pos.dy;
    }
    return Offset(x / pointers.length, y / pointers.length);
  }

  static double calculateDistance(Iterable<Offset> pointers) {
    if (pointers.length < 2) return 0.0;
    final pts = pointers.toList();
    return (pts[0] - pts[1]).distance;
  }

  static Matrix4? calculateTwoFingerTransform({
    required Offset? initialFocalPoint,
    required double? initialDistance,
    required Matrix4? initialTransform,
    required Iterable<Offset> activePointers,
  }) {
    if (initialFocalPoint == null || initialTransform == null) return null;
    final currentFocalPoint = calculateFocalPoint(activePointers);
    final currentDistance = calculateDistance(activePointers);
    double s = 1.0;
    if (initialDistance != null && initialDistance > 10.0 && currentDistance > 10.0) {
      s = (currentDistance / initialDistance).clamp(0.2, 5.0);
    }
    final f0 = initialFocalPoint;
    final f1 = currentFocalPoint;
    return Matrix4.identity()
      ..translateByDouble(f1.dx - s * f0.dx, f1.dy - s * f0.dy, 0.0, 1.0)
      ..scaleByDouble(s, s, 1.0, 1.0)
      ..multiply(initialTransform);
  }
}
