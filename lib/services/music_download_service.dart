import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../app_state.dart';
import '../database/database_helper.dart';
import '../models/music_track.dart';
import '../models/youtube_search_result.dart';
import '../supabase_config.dart';
import 'helpers/audio_converter_downloader.dart';

export '../models/youtube_search_result.dart';

/// Servicio que busca en YouTube, descarga el audio comprimido
/// y lo almacena en Supabase Storage y base de datos compartida.
class MusicDownloadService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Busca videos en YouTube
  Future<List<YouTubeSearchResult>> search(String query) async {
    try {
      final searchList = await _yt.search.search(query);
      final results = <YouTubeSearchResult>[];
      for (final video in searchList.take(15)) {
        final duration = video.duration?.inSeconds ?? 0;
        final thumb = video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : 'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg';

        results.add(YouTubeSearchResult(
          id: video.id.value,
          title: video.title,
          author: video.author,
          durationSeconds: duration,
          thumbnailUrl: thumb,
        ));
      }
      return results;
    } catch (e) {
      developer.log('MusicDownloadService.search error: $e');
      return [];
    }
  }

  /// Descarga el audio temporalmente y lo sube directamente a Supabase
  Future<MusicTrack?> downloadAndUploadTrack(
    YouTubeSearchResult item, {
    Function(double progress, String status)? onProgress,
  }) async {
    File? tempFile;
    try {
      onProgress?.call(0.05, 'Iniciando extracción de audio...');

      tempFile = await _downloadAudioToTempFile(item, onProgress: onProgress);

      final fileSize = await tempFile.length();
      final fileExt = tempFile.path.endsWith('.mp3') ? 'mp3' : 'm4a';
      final fileName = '${item.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final mimeType = fileExt == 'mp3' ? 'audio/mpeg' : 'audio/mp4';

      onProgress?.call(0.72, 'Subiendo a la nube de Supabase...');
      final storagePath = 'music_library/$fileName';

      String bucket = 'music';
      try {
        await SupabaseConfig.client.storage.from(bucket).upload(
              storagePath,
              tempFile,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
      } catch (storageErr) {
        developer.log('Upload al bucket music falló ($storageErr), intentando chat-media...');
        bucket = 'chat-media';
        await SupabaseConfig.client.storage.from(bucket).upload(
              storagePath,
              tempFile,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
      }

      final publicUrl = SupabaseConfig.client.storage.from(bucket).getPublicUrl(storagePath);

      onProgress?.call(0.88, 'Registrando canción compartida...');
      final rawIdentity = AppState.identity;
      final author = (rawIdentity != null && rawIdentity.isNotEmpty) ? rawIdentity : 'Facu';
      final now = DateTime.now().toIso8601String();

      final cloudData = {
        'youtube_id': item.id,
        'title': item.title,
        'artist': item.author,
        'duration_seconds': item.durationSeconds,
        'thumbnail_url': item.thumbnailUrl,
        'audio_url': publicUrl,
        'added_by': author,
        'size_bytes': fileSize,
        'is_favorite': false,
        'created_at': now,
      };

      final res = await SupabaseConfig.client
          .from('music_tracks')
          .insert(cloudData)
          .select('id')
          .single();
      final cloudId = (res['id'] as num?)?.toInt();

      final localTrack = MusicTrack(
        cloudId: cloudId,
        youtubeId: item.id,
        title: item.title,
        artist: item.author,
        durationSeconds: item.durationSeconds,
        thumbnailUrl: item.thumbnailUrl,
        audioUrl: publicUrl,
        localPath: '',
        addedBy: author,
        sizeBytes: fileSize,
        isFavorite: false,
        synced: 1,
        createdAt: now,
      );

      final db = await DatabaseHelper().database;
      final localId = await db.insert('music_tracks', localTrack.toMap());
      final savedTrack = localTrack.copyWith(id: localId);

      onProgress?.call(1.0, '¡Canción guardada en Supabase!');
      return savedTrack;
    } catch (e) {
      developer.log('MusicDownloadService.downloadAndUploadTrack error: $e');
      rethrow;
    } finally {
      if (tempFile != null) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          developer.log('Limpieza de archivo temporal: $e');
        }
      }
    }
  }

  /// Obtiene el archivo de audio temporal probando primero el convertidor optimizado
  /// y luego youtube_explode con guardas de timeout estrictas para evitar bloqueos.
  Future<File> _downloadAudioToTempFile(
    YouTubeSearchResult item, {
    Function(double progress, String status)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'furi_music_${item.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final tempFile = File('${tempDir.path}/$fileName');

    // 1. Intentar descargar mediante el convertidor de audio online de alta fiabilidad
    try {
      final success = await AudioConverterDownloader.download(
        item.id,
        tempFile,
        onProgress: onProgress,
      );
      if (success && await tempFile.exists() && await tempFile.length() > 50000) {
        return tempFile;
      }
    } catch (e) {
      developer.log('Fallo convertidor online: $e');
    }

    // 2. Fallback a youtube_explode_dart con timeout estricto para no colgarse
    try {
      final success = await _downloadViaYoutubeExplode(item, tempFile, onProgress: onProgress);
      if (success && await tempFile.exists() && await tempFile.length() > 50000) {
        return tempFile;
      }
    } catch (e) {
      developer.log('Fallo youtube_explode fallback: $e');
    }

    throw Exception('No se pudo extraer el audio de la canción.');
  }

  /// Descarga directa via youtube_explode_dart con guardas de timeout estrictas
  Future<bool> _downloadViaYoutubeExplode(
    YouTubeSearchResult item,
    File destination, {
    Function(double progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(0.15, 'Consultando streams directos...');
      final manifest = await _yt.videos.streamsClient.getManifest(
        item.id,
        ytClients: [YoutubeApiClient.androidSdkless, YoutubeApiClient.ios],
        requireWatchPage: false,
      ).timeout(const Duration(seconds: 8));

      final audioStreams = manifest.audioOnly.sortByBitrate();
      if (audioStreams.isEmpty) return false;

      final selectedStream = audioStreams.firstWhere(
        (s) => s.container.name.toLowerCase() == 'mp4' || s.container.name.toLowerCase() == 'm4a',
        orElse: () => audioStreams.last,
      );

      final totalSize = selectedStream.size.totalBytes;
      final stream = _yt.videos.streamsClient.get(selectedStream);
      final fileStream = destination.openWrite();

      int downloaded = 0;
      await for (final chunk in stream) {
        fileStream.add(chunk);
        downloaded += chunk.length;
        if (totalSize > 0) {
          final p = 0.20 + (downloaded / totalSize) * 0.45;
          onProgress?.call(p.clamp(0.20, 0.65), 'Descargando: ${(downloaded / 1024 / 1024).toStringAsFixed(1)} MB');
        }
      }
      await fileStream.flush();
      await fileStream.close();

      return downloaded > 50000;
    } catch (e) {
      developer.log('_downloadViaYoutubeExplode error: $e');
      return false;
    }
  }

  void dispose() {
    _yt.close();
  }
}
