import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/canvas_background_type.dart';
import '../models/drawing_layer.dart';
import '../painters/stroke_renderer.dart';

/// Helper desacoplado para exportación a PNG del lienzo multicapa con escalado de coordenadas.
abstract final class DrawingRenderExporter {
  static Future<Uint8List?> exportToPng({
    required List<DrawingLayer> layers,
    required CanvasBackgroundType backgroundType,
    Size size = const Size(1080, 1080),
    Size? canvasSize,
  }) async {
    final srcW = (canvasSize?.width ?? 2000.0).clamp(1.0, 10000.0);
    final srcH = (canvasSize?.height ?? 2000.0).clamp(1.0, 10000.0);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundType.color,
    );

    canvas.save();
    canvas.scale(size.width / srcW, size.height / srcH);

    for (final layer in layers) {
      if (!layer.isVisible) continue;
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, srcW, srcH),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: layer.opacity),
      );

      for (final stroke in layer.strokes) {
        StrokeRenderer.renderStroke(canvas, stroke);
      }
      canvas.restore();
    }
    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
