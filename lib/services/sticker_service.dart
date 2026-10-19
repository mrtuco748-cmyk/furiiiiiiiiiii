import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class StickerService {
  /// Directorio local exclusivo de stickers guardados de la app
  static Future<Directory> getStickersDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'furi_stickers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Devuelve la lista de stickers almacenados localmente, ordenados del más reciente al más antiguo.
  static Future<List<File>> getSavedStickers() async {
    try {
      final dir = await getStickersDirectory();
      final entities = await dir.list().toList();
      final files = entities
          .whereType<File>()
          .where((f) {
            final ext = p.extension(f.path).toLowerCase();
            return ext == '.webp' || ext == '.png' || ext == '.jpg' || ext == '.jpeg';
          })
          .toList();

      files.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (_) {
          return 0;
        }
      });
      return files;
    } catch (e) {
      debugPrint('StickerService.getSavedStickers error: $e');
      return [];
    }
  }

  /// Rutas conocidas de WhatsApp en Android donde se almacenan los stickers (.webp)
  static List<String> get _whatsAppStickersPaths => [
        // Android 11+ (Scoped Storage común)
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Stickers',
        // Android 10 y anteriores
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Stickers',
        // WhatsApp Business (Android 11+)
        '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/WhatsApp Business Stickers',
        // WhatsApp Business tradicional
        '/storage/emulated/0/WhatsApp Business/Media/WhatsApp Business Stickers',
      ];

  /// Intenta buscar y exportar automáticamente los stickers de WhatsApp a F.U.R.I.
  /// Si encuentra la carpeta con archivos .webp, los copia a la carpeta local.
  /// Devuelve la cantidad de stickers nuevos importados.
  static Future<int> exportFromWhatsAppDirect() async {
    int imported = 0;
    try {
      final targetDir = await getStickersDirectory();
      final existingNames = (await targetDir.list().toList())
          .map((e) => p.basename(e.path))
          .toSet();

      for (final rawPath in _whatsAppStickersPaths) {
        final sourceDir = Directory(rawPath);
        if (await sourceDir.exists()) {
          final list = await sourceDir.list().toList();
          for (final entity in list) {
            if (entity is File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (ext == '.webp' || ext == '.png') {
                final baseName = p.basename(entity.path);
                if (!existingNames.contains(baseName)) {
                  final destPath = p.join(targetDir.path, baseName);
                  await entity.copy(destPath);
                  existingNames.add(baseName);
                  imported++;
                }
              }
            }
          }
          if (imported > 0) break;
        }
      }
    } catch (e) {
      debugPrint('StickerService.exportFromWhatsAppDirect error: $e');
    }
    return imported;
  }

  /// Selector de archivos manual como respaldo o para importar paquetes descargados
  static Future<int> pickAndImportStickers() async {
    int imported = 0;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webp', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return 0;

      final targetDir = await getStickersDirectory();
      for (final f in result.files) {
        if (f.path != null) {
          final file = File(f.path!);
          final name = 'stk_${DateTime.now().millisecondsSinceEpoch}_${p.basename(f.path!)}';
          final dest = p.join(targetDir.path, name);
          await file.copy(dest);
          imported++;
        }
      }
    } catch (e) {
      debugPrint('StickerService.pickAndImportStickers error: $e');
    }
    return imported;
  }

  /// Elimina un sticker específico
  static Future<bool> deleteSticker(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('StickerService.deleteSticker error: $e');
    }
    return false;
  }
}
