import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../models/comic_page.dart';

/// Helper para decodificación asíncrona y caché en memoria de imágenes incrustadas en viñetas.
abstract final class ComicImageCache {
  static void decodeAll(ComicPage page, Map<String, ui.Image> cache, VoidCallback onUpdate) {
    for (final panel in page.panels) {
      if (panel.drawingPngBase64 != null) {
        decodeSingle(panel.id, panel.drawingPngBase64!, cache, onUpdate);
      }
    }
  }

  static void decodeSingle(String panelId, String base64Str, Map<String, ui.Image> cache, VoidCallback onUpdate) {
    try {
      final bytes = base64Decode(base64Str);
      ui.decodeImageFromList(bytes, (img) {
        cache[panelId] = img;
        onUpdate();
      });
    } catch (_) {}
  }

  static Future<Map<String, ui.Image>> ensureDecoded(ComicPage page, Map<String, ui.Image> currentCache) async {
    final result = Map<String, ui.Image>.from(currentCache);
    for (final panel in page.panels) {
      if (panel.drawingPngBase64 != null && !result.containsKey(panel.id)) {
        try {
          final bytes = base64Decode(panel.drawingPngBase64!);
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          result[panel.id] = frame.image;
        } catch (_) {}
      }
    }
    return result;
  }
}
