import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/schedule.dart';
import 'package:furi_app/services/event_notification_service.dart';

void main() {
  Schedule rec(String recurrence, DateTime anchor) => Schedule(
        id: 5,
        title: 'Gym',
        date: anchor,
        startTime: '18:00',
        endTime: '19:00',
        recurrence: recurrence,
      );

  test('un repetido programa la PRÓXIMA ocurrencia, no la del ancla', () {
    final now = DateTime(2026, 10, 14, 12); // miércoles mediodía
    final specs = EventNotificationService.specsForEvent(
        rec('weekly:5', DateTime(2026, 9, 1)), now); // viernes
    expect(specs.map((s) => s.scheduledDate).toList(), [
      DateTime(2026, 10, 16, 17),
      DateTime(2026, 10, 16, 18),
    ]);
  });

  test('si hoy ya pasó la hora, salta a la siguiente ocurrencia', () {
    final now = DateTime(2026, 10, 14, 20);
    final specs = EventNotificationService.specsForEvent(
        rec('every:1', DateTime(2026, 10, 1)), now);
    expect(specs.first.scheduledDate, DateTime(2026, 10, 15, 17));
  });

  test('un único pasado no programa nada', () {
    final now = DateTime(2026, 10, 14, 20);
    final specs =
        EventNotificationService.specsForEvent(rec('', DateTime(2026, 10, 1)), now);
    expect(specs, isEmpty);
  });
}
