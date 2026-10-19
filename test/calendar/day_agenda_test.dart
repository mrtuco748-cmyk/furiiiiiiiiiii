import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/class_schedule.dart';
import 'package:furi_app/models/schedule.dart';
import 'package:furi_app/screens/calendar/day_agenda.dart';

Schedule _s(String title, DateTime date, String start,
        {String recurrence = '', int id = 1}) =>
    Schedule(
      id: id,
      title: title,
      date: date,
      startTime: start,
      endTime: '',
      type: 'Evento',
      recurrence: recurrence,
      userId: 'Facu',
    );

ClassSchedule _c(String title, int dow, String start, {int id = 1}) =>
    ClassSchedule(
      id: id,
      dayOfWeek: dow,
      startTime: start,
      endTime: '10:00',
      title: title,
      userId: 'Rocio',
    );

void main() {
  final wed = DateTime(2026, 10, 14); // miércoles

  test('mezcla únicos, repetidos y clases viejas ordenados por hora', () {
    final items = DayAgenda.forDay(
      schedules: [
        _s('Cena', wed, '21:00', id: 1),
        _s('Gym', DateTime(2026, 10, 1), '07:30', recurrence: 'every:1', id: 2),
      ],
      classes: [_c('Mate', 3, '09:00')],
      day: wed,
    );
    expect(items.map((e) => e.title).toList(), ['Gym', 'Mate', 'Cena']);
    expect(items[0].recurring, isTrue);
    expect(items[1].recurring, isTrue);
    expect(items[1].legacyClass, isNotNull);
    expect(items[2].recurring, isFalse);
  });

  test('no incluye eventos de otros días ni repetidos que no tocan', () {
    final items = DayAgenda.forDay(
      schedules: [
        _s('Otro día', DateTime(2026, 10, 15), '10:00'),
        _s('Solo lunes', DateTime(2026, 10, 1), '10:00', recurrence: 'weekly:1'),
      ],
      classes: [_c('Jueves', 4, '09:00')],
      day: wed,
    );
    expect(items, isEmpty);
  });

  test('hora vacía o rara va al final sin romper', () {
    final items = DayAgenda.forDay(
      schedules: [_s('Sin hora', wed, '', id: 1), _s('Temprano', wed, '08:00', id: 2)],
      classes: const [],
      day: wed,
    );
    expect(items.map((e) => e.title).toList(), ['Temprano', 'Sin hora']);
  });

  test('legacyGroup junta las filas de la misma clase en varios días', () {
    final classes = [
      _c('Mate', 1, '09:00', id: 1),
      _c('Mate', 3, '09:00', id: 2),
      _c('Física', 3, '09:00', id: 3),
    ];
    final group = DayAgenda.legacyGroup(classes, classes[1]);
    expect(group.map((c) => c.id).toSet(), {1, 2});
  });
}
