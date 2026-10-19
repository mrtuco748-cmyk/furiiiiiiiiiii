import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/services/music_download_service.dart';

void main() {
  group('MusicDownloadService and YouTubeSearchResult Tests', () {
    test('YouTubeSearchResult durationFormatted formats seconds properly', () {
      final res1 = YouTubeSearchResult(
        id: '123',
        title: 'Song A',
        author: 'Artist A',
        durationSeconds: 185,
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );
      expect(res1.durationFormatted, '3:05');

      final res2 = YouTubeSearchResult(
        id: '456',
        title: 'Song B',
        author: 'Artist B',
        durationSeconds: 59,
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );
      expect(res2.durationFormatted, '0:59');

      final res3 = YouTubeSearchResult(
        id: '789',
        title: 'Song C',
        author: 'Artist C',
        durationSeconds: 360,
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );
      expect(res3.durationFormatted, '6:00');
    });

    test('MusicDownloadService instantiates and disposes cleanly', () {
      final service = MusicDownloadService();
      expect(service, isNotNull);
      service.dispose();
    });
  });
}
