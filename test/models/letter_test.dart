import 'package:flutter_test/flutter_test.dart';

import 'package:furi_app/models/letter.dart';

void main() {
  final now = DateTime(2026, 8, 26, 10);

  group('Letter.isSealed', () {
    test('sin fecha programada nunca está sellada', () {
      expect(Letter.isSealed(scheduledOpen: null, isIncoming: true, now: now), isFalse);
    });

    test('carta recibida con apertura futura está sellada', () {
      expect(
        Letter.isSealed(scheduledOpen: now.add(const Duration(days: 2)), isIncoming: true, now: now),
        isTrue,
      );
    });

    test('carta recibida con apertura ya pasada no está sellada', () {
      expect(
        Letter.isSealed(scheduledOpen: now.subtract(const Duration(days: 1)), isIncoming: true, now: now),
        isFalse,
      );
    });

    test('la carta propia (enviada) nunca está sellada aunque tenga fecha futura', () {
      expect(
        Letter.isSealed(scheduledOpen: now.add(const Duration(days: 2)), isIncoming: false, now: now),
        isFalse,
      );
    });
  });

  group('Letter', () {
    test('fromMap parsea scheduled_open null y no nulo', () {
      final a = Letter.fromMap(const {'id': 1, 'from_user': 'a', 'to_user': 'b', 'title': 't', 'content': 'c', 'scheduled_open': null});
      expect(a.scheduledOpen, isNull);

      final b = Letter.fromMap({'id': 2, 'from_user': 'a', 'to_user': 'b', 'title': 't', 'content': 'c', 'scheduled_open': '2026-09-01T10:00:00.000Z'});
      expect(b.scheduledOpen, DateTime.utc(2026, 9, 1, 10));
    });
  });
}