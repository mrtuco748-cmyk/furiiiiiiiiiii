import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/comic_page.dart';
import '../painters/comic_page_painter.dart';

/// Helper de renderizado de alta resolución para exportación de páginas a PNG.
abstract final class ComicRenderExporter {
  static Future<Uint8List?> exportPageToPng(
    ComicPage page,
    Map<String, ui.Image> panelImages, {
    Size size = const Size(1200, 1697),
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));
    final painter = ComicPagePainter(page: page, panelImages: panelImages);
    painter.paint(canvas, size);

    final pic = recorder.endRecording();
    final img = await pic.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
