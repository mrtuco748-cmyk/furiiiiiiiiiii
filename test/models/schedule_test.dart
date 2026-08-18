import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/schedule.dart';

void main() {
  test('Schedule serializa y deserializa con todos los campos', () {
    final original = Schedule(
      id: 1,
      cloudId: 42,
      title: 'Examen',
      description: 'Parcial',
      date: DateTime(2026, 8, 20),
      startTime: '10:00',
      endTime: '12:00',
      location: 'Aula 3',
      instructor: 'Prof X',
      type: 'Examen',
      color: 0xFFFF5757,
      userId: 'Facu',
      createdAt: DateTime(2026, 8, 1, 9),
      updatedAt: DateTime(2026, 8, 2, 9),
    );

    final map = original.toMap();
    expect(map['id'], 1);
    expect(map['cloudId'], 42);
    expect(map['userId'], 'Facu');

    final restored = Schedule.fromMap(map);
    expect(restored.id, 1);
    expect(restored.cloudId, 42);
    expect(restored.title, 'Examen');
    expect(restored.userId, 'Facu');
    expect(restored.color, 0xFFFF5757);
  });

  test('toSupabaseMap usa user_id snake_case y no manda id local', () {
    final s = Schedule(
      id: 7,
      cloudId: 99,
      title: 'Salida',
      date: DateTime(2026, 8, 20),
      startTime: '20:00',
      endTime: '22:00',
      userId: 'Rocio',
      color: 0xFF7B2D8E,
    );

    final map = s.toSupabaseMap();
    expect(map.containsKey('id'), isFalse);
    expect(map.containsKey('cloudId'), isFalse);
    expect(map['user_id'], 'Rocio');
    expect(map['date'], '2026-08-20');
    expect(map['color'], 0xFF7B2D8E);
  });

  test('fromCloudRow mapea el id del servidor a cloudId y user_id a userId',
      () {
    final s = Schedule.fromCloudRow({
      'id': 123,
      'title': 'Cena',
      'description': '',
      'date': '2026-08-14',
      'startTime': '21:00',
      'endTime': '23:00',
      'location': '',
      'instructor': '',
      'type': 'Cita',
      'color': 4286262670,
      'user_id': 'Facu',
      'createdAt': '2026-08-14T10:00:00.000Z',
      'updatedAt': '2026-08-14T10:00:00.000Z',
    });

    expect(s.cloudId, 123);
    expect(s.id, isNull);
    expect(s.userId, 'Facu');
    expect(s.color, 4286262670);
    expect(s.date, DateTime(2026, 8, 14));
  });

  test('fromMap maneja filas legacy sin cloudId ni userId', () {
    final s = Schedule.fromMap({
      'id': 5,
      'title': 'Viejo',
      'date': '2026-08-10T00:00:00.000',
      'startTime': '08:00',
      'endTime': '10:00',
      'createdAt': '2026-08-01T00:00:00.000',
      'updatedAt': '2026-08-01T00:00:00.000',
    });

    expect(s.cloudId, isNull);
    expect(s.userId, '');
    expect(s.description, '');
    expect(s.color, 0xFF7B2D8E);
  });

  test('copyWith preserva cloudId al cambiar otros campos', () {
    final s = Schedule(
      id: 3,
      cloudId: 77,
      title: 'A',
      date: DateTime(2026, 8, 20),
      startTime: '10:00',
      endTime: '11:00',
    );
    final updated = s.copyWith(title: 'B');

    expect(updated.title, 'B');
    expect(updated.cloudId, 77);
    expect(updated.id, 3);
  });
}
