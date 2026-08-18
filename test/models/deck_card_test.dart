import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/deck_card.dart';

void main() {
  group('DeckCard', () {
    test('serializa a Map con snake_case y reacciones', () {
      final card = DeckCard(
        id: 7,
        category: DeckCategory.chistes,
        content: 'Un chiste',
        createdBy: 'facu-uuid',
        reactions: {'rocio-uuid': DeckReaction.encanta},
        createdAt: DateTime.utc(2026, 8, 17, 10),
        updatedAt: DateTime.utc(2026, 8, 17, 11),
      );

      final map = card.toMap();

      expect(map['id'], 7);
      expect(map['category'], DeckCategory.chistes);
      expect(map['content'], 'Un chiste');
      expect(map['created_by'], 'facu-uuid');
      expect(map['reactions'], {'rocio-uuid': DeckReaction.encanta});
      expect(map['created_at'], '2026-08-17T10:00:00.000Z');
      expect(map['updated_at'], '2026-08-17T11:00:00.000Z');
    });

    test('fromMap parsea reacciones JSONB y usa defaults', () {
      final card = DeckCard.fromMap({
        'id': 3,
        'category': 'poemas',
        'content': 'Roses are red',
        'created_by': 'rocio-uuid',
        'reactions': {'facu-uuid': 'meh', 'rocio-uuid': 'encanta'},
        'created_at': '2026-08-17T10:00:00.000Z',
        'updated_at': '2026-08-17T11:00:00.000Z',
      });

      expect(card.id, 3);
      expect(card.category, 'poemas');
      expect(card.content, 'Roses are red');
      expect(card.createdBy, 'rocio-uuid');
      expect(card.reactions['facu-uuid'], 'meh');
      expect(card.reactions['rocio-uuid'], 'encanta');
      expect(card.createdAt, DateTime.utc(2026, 8, 17, 10));
    });

    test('fromMap tolera reacciones nulas y timestamps ausentes', () {
      final card = DeckCard.fromMap({
        'id': 1,
        'category': 'random',
        'content': 'hola',
        'reactions': null,
      });

      expect(card.reactions, isEmpty);
      expect(card.createdBy, isNull);
      expect(card.updatedAt, isNotNull);
    });

    test('fromMap tolera reacciones con valores no string', () {
      final card = DeckCard.fromMap({
        'reactions': {'a': 1, 'b': 'encanta'},
      });

      expect(card.reactions, {'b': 'encanta'});
    });

    test('reactionOf devuelve la reaccion del usuario o null', () {
      final card = DeckCard(
        reactions: {'facu-uuid': DeckReaction.meGusta},
      );

      expect(card.reactionOf('facu-uuid'), DeckReaction.meGusta);
      expect(card.reactionOf('rocio-uuid'), isNull);
      expect(card.reactionOf(null), isNull);
    });

    test('withReaction agrega/actualiza sin mutar el original', () {
      final card = DeckCard(
        id: 1,
        category: DeckCategory.ideas,
        content: 'idea',
        reactions: {'rocio-uuid': DeckReaction.meh},
        createdAt: DateTime.utc(2026, 8, 17),
        updatedAt: DateTime.utc(2026, 8, 17),
      );

      final updated = card.withReaction('facu-uuid', DeckReaction.encanta);

      expect(updated.reactions['facu-uuid'], DeckReaction.encanta);
      expect(updated.reactions['rocio-uuid'], DeckReaction.meh);
      expect(card.reactions.containsKey('facu-uuid'), isFalse);
      expect(updated.createdAt, card.createdAt);
      expect(updated.createdBy, card.createdBy);
    });

    test('mergedReactions preserva las reacciones locales', () {
      final local = DeckCard(
        reactions: {'facu-uuid': DeckReaction.encanta},
      );
      final cloud = DeckCard(
        reactions: {'rocio-uuid': DeckReaction.meGusta},
      );

      final merged = local.mergedReactions(cloud.reactions);

      expect(merged['facu-uuid'], DeckReaction.encanta);
      expect(merged['rocio-uuid'], DeckReaction.meGusta);
    });

    test('mergedReactions: la reaccion local pisa a la cloud para el mismo user', () {
      final local = DeckCard(
        reactions: {'facu-uuid': DeckReaction.encanta},
      );

      final merged = local.mergedReactions({'facu-uuid': DeckReaction.meh});

      expect(merged['facu-uuid'], DeckReaction.encanta);
    });

    test('isMatch: ambos encanta es match', () {
      final card = DeckCard(
        reactions: {
          'facu-uuid': DeckReaction.encanta,
          'rocio-uuid': DeckReaction.encanta,
        },
      );

      expect(card.isMatch, isTrue);
    });

    test('isMatch: una sola reaccion no es match', () {
      final card = DeckCard(
        reactions: {'facu-uuid': DeckReaction.encanta},
      );

      expect(card.isMatch, isFalse);
    });

    test('isMatch: encanta + meh no es match', () {
      final card = DeckCard(
        reactions: {
          'facu-uuid': DeckReaction.encanta,
          'rocio-uuid': DeckReaction.meh,
        },
      );

      expect(card.isMatch, isFalse);
    });

    test('categorias conocidas tienen valores unicos', () {
      expect(DeckCategory.all.toSet().length, DeckCategory.all.length);
      expect(DeckCategory.all.length, 8);
    });
  });
}
