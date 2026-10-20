import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../database/database_helper.dart';
import '../../models/download_queue_item.dart';
import '../../models/music_track.dart';
import '../../services/music_download_service.dart';
import '../../services/notification_service.dart';

class MusicDownloadQueueManager {
  final MusicDownloadService downloadService;
  final VoidCallback onNotify;
  final Future<void> Function() onReloadTracks;
  final List<MusicTrack> Function() getTracks;
  final void Function(MusicTrack updated) onUpdateTrack;

  MusicDownloadQueueManager({
    required this.downloadService,
    required this.onNotify,
    required this.onReloadTracks,
    required this.getTracks,
    required this.onUpdateTrack,
  });

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  String? _lastDownloadError;

  final List<DownloadQueueItem> _downloadQueue = [];
  bool _isProcessingQueue = false;
  final Set<int> _localDownloadingIds = {};

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get downloadStatus => _downloadStatus;
  String? get lastDownloadError => _lastDownloadError;

  List<DownloadQueueItem> get downloadQueue => List.unmodifiable(_downloadQueue);
  int get queuedCount => _downloadQueue.where((i) => i.isQueued).length;
  int get activeOrQueuedCount => _downloadQueue.where((i) => i.isDownloading || i.isQueued).length;
  DownloadQueueItem? get currentDownloadingItem =>
      _downloadQueue.where((i) => i.isDownloading).firstOrNull;

  bool isDownloadingItem(String youtubeId) =>
      _downloadQueue.any((i) => i.id == youtubeId && i.isDownloading);

  bool isQueuedItem(String youtubeId) =>
      _downloadQueue.any((i) => i.id == youtubeId && i.isQueued);

  DownloadQueueItem? getQueueItem(String youtubeId) =>
      _downloadQueue.where((i) => i.id == youtubeId).firstOrNull;

  int getQueuePosition(String youtubeId) {
    final queuedList = _downloadQueue.where((i) => i.isQueued).toList();
    final idx = queuedList.indexWhere((i) => i.id == youtubeId);
    return idx != -1 ? idx + 1 : 0;
  }

  Set<int> get localDownloadingIds => _localDownloadingIds;

  Future<List<YouTubeSearchResult>> searchYouTube(String query) async {
    return await downloadService.search(query);
  }

  bool addToDownloadQueue(YouTubeSearchResult result) {
    if (getTracks().any((t) => t.youtubeId == result.id)) {
      return false;
    }

    final existing = getQueueItem(result.id);
    if (existing != null) {
      if (existing.isDownloading || existing.isQueued) {
        return false;
      }
      _downloadQueue.remove(existing);
    }

    final newItem = DownloadQueueItem(searchResult: result);
    _downloadQueue.add(newItem);
    onNotify();

    _processQueue();
    return true;
  }

  void removeFromQueue(String youtubeId) {
    _downloadQueue.removeWhere((i) => i.id == youtubeId && !i.isDownloading);
    onNotify();
  }

  void retryDownload(String youtubeId) {
    final item = getQueueItem(youtubeId);
    if (item != null && item.isFailed) {
      item.status = DownloadItemStatus.queued;
      item.progress = 0.0;
      item.statusMessage = 'En cola...';
      item.errorMessage = null;
      onNotify();
      _processQueue();
    }
  }

  void clearFinishedDownloads() {
    _downloadQueue.removeWhere((i) => i.isCompleted || i.isFailed || i.isCancelled);
    onNotify();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (true) {
      final nextIdx = _downloadQueue.indexWhere((i) => i.isQueued);
      if (nextIdx == -1) break;

      final currentItem = _downloadQueue[nextIdx];
      currentItem.status = DownloadItemStatus.downloading;
      currentItem.progress = 0.05;
      currentItem.statusMessage = 'Iniciando extracción...';

      _isDownloading = true;
      _downloadProgress = 0.05;
      _downloadStatus = 'Descargando: ${currentItem.title}';
      _lastDownloadError = null;
      onNotify();

      try {
        final track = await downloadService.downloadAndUploadTrack(
          currentItem.searchResult,
          onProgress: (p, s) {
            currentItem.progress = p;
            currentItem.statusMessage = s;
            _downloadProgress = p;
            _downloadStatus = '${currentItem.title} ($s)';
            onNotify();
          },
        );

        if (track != null) {
          currentItem.status = DownloadItemStatus.completed;
          currentItem.progress = 1.0;
          currentItem.statusMessage = '¡Guardada en Supabase!';
          currentItem.savedTrack = track;
          await onReloadTracks();

          NotificationService.showInAppNotification(InAppNotificationItem(
            title: 'Música guardada',
            body: '¡"${currentItem.title}" ya está disponible en la música compartida!',
            data: {'type': 'music'},
          ));
        } else {
          currentItem.status = DownloadItemStatus.failed;
          currentItem.errorMessage = 'No se pudo guardar la canción';
          currentItem.statusMessage = 'Error al guardar';
        }
      } catch (e) {
        developer.log('MusicDownloadQueueManager._processQueue error: $e');
        currentItem.status = DownloadItemStatus.failed;
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        currentItem.errorMessage = cleanMsg;
        currentItem.statusMessage = 'Error: $cleanMsg';
        _lastDownloadError = cleanMsg;
      } finally {
        onNotify();
      }
    }

    _isDownloading = false;
    _downloadProgress = 0.0;
    _downloadStatus = '';
    _isProcessingQueue = false;
    onNotify();
  }

  Future<MusicTrack?> downloadTrack(YouTubeSearchResult result) async {
    final existing = getTracks().where((t) => t.youtubeId == result.id).firstOrNull;
    if (existing != null) return existing;

    addToDownloadQueue(result);

    while (true) {
      final item = getQueueItem(result.id);
      if (item == null) return null;
      if (item.isCompleted) return item.savedTrack;
      if (item.isFailed || item.isCancelled) return null;
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<bool> downloadTrackLocally(MusicTrack track) async {
    if (track.audioUrl.isEmpty) return false;
    final trackId = track.id ?? track.cloudId ?? 0;
    _localDownloadingIds.add(trackId);
    onNotify();

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final ext = track.audioUrl.contains('.mp4') || track.audioUrl.contains('.m4a') ? 'm4a' : 'mp3';
      final fileName = 'furi_offline_${track.cloudId ?? track.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final localFile = File('${docsDir.path}/$fileName');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(Uri.parse(track.audioUrl));
      final res = await req.close();
      if (res.statusCode != 200 && res.statusCode != 206) {
        client.close();
        return false;
      }

      final sink = localFile.openWrite();
      await for (final chunk in res) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      client.close();

      final updated = track.copyWith(localPath: localFile.path);
      onUpdateTrack(updated);

      final db = await DatabaseHelper().database;
      await db.update('music_tracks', {'local_path': localFile.path}, where: 'id = ?', whereArgs: [track.id]);
      onNotify();
      return true;
    } catch (e) {
      developer.log('downloadTrackLocally error: $e');
      return false;
    } finally {
      _localDownloadingIds.remove(trackId);
      onNotify();
    }
  }

  Future<void> removeLocalCopy(MusicTrack track) async {
    try {
      if (track.localPath.isNotEmpty) {
        final f = File(track.localPath);
        if (await f.exists()) {
          await f.delete();
        }
      }
      final updated = track.copyWith(localPath: '');
      onUpdateTrack(updated);

      final db = await DatabaseHelper().database;
      await db.update('music_tracks', {'local_path': ''}, where: 'id = ?', whereArgs: [track.id]);
      onNotify();
    } catch (e) {
      developer.log('removeLocalCopy error: $e');
    }
  }
}
