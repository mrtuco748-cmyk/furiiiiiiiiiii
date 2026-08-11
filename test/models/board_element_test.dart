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

    test('toMap usa userId del constructor y no lo pisa', () {
      final el = BoardElement(type: 'note', userId: 'rocio-uuid');
      expect(el.toMap()['user_id'], 'rocio-uuid');
    });

    test('toMap cae a AppState.myId si no hay userId', () {
      final el = BoardElement(type: 'note');
      expect(el.toMap()['user_id'], 'facu-uuid');
    });

    test('copyWith actualiza posicion, tamano, data e id', () {
      final el = BoardElement(type: 'note', x: 1, y: 2, width: 100, height: 50, z: 1);
      final updated = el.copyWith(x: 50, width: 220, height: 120, data: {'url': 'a'}, id: 99);
      expect(updated.x, 50);
      expect(updated.width, 220);
      expect(updated.height, 120);
      expect(updated.y, 2);
      expect(updated.z, 1);
      expect(updated.data['url'], 'a');
      expect(updated.id, 99);
    });

    test('copyWith clearId limpia el id', () {
      final el = BoardElement(type: 'note', id: 5);
      expect(el.copyWith(clearId: true).id, isNull);
    });

    test('fromMap acepta data como Map dinamico', () {
      final back = BoardElement.fromMap({
        'id': 1,
        'type': 'link',
        'content': 'https://a.com',
        'data': <dynamic, dynamic>{'title': 'a.com', 'url': 'https://a.com'},
        'board_id': 2,
      });
      expect(back.data['title'], 'a.com');
      expect(back.boardId, 2);
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

    test('isDone es falso si no es task o no tiene done', () {
      expect(BoardElement(type: 'task').isDone, isFalse);
      expect(BoardElement(type: 'note').isDone, isFalse);
    });

    test('isDone es verdadero cuando data.done es true en task', () {
      final el = BoardElement(type: 'task', data: {'done': true});
      expect(el.isDone, isTrue);
    });

    test('boardId por defecto es 1 y se serializa/deserializa', () {
      expect(BoardElement(type: 'note').boardId, 1);
      final el = BoardElement(type: 'note', boardId: 7);
      final back = BoardElement.fromMap(el.toMap());
      expect(back.boardId, 7);
      expect(el.toMap()['board_id'], 7);
    });

    test('copyWith actualiza boardId', () {
      final el = BoardElement(type: 'note').copyWith(boardId: 5);
      expect(el.boardId, 5);
    });
  });
}
