import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/class_schedule.dart';
import 'package:furi_app/services/class_notification_service.dart';

void main() {
  ClassSchedule make({int? id, int day = 1, String start = '08:00'}) =>
      ClassSchedule(
        id: id,
        dayOfWeek: day,
        startTime: start,
        title: 'Matematica',
      );

  group('ClassNotificationService.nextOccurrence', () {
    test('clase de mañana cae mañana a la misma hora', () {
      final now = DateTime(2026, 8, 17, 9, 0); // lunes
      final next = ClassNotificationService.nextOccurrence(
          make(day: 2), now); // martes
      expect(next, DateTime(2026, 8, 18, 8, 0));
    });

    test('clase de hoy antes de empezar cae hoy', () {
      final now = DateTime(2026, 8, 17, 7, 0); // lunes 7am, clase lunes 8am
      expect(
        ClassNotificationService.nextOccurrence(make(day: 1), now),
        DateTime(2026, 8, 17, 8, 0),
      );
    });

    test('clase de hoy ya pasada cae la proxima semana', () {
      final now = DateTime(2026, 8, 17, 9, 30);
      expect(
        ClassNotificationService.nextOccurrence(make(day: 1), now),
        DateTime(2026, 8, 24, 8, 0),
      );
    });

    test('domingo a lunes salta 1 dia y no 6', () {
      final now = DateTime(2026, 8, 23, 12, 0); // domingo
      expect(
        ClassNotificationService.nextOccurrence(make(day: 1), now),
        DateTime(2026, 8, 24, 8, 0),
      );
    });

    test('vuelta completa de domingo a domingo', () {
      final now = DateTime(2026, 8, 23, 12, 0); // domingo
      expect(
        ClassNotificationService.nextOccurrence(make(day: 7), now),
        DateTime(2026, 8, 30, 8, 0),
      );
    });
  });

  group('ClassNotificationService.specsForClass', () {
    test('genera el recordatorio 1h antes de la proxima ocurrencia', () {
      final now = DateTime(2026, 8, 17, 6, 0); // lunes 6am, clase lunes 8am
      final specs = ClassNotificationService.specsForClass(make(id: 3), now);
      expect(specs.length, 1);
      expect(specs.first.id, 200003);
      expect(specs.first.scheduledDate, DateTime(2026, 8, 17, 7, 0));
      expect(specs.first.body, contains('1 hora'));
    });

    test('clase sin id no genera recordatorios', () {
      final specs = ClassNotificationService.specsForClass(
        make(id: null),
        DateTime(2026, 8, 17, 6, 0),
      );
      expect(specs, isEmpty);
    });

    test('clase sin hora valida no rompe ni genera recordatorios', () {
      final specs = ClassNotificationService.specsForClass(
        make(start: ''),
        DateTime(2026, 8, 17, 6, 0),
      );
      expect(specs, isEmpty);
    });
  });
}
