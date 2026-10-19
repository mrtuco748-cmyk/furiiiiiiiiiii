import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/music_track.dart';

void main() {
  group('MusicTrack model tests', () {
    test('instantiates with defaults and converts to/from SQLite map', () {
      final now = DateTime.now().toIso8601String();
      final track = MusicTrack(
        id: 1,
        cloudId: 42,
        youtubeId: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        artist: 'Rick Astley',
        durationSeconds: 213,
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        audioUrl: 'https://supabase.co/storage/v1/object/public/music/rick.mp3',
        localPath: '/data/user/0/app/music/rick.mp3',
        addedBy: 'Facu',
        sizeBytes: 3145728,
        isFavorite: true,
        synced: 1,
        createdAt: now,
      );

      final map = track.toMap();
      expect(map['id'], 1);
      expect(map['cloud_id'], 42);
      expect(map['youtube_id'], 'dQw4w9WgXcQ');
      expect(map['title'], 'Never Gonna Give You Up');
      expect(map['artist'], 'Rick Astley');
      expect(map['duration_seconds'], 213);
      expect(map['is_favorite'], 1);
      expect(map['added_by'], 'Facu');
      expect(map['size_bytes'], 3145728);

      final fromMap = MusicTrack.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.cloudId, 42);
      expect(fromMap.title, 'Never Gonna Give You Up');
      expect(fromMap.isFavorite, true);
      expect(fromMap.durationFormatted, '3:33');
    });

    test('toSupabaseMap and fromCloudRow map properly', () {
      final track = MusicTrack(
        cloudId: 99,
        youtubeId: 'abc123xyz',
        title: 'Nuestra Canción',
        artist: 'Monsieur Periné',
        durationSeconds: 180,
        thumbnailUrl: 'https://img.youtube.com/vi/abc123xyz/0.jpg',
        audioUrl: 'https://supabase.co/storage/v1/object/public/music/cancion.mp3',
        addedBy: 'Rocio',
        sizeBytes: 2500000,
        isFavorite: false,
        createdAt: '2026-10-14T12:00:00Z',
      );

      final supaMap = track.toSupabaseMap();
      expect(supaMap['youtube_id'], 'abc123xyz');
      expect(supaMap['added_by'], 'Rocio');
      expect(supaMap['duration_seconds'], 180);

      final cloudRow = {
        'id': 99,
        'youtube_id': 'abc123xyz',
        'title': 'Nuestra Canción',
        'artist': 'Monsieur Periné',
        'duration_seconds': 180,
        'thumbnail_url': 'https://img.youtube.com/vi/abc123xyz/0.jpg',
        'audio_url': 'https://supabase.co/storage/v1/object/public/music/cancion.mp3',
        'added_by': 'Rocio',
        'size_bytes': 2500000,
        'is_favorite': false,
        'created_at': '2026-10-14T12:00:00Z',
      };

      final fromCloud = MusicTrack.fromCloudRow(cloudRow);
      expect(fromCloud.cloudId, 99);
      expect(fromCloud.addedBy, 'Rocio');
      expect(fromCloud.durationFormatted, '3:00');
    });

    test('copyWith updates fields properly', () {
      final original = MusicTrack(
        id: 5,
        youtubeId: 'id1',
        title: 'Original Title',
        audioUrl: '',
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        audioUrl: 'https://newurl.mp3',
        isFavorite: true,
      );

      expect(updated.id, 5);
      expect(updated.title, 'Updated Title');
      expect(updated.audioUrl, 'https://newurl.mp3');
      expect(updated.isFavorite, true);
    });
  });
}
