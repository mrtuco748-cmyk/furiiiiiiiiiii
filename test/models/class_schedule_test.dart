import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/class_schedule.dart';

void main() {
  test('ClassSchedule serializa y deserializa con todos los campos', () {
    final original = ClassSchedule(
      id: 1,
      dayOfWeek: 2,
      classTypeId: 3,
      startTime: '08:00',
      endTime: '10:00',
      title: 'Pastelería 1',
      professor: 'Chef Ana',
      userId: 'Facu',
      color: 0xFF7B2D8E,
    );

    final map = original.toMap();
    expect(map['dayOfWeek'], 2);
    expect(map['startTime'], '08:00');
    expect(map['endTime'], '10:00');
    expect(map['title'], 'Pastelería 1');
    expect(map['professor'], 'Chef Ana');
    expect(map['userId'], 'Facu');
    expect(map['color'], 0xFF7B2D8E);

    final restored = ClassSchedule.fromMap(map);
    expect(restored.id, 1);
    expect(restored.dayOfWeek, 2);
    expect(restored.startTime, '08:00');
    expect(restored.endTime, '10:00');
    expect(restored.title, 'Pastelería 1');
    expect(restored.professor, 'Chef Ana');
    expect(restored.userId, 'Facu');
    expect(restored.color, 0xFF7B2D8E);
  });

  test('ClassSchedule fromMap maneja valores nulos por defecto', () {
    final legacy = ClassSchedule.fromMap({
      'id': 5,
      'dayOfWeek': 3,
      'classTypeId': null,
      'startTime': '14:00',
      'title': 'Gastronomía',
    });

    expect(legacy.endTime, '');
    expect(legacy.professor, '');
    expect(legacy.userId, '');
    expect(legacy.color, 0xFF7B2D8E);
  });

  test('ClassSchedule serializa cloudId y fromMap lo recupera', () {
    final original = ClassSchedule(
      id: 7,
      cloudId: 42,
      dayOfWeek: 2,
      startTime: '08:00',
      title: 'Clase',
    );

    final map = original.toMap();
    expect(map['cloudId'], 42);

    final restored = ClassSchedule.fromMap({'id': 7, 'cloudId': 42, 'dayOfWeek': 2, 'startTime': '08:00', 'title': 'Clase'});
    expect(restored.cloudId, 42);

    final sinCloud = ClassSchedule.fromMap({'id': 7, 'dayOfWeek': 2, 'startTime': '08:00', 'title': 'Clase'});
    expect(sinCloud.cloudId, isNull);
  });

  test('copyWith actualiza cloudId sin tocar el resto', () {
    final original = ClassSchedule(id: 7, dayOfWeek: 2, startTime: '08:00', title: 'Clase');
    final updated = original.copyWith(cloudId: 99);

    expect(updated.cloudId, 99);
    expect(updated.id, 7);
    expect(updated.title, 'Clase');
    expect(updated.dayOfWeek, 2);
  });
}
