import 'package:flutter_test/flutter_test.dart';

import 'package:furi_app/models/deck_card.dart';
import 'package:furi_app/models/deck_memory.dart';

void main() {
  DeckCard m({int? id, DateTime? at}) => DeckCard(
        id: id,
        category: DeckCategory.ideas,
        content: 'c$id',
        reactions: {'facu': DeckReaction.encanta, 'rocio': DeckReaction.encanta},
        updatedAt: at ?? DateTime(2026, 8, 20),
      );
  DeckCard notMatch({int? id}) => DeckCard(
        id: id,
        category: DeckCategory.ideas,
        content: 'x$id',
        reactions: {'facu': DeckReaction.encanta},
        updatedAt: DateTime(2026, 8, 21),
      );

  group('DeckMemory.latestMatch', () {
    test('devuelve el match más reciente', () {
      final cards = [
        m(id: 1, at: DateTime(2026, 8, 10)),
        notMatch(id: 2),
        m(id: 3, at: DateTime(2026, 8, 25)),
        m(id: 4, at: DateTime(2026, 8, 18)),
      ];
      final latest = DeckMemory.latestMatch(cards);
      expect(latest?.id, 3);
    });

    test('null cuando no hay matches', () {
      expect(DeckMemory.latestMatch([notMatch(id: 1)]), isNull);
      expect(DeckMemory.latestMatch([]), isNull);
    });
  });

  group('DeckMemory.firstMatch', () {
    test('devuelve el match más antiguo', () {
      final cards = [
        m(id: 1, at: DateTime(2026, 8, 10)),
        m(id: 2, at: DateTime(2026, 8, 25)),
        m(id: 3, at: DateTime(2026, 8, 5)),
      ];
      final first = DeckMemory.firstMatch(cards);
      expect(first?.id, 3);
    });

    test('null cuando no hay matches', () {
      expect(DeckMemory.firstMatch([]), isNull);
    });
  });

  group('DeckMemory.matchesInMonth', () {
    test('cuenta matches del mes indicado', () {
      final cards = [
        m(id: 1, at: DateTime(2026, 8, 5)),
        m(id: 2, at: DateTime(2026, 8, 20)),
        notMatch(id: 3),
        m(id: 4, at: DateTime(2026, 9, 1)),
      ];
      expect(DeckMemory.matchesInMonth(cards, DateTime(2026, 8)), 2);
      expect(DeckMemory.matchesInMonth(cards, DateTime(2026, 9)), 1);
      expect(DeckMemory.matchesInMonth(cards, DateTime(2026, 10)), 0);
    });
  });

  group('DeckMemory.summary', () {
    test('descripcion legible del match', () {
      final s = DeckMemory.summary(m(id: 1, at: DateTime(2026, 8, 20)));
      expect(s, contains('20'));
      expect(s, isNotEmpty);
    });
  });
}