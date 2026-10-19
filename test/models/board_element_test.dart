import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/board_element.dart';

void main() {
  group('BoardElement model tests', () {
    test('instantiates with defaults and converts to/from SQLite map', () {
      final now = DateTime.now().toIso8601String();
      final element = BoardElement(
        id: 1,
        cloudId: 101,
        boardId: 1,
        userId: 'Facu',
        type: 'note',
        title: 'Mi Idea',
        content: 'Recordar comprar flores',
        color: '#9D00FF',
        x: 150.0,
        y: 220.5,
        width: 220.0,
        height: 180.0,
        data: {'noteType': 'postit'},
        synced: 1,
        createdAt: now,
        updatedAt: now,
      );

      final map = element.toMap();
      expect(map['id'], 1);
      expect(map['cloud_id'], 101);
      expect(map['board_id'], 1);
      expect(map['user_id'], 'Facu');
      expect(map['type'], 'note');
      expect(map['title'], 'Mi Idea');
      expect(map['content'], 'Recordar comprar flores');
      expect(map['color'], '#9D00FF');
      expect(map['x'], 150.0);
      expect(map['y'], 220.5);
      expect(map['width'], 220.0);
      expect(map['height'], 180.0);
      expect(map['synced'], 1);
      expect(map['data'], contains('postit'));

      final fromMap = BoardElement.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.cloudId, 101);
      expect(fromMap.title, 'Mi Idea');
      expect(fromMap.x, 150.0);
      expect(fromMap.y, 220.5);
      expect(fromMap.data['noteType'], 'postit');
    });

    test('toSupabaseMap and fromCloudRow map properly', () {
      final element = BoardElement(
        cloudId: 55,
        boardId: 1,
        userId: 'Rocio',
        type: 'checklist',
        title: 'Supermercado',
        content: '',
        color: '#39FF14',
        x: -50.0,
        y: 80.0,
        width: 250.0,
        height: 200.0,
        data: {
          'items': [
            {'text': 'Frutas', 'done': true}
          ]
        },
        createdAt: '2026-10-14T10:00:00Z',
        updatedAt: '2026-10-14T10:00:00Z',
      );

      final supaMap = element.toSupabaseMap();
      expect(supaMap['user_id'], 'Rocio');
      expect(supaMap['board_id'], 1);
      expect(supaMap['type'], 'checklist');
      expect(supaMap['x'], -50.0);
      expect(supaMap['y'], 80.0);
      expect(supaMap['data'], isA<Map>());

      final cloudRow = {
        'id': 55,
        'board_id': 1,
        'user_id': 'Rocio',
        'type': 'checklist',
        'title': 'Supermercado',
        'content': '',
        'color': '#39FF14',
        'x': -50.0,
        'y': 80.0,
        'width': 250.0,
        'height': 200.0,
        'data': {
          'items': [
            {'text': 'Frutas', 'done': true}
          ]
        },
        'created_at': '2026-10-14T10:00:00Z',
        'updated_at': '2026-10-14T10:00:00Z',
      };

      final fromCloud = BoardElement.fromCloudRow(cloudRow);
      expect(fromCloud.cloudId, 55);
      expect(fromCloud.userId, 'Rocio');
      expect(fromCloud.x, -50.0);
      expect(fromCloud.data['items'].first['text'], 'Frutas');
    });

    test('copyWith updates fields as expected', () {
      final original = BoardElement(
        id: 10,
        title: 'Original',
        x: 10,
        y: 10,
      );

      final moved = original.copyWith(x: 100, y: 200, title: 'Movido');
      expect(moved.id, 10);
      expect(moved.x, 100);
      expect(moved.y, 200);
      expect(moved.title, 'Movido');
    });
  });
}
