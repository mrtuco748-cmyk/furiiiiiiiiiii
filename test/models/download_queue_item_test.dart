import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/download_queue_item.dart';
import 'package:furi_app/services/music_download_service.dart';

void main() {
  group('DownloadQueueItem Model Tests', () {
    final sampleResult = YouTubeSearchResult(
      id: 'yt_abc_123',
      title: 'Canción Romántica',
      author: 'Artista Genial',
      durationSeconds: 215,
      thumbnailUrl: 'https://example.com/thumb.jpg',
    );

    test('Initializes with default queued values', () {
      final item = DownloadQueueItem(searchResult: sampleResult);

      expect(item.id, 'yt_abc_123');
      expect(item.title, 'Canción Romántica');
      expect(item.author, 'Artista Genial');
      expect(item.durationSeconds, 215);
      expect(item.durationFormatted, '3:35');
      expect(item.status, DownloadItemStatus.queued);
      expect(item.progress, 0.0);
      expect(item.statusMessage, 'En cola...');
      expect(item.isQueued, isTrue);
      expect(item.isDownloading, isFalse);
      expect(item.isCompleted, isFalse);
      expect(item.isFailed, isFalse);
      expect(item.isCancelled, isFalse);
    });

    test('Status transitions work properly', () {
      final item = DownloadQueueItem(searchResult: sampleResult);

      item.status = DownloadItemStatus.downloading;
      item.progress = 0.45;
      item.statusMessage = 'Descargando audio...';
      expect(item.isDownloading, isTrue);
      expect(item.isQueued, isFalse);
      expect(item.progress, 0.45);

      item.status = DownloadItemStatus.completed;
      item.progress = 1.0;
      item.statusMessage = '¡Guardada!';
      expect(item.isCompleted, isTrue);

      item.status = DownloadItemStatus.failed;
      item.errorMessage = 'Network timeout';
      expect(item.isFailed, isTrue);
      expect(item.errorMessage, 'Network timeout');

      item.status = DownloadItemStatus.cancelled;
      expect(item.isCancelled, isTrue);
    });

    test('copyWith updates properties properly', () {
      final item = DownloadQueueItem(searchResult: sampleResult);
      final updated = item.copyWith(
        status: DownloadItemStatus.downloading,
        progress: 0.8,
        statusMessage: 'Subiendo a Supabase...',
      );

      expect(updated.id, item.id);
      expect(updated.status, DownloadItemStatus.downloading);
      expect(updated.progress, 0.8);
      expect(updated.statusMessage, 'Subiendo a Supabase...');
    });
  });
}
