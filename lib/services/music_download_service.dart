import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../app_state.dart';
import '../database/database_helper.dart';
import '../models/music_track.dart';
import '../supabase_config.dart';

/// Resultado simplificado de búsqueda de YouTube
class YouTubeSearchResult {
  final String id;
  final String title;
  final String author;
  final int durationSeconds;
  final String thumbnailUrl;

  YouTubeSearchResult({
    required this.id,
    required this.title,
    required this.author,
    required this.durationSeconds,
    required this.thumbnailUrl,
  });

  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

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

      // 1. Guardar primero en Supabase Cloud
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

      // 2. Guardar metadatos en SQLite local SIN guardar archivo permanente en el dispositivo (localPath = '')
      final localTrack = MusicTrack(
        cloudId: cloudId,
        youtubeId: item.id,
        title: item.title,
        artist: item.author,
        durationSeconds: item.durationSeconds,
        thumbnailUrl: item.thumbnailUrl,
        audioUrl: publicUrl,
        localPath: '', // No ocupa espacio permanente en el dispositivo
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
      // Garantizar que el archivo temporal se elimine inmediatamente para no ocupar espacio en el disco
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
      final success = await _downloadViaConverter(item.id, tempFile, onProgress: onProgress);
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

  /// Convertidor online con polling de estado que devuelve audio MP3 limpio
  Future<bool> _downloadViaConverter(
    String youtubeId,
    File destination, {
    Function(double progress, String status)? onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      onProgress?.call(0.12, 'Conectando con servicio de conversión...');
      final req = await client.getUrl(Uri.parse(
        'https://loader.to/ajax/download.php?format=mp3&url=https://www.youtube.com/watch?v=$youtubeId',
      ));
      req.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return false;

      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final contentB64 = json['content'] as String?;
      if (contentB64 == null) return false;

      final html = utf8.decode(base64Decode(contentB64));
      final idMatch = RegExp(r'id="(v2_stream_[a-f0-9]+)_downloadLink"').firstMatch(html) ??
          RegExp(r'id="card-(v2_stream_[a-f0-9]+)"').firstMatch(html);
      final streamId = idMatch?.group(1);
      if (streamId == null) return false;

      String? downloadUrl;
      // Polling por hasta 30 segundos
      for (int i = 0; i < 25; i++) {
        await Future.delayed(const Duration(milliseconds: 1200));
        final pReq = await client.getUrl(Uri.parse('https://p.savenow.to/ajax/progress.php?id=$streamId'));
        pReq.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
        final pRes = await pReq.close().timeout(const Duration(seconds: 8));
        if (pRes.statusCode != 200) continue;

        final pBody = await pRes.transform(utf8.decoder).join();
        final pJson = jsonDecode(pBody) as Map<String, dynamic>;

        final dl = pJson['download_url'] as String?;
        if (dl != null && dl.isNotEmpty) {
          downloadUrl = dl;
          break;
        }

        // Progreso de conversión (0.15 a 0.48)
        final pVal = (pJson['progress'] as num?)?.toDouble() ?? 50.0;
        final pNorm = (0.15 + (pVal / 1000.0) * 0.33).clamp(0.15, 0.48);
        final statusText = pJson['text'] as String? ?? 'Preparando audio comprimido...';
        onProgress?.call(pNorm, statusText);
      }

      if (downloadUrl == null || downloadUrl.isEmpty) return false;

      onProgress?.call(0.50, 'Descargando audio...');
      final dReq = await client.getUrl(Uri.parse(downloadUrl));
      final dRes = await dReq.close().timeout(const Duration(seconds: 15));
      if (dRes.statusCode != 200 && dRes.statusCode != 206) return false;

      final totalBytes = dRes.contentLength;
      final fileSink = destination.openWrite();
      int downloaded = 0;

      await for (final chunk in dRes) {
        fileSink.add(chunk);
        downloaded += chunk.length;
        if (totalBytes > 0) {
          final p = 0.50 + (downloaded / totalBytes) * 0.20;
          onProgress?.call(p.clamp(0.50, 0.70), 'Descargando: ${(downloaded / 1024 / 1024).toStringAsFixed(1)} MB');
        } else {
          onProgress?.call(0.60, 'Descargando: ${(downloaded / 1024 / 1024).toStringAsFixed(1)} MB');
        }
      }
      await fileSink.flush();
      await fileSink.close();

      return downloaded > 50000;
    } catch (e) {
      developer.log('_downloadViaConverter error: $e');
      return false;
    } finally {
      client.close();
    }
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
