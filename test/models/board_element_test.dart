import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/board_element.dart';
import 'package:furi_app/app_state.dart';

void main() {
  setUp(() {
    AppState.myId = 'facu-uuid';
  });

  group('BoardElement', () {
    test('serializa y deserializa campos base y nuevos', () {
      final el = BoardElement(
        type: 'note',
        content: 'hola',
        x: 10,
        y: 20,
        width: 200,
        height: 150,
        rotation: 0.2,
        color: '#FFDE59',
        z: 3,
        data: {'title': 'x'},
      );
      final back = BoardElement.fromMap(el.toMap());
      expect(back.type, 'note');
      expect(back.x, 10);
      expect(back.z, 3);
      expect(back.data['title'], 'x');
    });

    test('toMap incluye user_id actual', () {
      final el = BoardElement(type: 'note');
      expect(el.toMap()['user_id'], 'facu-uuid');
    });

    test('copyWith actualiza posicion, tamano y data sin pisar lo demas', () {
      final el = BoardElement(type: 'note', x: 1, y: 2, width: 100, height: 50, z: 1);
      final updated = el.copyWith(x: 50, width: 220, height: 120, data: {'url': 'a'});
      expect(updated.x, 50);
      expect(updated.width, 220);
      expect(updated.height, 120);
      expect(updated.y, 2);
      expect(updated.z, 1);
      expect(updated.data['url'], 'a');
    });

    test('center calcula el punto medio', () {
      final el = BoardElement(type: 'note', x: 100, y: 200, width: 100, height: 80);
      expect(el.center.dx, 150);
      expect(el.center.dy, 240);
    });

    test('isMine compara contra el usuario actual', () {
      final mine = BoardElement(type: 'note', userId: 'facu-uuid');
      final other = BoardElement(type: 'note', userId: 'rocio-uuid');
      expect(mine.isMine, isTrue);
      expect(other.isMine, isFalse);
    });
  });
}
