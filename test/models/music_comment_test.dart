import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/music_comment.dart';

void main() {
  group('MusicComment Model Tests', () {
    test('toMap and fromMap work symmetrically', () {
      final comment = MusicComment(
        id: 1,
        cloudId: 101,
        trackId: 5,
        userId: 'Facu',
        content: 'Me encanta este tema!',
        createdAt: '2026-10-14T12:00:00Z',
      );

      final map = comment.toMap();
      final restored = MusicComment.fromMap(map);

      expect(restored.id, 1);
      expect(restored.cloudId, 101);
      expect(restored.trackId, 5);
      expect(restored.userId, 'Facu');
      expect(restored.content, 'Me encanta este tema!');
      expect(restored.createdAt, '2026-10-14T12:00:00Z');
    });

    test('fromCloudRow parses supabase row correctly', () {
      final row = {
        'id': 202,
        'track_id': 10,
        'user_id': 'Rocio',
        'content': 'Para escuchar en el auto',
        'created_at': '2026-10-14T12:15:00Z',
      };

      final comment = MusicComment.fromCloudRow(row);
      expect(comment.cloudId, 202);
      expect(comment.trackId, 10);
      expect(comment.userId, 'Rocio');
      expect(comment.content, 'Para escuchar en el auto');
    });

    test('copyWith updates properties properly', () {
      final comment = MusicComment(
        trackId: 5,
        userId: 'Facu',
        content: 'Hola',
        createdAt: 'now',
      );

      final updated = comment.copyWith(content: 'Chau', cloudId: 55);
      expect(updated.content, 'Chau');
      expect(updated.cloudId, 55);
      expect(updated.userId, 'Facu');
    });
  });
}
