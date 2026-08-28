import 'package:flutter_test/flutter_test.dart';

import 'package:furi_app/models/couple_stats.dart';

void main() {
  final d = DateTime(2026, 8, 20);
  DateTime dd(int daysFromBase) => d.add(Duration(days: daysFromBase));

  group('CoupleActivity.fromMap', () {
    test('parsea user_id y la fecha al día', () {
      final a = CoupleActivity.fromMap({'user_id': 'facu', 'date': '2026-08-20'});
      expect(a.userId, 'facu');
      expect(a.day, DateTime(2026, 8, 20));
    });

    test('tolerante a fecha null o user vacío', () {
      final a = CoupleActivity.fromMap({'user_id': '', 'date': null});
      expect(a.userId, '');
      expect(a.day, isNotNull);
    });
  });

  group('CoupleStats.activeByDay', () {
    test('agrupa por día y usuario', () {
      final m = CoupleStats.activeByDay([
        CoupleActivity(userId: 'facu', day: dd(0)),
        CoupleActivity(userId: 'rocio', day: dd(0)),
        CoupleActivity(userId: 'facu', day: dd(1)),
      ]);
      expect(m[dd(0)], {'facu', 'rocio'});
      expect(m[dd(1)], {'facu'});
    });

    test('actividades vacías → mapa vacío', () {
      expect(CoupleStats.activeByDay([]), isEmpty);
    });
  });

  group('CoupleStats.bothActiveDays', () {
    test('solo cuenta días donde TODOS los miembros están activos', () {
      final m = CoupleStats.activeByDay([
        CoupleActivity(userId: 'facu', day: dd(0)),
        CoupleActivity(userId: 'rocio', day: dd(0)),
        CoupleActivity(userId: 'facu', day: dd(1)),
      ]);
      final both = CoupleStats.bothActiveDays(m, members: {'facu', 'rocio'});
      expect(both, {dd(0)});
    });

    test('ignora usuarios fuera de members', () {
      final m = CoupleStats.activeByDay([
        CoupleActivity(userId: 'extra', day: dd(0)),
        CoupleActivity(userId: 'facu', day: dd(0)),
      ]);
      final both = CoupleStats.bothActiveDays(m, members: {'facu', 'rocio'});
      expect(both, isEmpty);
    });
  });

  group('CoupleStats.streakFor', () {
    test('0 cuando no hay ningún día compartido', () {
      expect(CoupleStats.streakFor({}, today: dd(0)), 0);
    });

    test('cuenta días consecutivos terminando hoy', () {
      final days = {dd(0), dd(-1), dd(-2)};
      expect(CoupleStats.streakFor(days, today: dd(0)), 3);
    });

    test('si hoy aún no hay, cuenta terminando ayer', () {
      final days = {dd(-1), dd(-2), dd(-3)};
      expect(CoupleStats.streakFor(days, today: dd(0)), 3);
    });

    test('se corta por una brecha', () {
      final days = {dd(0), dd(-1), dd(-3), dd(-4)};
      expect(CoupleStats.streakFor(days, today: dd(0)), 2);
    });

    test('0 si ni hoy ni ayer están activos', () {
      final days = {dd(-3), dd(-4)};
      expect(CoupleStats.streakFor(days, today: dd(0)), 0);
    });
  });

  group('CoupleStats.bestStreak', () {
    test('racha más larga de la serie', () {
      final days = {dd(0), dd(-1), dd(-2), dd(-6), dd(-7)};
      expect(CoupleStats.bestStreak(days), 3);
    });

    test('0 sin días', () {
      expect(CoupleStats.bestStreak({}), 0);
    });
  });

  group('CoupleStats.isBothActiveOn', () {
    test('true/false según el día', () {
      final days = {dd(0)};
      expect(CoupleStats.isBothActiveOn(days, dd(0)), isTrue);
      expect(CoupleStats.isBothActiveOn(days, dd(-1)), isFalse);
    });
  });
}