import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_helper.dart';
import '../supabase_config.dart';

class ChatMediaService {
  static const bucket = 'chat-media';

  final DatabaseHelper _db;
  ChatMediaService({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<Directory> _mediaDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'chat_media'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> copyToLocalCache({
    required String sourcePath,
    required String preferredName,
  }) async {
    final dir = await _mediaDir();
    final safe = preferredName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = p.join(dir.path, '${stamp}_$safe');
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<String> saveBytesLocal({
    required Uint8List bytes,
    required String preferredName,
  }) async {
    final dir = await _mediaDir();
    final safe = preferredName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = p.join(dir.path, '${stamp}_$safe');
    await File(dest).writeAsBytes(bytes, flush: true);
    return dest;
  }

  Future<String> uploadFile({
    required String localPath,
    required String ownerId,
    required String fileName,
  }) async {
    final safe = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$ownerId/${stamp}_$safe';
    await _client.storage.from(bucket).upload(
          storagePath,
          File(localPath),
          fileOptions: const FileOptions(upsert: false),
        );
    return storagePath;
  }

  Future<String> downloadAndKeepLocal({
    required int messageId,
    required String storagePath,
    String? fileName,
    String? mimeType,
  }) async {
    final existing = await _db.getChatMediaLocalPath(messageId);
    if (existing != null && await File(existing).exists()) {
      return existing;
    }

    final bytes = await _client.storage.from(bucket).download(storagePath);
    final name = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : p.basename(storagePath);
    final localPath = await saveBytesLocal(bytes: bytes, preferredName: name);
    await _db.saveChatMediaLocal(
      messageId: messageId,
      localPath: localPath,
      fileName: name,
      mimeType: mimeType,
    );
    return localPath;
  }

  Future<void> bindLocalPath({
    required int messageId,
    required String localPath,
    String? fileName,
    String? mimeType,
  }) async {
    await _db.saveChatMediaLocal(
      messageId: messageId,
      localPath: localPath,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<void> deleteFromCloud(String storagePath) async {
    if (storagePath.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove([storagePath]);
    } catch (_) {
      // El archivo puede ya no existir; no bloquear el flujo local.
    }
  }

  Future<Map<int, String>> loadLocalIndex() => _db.getAllChatMediaLocalPaths();

  static String guessMessageType({
    required String? mime,
    required String fileName,
  }) {
    final lowerMime = (mime ?? '').toLowerCase();
    final lowerName = fileName.toLowerCase();
    if (lowerMime == 'image/gif' || lowerName.endsWith('.gif')) return 'gif';
    if (lowerMime.startsWith('image/')) return 'image';
    if (lowerMime.startsWith('video/')) return 'video';
    if (lowerMime.startsWith('audio/')) return 'voice';
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.heic')) {
      return 'image';
    }
    if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.webm')) {
      return 'video';
    }
    if (lowerName.endsWith('.m4a') ||
        lowerName.endsWith('.aac') ||
        lowerName.endsWith('.mp3') ||
        lowerName.endsWith('.wav') ||
        lowerName.endsWith('.ogg')) {
      return 'voice';
    }
    return 'document';
  }
}
