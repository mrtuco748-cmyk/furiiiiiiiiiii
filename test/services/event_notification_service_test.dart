import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/schedule.dart';
import 'package:furi_app/services/event_notification_service.dart';

void main() {
  Schedule make({int? id, DateTime? date, String start = '10:00'}) => Schedule(
        id: id,
        title: 'Examen',
        date: date ?? DateTime(2026, 8, 20),
        startTime: start,
        endTime: '11:00',
        type: 'Examen',
      );

  group('EventNotificationService.specsForEvent', () {
    test('evento futuro genera 2 recordatorios: 1h antes y al empezar', () {
      final now = DateTime(2026, 8, 19, 12, 0);
      final specs = EventNotificationService.specsForEvent(
        make(id: 5, date: DateTime(2026, 8, 20), start: '10:00'),
        now,
      );
      expect(specs.length, 2);
      expect(specs[0].id, 100005);
      expect(specs[0].scheduledDate, DateTime(2026, 8, 20, 9, 0));
      expect(specs[0].body, contains('1 hora'));
      expect(specs[1].id, 100006);
      expect(specs[1].scheduledDate, DateTime(2026, 8, 20, 10, 0));
    });

    test('evento que empieza en 30 min solo genera el recordatorio al empezar',
        () {
      final now = DateTime(2026, 8, 20, 9, 30);
      final specs = EventNotificationService.specsForEvent(
        make(id: 5, date: DateTime(2026, 8, 20), start: '10:00'),
        now,
      );
      expect(specs.map((s) => s.id), [100006]);
    });

    test('evento ya pasado no genera recordatorios', () {
      final now = DateTime(2026, 8, 21, 12, 0);
      final specs = EventNotificationService.specsForEvent(
        make(id: 5, date: DateTime(2026, 8, 20), start: '10:00'),
        now,
      );
      expect(specs, isEmpty);
    });

    test('evento sin id no genera recordatorios', () {
      final specs = EventNotificationService.specsForEvent(
        make(id: null, date: DateTime(2026, 8, 20)),
        DateTime(2026, 8, 19),
      );
      expect(specs, isEmpty);
    });

    test('hora invalida no rompe ni genera recordatorios', () {
      final specs = EventNotificationService.specsForEvent(
        make(id: 5, start: 'nada'),
        DateTime(2026, 8, 19),
      );
      expect(specs, isEmpty);
    });
  });
}
