import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/deck_card.dart';
import 'package:furi_app/providers/deck_provider.dart';

void main() {
  late DeckProvider pv;

  setUp(() {
    pv = DeckProvider();
  });

  DeckCard makeCard({
    int? id,
    String category = DeckCategory.ideas,
    String content = 'x',
    Map<String, String> reactions = const {},
  }) =>
      DeckCard(
        id: id,
        category: category,
        content: content,
        reactions: reactions,
      );

  test('pendingFor filtra cartas sin reaccion del usuario', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'rocio-uuid': DeckReaction.encanta}),
      makeCard(id: 2, reactions: {'facu-uuid': DeckReaction.meh}),
      makeCard(id: 3),
    ]);
    final pending = pv.pendingFor('facu-uuid');
    expect(pending.map((c) => c.id), containsAll([1, 3]));
    expect(pending.length, 2);
  });

  test('historyFor filtra cartas ya deslizadas por el usuario', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'rocio-uuid': DeckReaction.encanta}),
      makeCard(id: 2, reactions: {'facu-uuid': DeckReaction.meh}),
      makeCard(id: 3),
    ]);
    final history = pv.historyFor('facu-uuid');
    expect(history.length, 1);
    expect(history.first.id, 2);
  });

  test('pendingFor con userId null devuelve todas', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'rocio-uuid': DeckReaction.encanta}),
      makeCard(id: 2),
    ]);
    expect(pv.pendingFor(null).length, 2);
  });

  test('matches y matchCount cuentan cartas con ambos encanta', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {
        'facu-uuid': DeckReaction.encanta,
        'rocio-uuid': DeckReaction.encanta,
      }),
      makeCard(id: 2, reactions: {
        'facu-uuid': DeckReaction.encanta,
        'rocio-uuid': DeckReaction.meh,
      }),
      makeCard(id: 3, reactions: {'facu-uuid': DeckReaction.encanta}),
    ]);
    expect(pv.matchCount, 1);
    expect(pv.matches.first.id, 1);
  });

  test('reactLocal actualiza la reaccion sin pisar la de la pareja', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'rocio-uuid': DeckReaction.encanta}),
    ]);
    pv.reactLocal(pv.cards.first, DeckReaction.meGusta, 'facu-uuid');
    final card = pv.cards.first;
    expect(card.reactionOf('rocio-uuid'), DeckReaction.encanta);
    expect(card.reactionOf('facu-uuid'), DeckReaction.meGusta);
  });

  test('reactLocal setea pendingMatch cuando completa el match', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'rocio-uuid': DeckReaction.encanta}),
    ]);
    pv.reactLocal(pv.cards.first, DeckReaction.encanta, 'facu-uuid');
    expect(pv.pendingMatch, isNotNull);
    expect(pv.pendingMatch!.id, 1);
  });

  test('reactLocal no setea pendingMatch sin match', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'rocio-uuid': DeckReaction.encanta}),
    ]);
    pv.reactLocal(pv.cards.first, DeckReaction.meh, 'facu-uuid');
    expect(pv.pendingMatch, isNull);
  });

  test('applyCloudCards mergea las reacciones locales', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'facu-uuid': DeckReaction.encanta}),
    ]);
    final result = pv.applyCloudCards([
      makeCard(id: 1, reactions: {'rocio-uuid': DeckReaction.meGusta}),
    ]);
    expect(result.first.reactions['facu-uuid'], DeckReaction.encanta);
    expect(result.first.reactions['rocio-uuid'], DeckReaction.meGusta);
  });

  test('applyCloudCards detecta match traido por realtime', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'facu-uuid': DeckReaction.encanta}),
    ]);
    pv.applyCloudCards([
      makeCard(id: 1, reactions: {
        'facu-uuid': DeckReaction.encanta,
        'rocio-uuid': DeckReaction.encanta,
      }),
    ]);
    expect(pv.pendingMatch, isNotNull);
    expect(pv.pendingMatch!.id, 1);
  });

  test('applyCloudCards no repite pendingMatch si local ya era match', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {
        'facu-uuid': DeckReaction.encanta,
        'rocio-uuid': DeckReaction.encanta,
      }),
    ]);
    pv.consumeMatch();
    pv.applyCloudCards([
      makeCard(id: 1, reactions: {
        'facu-uuid': DeckReaction.encanta,
        'rocio-uuid': DeckReaction.encanta,
      }),
    ]);
    expect(pv.pendingMatch, isNull);
  });

  test('consumeMatch limpia el pendingMatch', () {
    pv.setCardsForTest([
      makeCard(id: 1, reactions: {'rocio-uuid': DeckReaction.encanta}),
    ]);
    pv.reactLocal(pv.cards.first, DeckReaction.encanta, 'facu-uuid');
    expect(pv.pendingMatch, isNotNull);
    pv.consumeMatch();
    expect(pv.pendingMatch, isNull);
  });

  test('clearError limpia el error', () {
    pv.setCardsForTest([]);
    pv.clearError();
    expect(pv.hasError, isFalse);
  });
}
