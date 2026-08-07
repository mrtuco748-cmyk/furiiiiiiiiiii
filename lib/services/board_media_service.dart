import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../app_state.dart';

/// Gestiona subida/descarga de imágenes del pizarron estilo Milanote.
/// Usa un bucket privado y bytes en memoria con cache (misma linea que chat-media).
class BoardMediaService {
  static const bucket = 'board-media';
  static final Map<String, Uint8List> _cache = {};

  SupabaseClient get _client => SupabaseConfig.client;

  Future<String> uploadImage(XFile file, {String? ownerId}) async {
    final safe = file.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${ownerId ?? AppState.myId ?? ''}/${stamp}_$safe';
    await _client.storage.from(bucket).upload(
          path,
          File(file.path),
          fileOptions: const FileOptions(upsert: false),
        );
    return path;
  }

  Future<Uint8List> downloadImage(String storagePath) async {
    final cached = _cache[storagePath];
    if (cached != null) return cached;
    final bytes = await _client.storage.from(bucket).download(storagePath);
    _cache[storagePath] = bytes;
    return bytes;
  }

  Future<void> deleteImage(String storagePath) async {
    if (storagePath.isEmpty) return;
    _cache.remove(storagePath);
    try {
      await _client.storage.from(bucket).remove([storagePath]);
    } catch (e) {
      debugPrint('BoardMediaService.deleteImage error (ignorable): $e');
    }
  }

  static String guessExt(String name) {
    final ext = p.extension(name).replaceAll('.', '').toLowerCase();
    if (ext.isEmpty) return 'jpg';
    return ext;
  }
}