import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/recurrence.dart';

void main() {
  group('Recurrence parse/encode', () {
    test('vacío o basura = evento único', () {
      expect(Recurrence.parse('').kind, RecurrenceKind.none);
      expect(Recurrence.parse('cualquier cosa').kind, RecurrenceKind.none);
      expect(Recurrence.none.encode(), '');
    });

    test('ida y vuelta de todos los tipos', () {
      for (final raw in ['weekly:1,3,5', 'every:3', 'monthly', 'yearly']) {
        expect(Recurrence.parse(raw).encode(), raw);
      }
    });

    test('weekly ordena días y descarta inválidos', () {
      final r = Recurrence.parse('weekly:5,1,9,0,3');
      expect(r.weekdays, {1, 3, 5});
      expect(r.encode(), 'weekly:1,3,5');
    });

    test('weekly sin días válidos = único', () {
      expect(Recurrence.parse('weekly:').kind, RecurrenceKind.none);
    });

    test('every con intervalo < 1 = único', () {
      expect(Recurrence.parse('every:0').kind, RecurrenceKind.none);
    });
  });

  group('occursOn', () {
    final anchor = DateTime(2026, 10, 14); // miércoles

    test('único: solo el día ancla', () {
      expect(Recurrence.none.occursOn(anchor, DateTime(2026, 10, 14)), isTrue);
      expect(Recurrence.none.occursOn(anchor, DateTime(2026, 10, 15)), isFalse);
    });

    test('nunca antes del ancla', () {
      final r = Recurrence.weekly({1, 2, 3, 4, 5, 6, 7});
      expect(r.occursOn(anchor, DateTime(2026, 10, 13)), isFalse);
      expect(r.occursOn(anchor, DateTime(2026, 10, 14)), isTrue);
    });

    test('semanal: solo los días marcados', () {
      final r = Recurrence.weekly({1, 3}); // lunes y miércoles
      expect(r.occursOn(anchor, DateTime(2026, 10, 19)), isTrue); // lunes
      expect(r.occursOn(anchor, DateTime(2026, 10, 21)), isTrue); // miércoles
      expect(r.occursOn(anchor, DateTime(2026, 10, 20)), isFalse); // martes
    });

    test('cada N días', () {
      final r = Recurrence.everyNDays(3);
      expect(r.occursOn(anchor, DateTime(2026, 10, 17)), isTrue);
      expect(r.occursOn(anchor, DateTime(2026, 10, 18)), isFalse);
      // cruza el cambio de mes sin errores de horario de verano
      expect(r.occursOn(anchor, DateTime(2026, 11, 1)), isTrue); // 18 días
      expect(r.occursOn(anchor, DateTime(2026, 11, 2)), isFalse); // 19 días
    });

    test('mensual: mismo día del mes', () {
      final r = Recurrence.monthly();
      expect(r.occursOn(anchor, DateTime(2026, 11, 14)), isTrue);
      expect(r.occursOn(anchor, DateTime(2026, 11, 15)), isFalse);
    });

    test('mensual del 31: cae el último día en meses cortos', () {
      final r = Recurrence.monthly();
      final a = DateTime(2026, 1, 31);
      expect(r.occursOn(a, DateTime(2026, 2, 28)), isTrue);
      expect(r.occursOn(a, DateTime(2026, 4, 30)), isTrue);
      expect(r.occursOn(a, DateTime(2026, 4, 29)), isFalse);
    });

    test('anual: mismo día y mes', () {
      final r = Recurrence.yearly();
      final cumple = DateTime(2026, 5, 22);
      expect(r.occursOn(cumple, DateTime(2027, 5, 22)), isTrue);
      expect(r.occursOn(cumple, DateTime(2027, 5, 23)), isFalse);
    });

    test('anual del 29/2: cae el 28/2 en años no bisiestos', () {
      final r = Recurrence.yearly();
      final a = DateTime(2028, 2, 29);
      expect(r.occursOn(a, DateTime(2029, 2, 28)), isTrue);
      expect(r.occursOn(a, DateTime(2032, 2, 29)), isTrue);
      expect(r.occursOn(a, DateTime(2032, 2, 28)), isFalse);
    });
  });

  group('nextOnOrAfter', () {
    test('devuelve la próxima ocurrencia desde una fecha', () {
      final r = Recurrence.weekly({1}); // lunes
      final next = r.nextOnOrAfter(DateTime(2026, 10, 14), DateTime(2026, 10, 15));
      expect(next, DateTime(2026, 10, 19));
    });

    test('único ya pasado = null', () {
      expect(
        Recurrence.none.nextOnOrAfter(DateTime(2026, 10, 1), DateTime(2026, 10, 2)),
        isNull,
      );
    });

    test('antes del ancla devuelve el ancla', () {
      final r = Recurrence.yearly();
      expect(
        r.nextOnOrAfter(DateTime(2026, 12, 1), DateTime(2026, 10, 1)),
        DateTime(2026, 12, 1),
      );
    });
  });
}
