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
}
