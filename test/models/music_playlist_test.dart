import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/music_playlist.dart';

void main() {
  group('MusicPlaylist Model Tests', () {
    test('toMap and fromMap work symmetrically', () {
      final playlist = MusicPlaylist(
        id: 1,
        cloudId: 50,
        title: 'Viaje a la Costa',
        description: 'Canciones para la ruta',
        createdBy: 'Facu',
        trackIds: [1, 5, 8],
        createdAt: '2026-10-14T10:00:00Z',
      );

      final map = playlist.toMap();
      final restored = MusicPlaylist.fromMap(map);

      expect(restored.id, 1);
      expect(restored.cloudId, 50);
      expect(restored.title, 'Viaje a la Costa');
      expect(restored.description, 'Canciones para la ruta');
      expect(restored.createdBy, 'Facu');
      expect(restored.trackIds, [1, 5, 8]);
      expect(restored.createdAt, '2026-10-14T10:00:00Z');
    });

    test('fromCloudRow handles List track_ids', () {
      final row = {
        'id': 99,
        'title': 'Entrenamiento',
        'description': 'Poder',
        'created_by': 'Rocio',
        'track_ids': [12, 14, 18],
        'created_at': '2026-10-14T10:30:00Z',
      };

      final playlist = MusicPlaylist.fromCloudRow(row);
      expect(playlist.cloudId, 99);
      expect(playlist.title, 'Entrenamiento');
      expect(playlist.trackIds, [12, 14, 18]);
      expect(playlist.createdBy, 'Rocio');
    });

    test('copyWith updates properties properly', () {
      final playlist = MusicPlaylist(
        title: 'Chill',
        createdBy: 'Facu',
        createdAt: 'now',
      );

      final updated = playlist.copyWith(trackIds: [100, 200], description: 'Relax total');
      expect(updated.trackIds, [100, 200]);
      expect(updated.description, 'Relax total');
      expect(updated.title, 'Chill');
    });
  });
}
