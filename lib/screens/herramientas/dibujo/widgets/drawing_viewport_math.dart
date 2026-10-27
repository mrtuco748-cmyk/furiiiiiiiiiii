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
    final double scale = math.min(scaleW, scaleH).clamp(0.02, 10.0);

    final double tx = (viewportSize.width - canvasSize.width * scale) / 2;
    final double ty = (viewportSize.height - canvasSize.height * scale) / 2;

    transformController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  static Offset toCanvasCoordinates({
    required Offset globalPosition,
    required GlobalKey canvasKey,
    BuildContext? context,
    required TransformationController transformController,
    required Size canvasSize,
    required bool isFlippedHorizontal,
    required bool isFlippedVertical,
  }) {
    Offset rawPoint = globalPosition;
    final RenderBox? canvasBox = canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox != null) {
      rawPoint = canvasBox.globalToLocal(globalPosition);
    } else if (context != null) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final localInViewport = box.globalToLocal(globalPosition);
        final Matrix4 inverted = Matrix4.inverted(transformController.value);
        rawPoint = MatrixUtils.transformPoint(inverted, localInViewport);
      } else {
        final Matrix4 inverted = Matrix4.inverted(transformController.value);
        rawPoint = MatrixUtils.transformPoint(inverted, globalPosition);
      }
    } else {
      final Matrix4 inverted = Matrix4.inverted(transformController.value);
      rawPoint = MatrixUtils.transformPoint(inverted, globalPosition);
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

  /// Calcula la separación promedio o span entre los punteros activos de forma
  /// continua e independiente del orden de los dedos.
  static double calculateSpan(Iterable<Offset> pointers) {
    if (pointers.length < 2) return 0.0;
    if (pointers.length == 2) {
      final pts = pointers.toList();
      return (pts[0] - pts[1]).distance;
    }
    final focal = calculateFocalPoint(pointers);
    double totalDist = 0.0;
    for (final p in pointers) {
      totalDist += (p - focal).distance;
    }
    return (totalDist / pointers.length) * 2.0;
  }

  /// Aplica una transformación incremental continua (pan + zoom) alrededor del
  /// punto focal sin descolocar el lienzo ni resetear la posición.
  static Matrix4 applyIncrementalTransform({
    required Matrix4 currentMatrix,
    required Offset prevFocalPoint,
    required Offset currentFocalPoint,
    double scaleFactor = 1.0,
    double minScale = 0.02,
    double maxScale = 30.0,
  }) {
    double s = scaleFactor;
    if (s <= 0.0 || s.isNaN || s.isInfinite) {
      s = 1.0;
    }

    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    if (currentScale > 0.0 && !currentScale.isNaN) {
      if (currentScale * s < minScale) {
        s = minScale / currentScale;
      } else if (currentScale * s > maxScale) {
        s = maxScale / currentScale;
      }
    }

    final double dx = currentFocalPoint.dx - s * prevFocalPoint.dx;
    final double dy = currentFocalPoint.dy - s * prevFocalPoint.dy;

    final delta = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..scaleByDouble(s, s, 1.0, 1.0);

    return delta..multiply(currentMatrix);
  }

  /// Zoom centrado en una coordenada específica de la pantalla (ej. rueda del ratón).
  static Matrix4 applyZoomAtPoint({
    required Matrix4 currentMatrix,
    required Offset focalPoint,
    required double scaleFactor,
    double minScale = 0.02,
    double maxScale = 30.0,
  }) {
    return applyIncrementalTransform(
      currentMatrix: currentMatrix,
      prevFocalPoint: focalPoint,
      currentFocalPoint: focalPoint,
      scaleFactor: scaleFactor,
      minScale: minScale,
      maxScale: maxScale,
    );
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
      s = (currentDistance / initialDistance).clamp(0.05, 20.0);
    }
    final f0 = initialFocalPoint;
    final f1 = currentFocalPoint;
    return Matrix4.identity()
      ..translateByDouble(f1.dx - s * f0.dx, f1.dy - s * f0.dy, 0.0, 1.0)
      ..scaleByDouble(s, s, 1.0, 1.0)
      ..multiply(initialTransform);
  }
}
