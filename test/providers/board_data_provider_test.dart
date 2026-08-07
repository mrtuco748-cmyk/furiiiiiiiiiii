import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/board_element.dart';
import 'package:furi_app/providers/board_data_provider.dart';
import 'package:furi_app/app_state.dart';

void main() {
  setUp(() {
    AppState.myId = 'facu-uuid';
  });

  group('BoardDataProvider (logica pura)', () {
    test('zOrdered devuelve elementos ordenados por capa', () {
      final p = BoardDataProvider();
      p.setElementsForTest([
        BoardElement(type: 'note', id: 1, z: 2),
        BoardElement(type: 'note', id: 2, z: 0),
        BoardElement(type: 'note', id: 3, z: 5),
      ]);
      expect(p.zOrdered.map((e) => e.id).toList(), [2, 1, 3]);
      p.dispose();
    });

    test('moveLocal sin ID solo actualiza la copia local', () {
      final p = BoardDataProvider();
      final el = BoardElement(type: 'note', x: 0, y: 0);
      p.setElementsForTest([el]);
      p.moveLocal(el, 40, 60);
      expect(p.elements.first.x, 40);
      expect(p.elements.first.y, 60);
      p.dispose();
    });

    test('resizeLocal sin ID actualiza la copia local', () {
      final p = BoardDataProvider();
      final el = BoardElement(type: 'note', width: 100, height: 80);
      p.setElementsForTest([el]);
      p.resizeLocal(el, 240, 180);
      expect(p.elements.first.width, 240);
      expect(p.elements.first.height, 180);
      p.dispose();
    });
  });
}