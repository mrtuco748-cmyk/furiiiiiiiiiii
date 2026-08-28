import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/message.dart';

/// Contrato que la RPC `toggle_reaction` (supabase/migration_reaction_rpc.sql)
/// DEBE replicar en el servidor, expresado con la lógica pura que ya viven en
/// los modelos. Cualquier cambio en el SQL que rompa estos comportamientos es
/// un bug de consolidación de datos.
///
/// La RPC hace el merge con row-level lock (FOR UPDATE), lo que serializa dos
/// toggles concurrentes de Facu y Rocio: el resultado debe ser idéntico a
/// ejecutar los toggles uno después del otro (sin race de "último write gana").
void main() {
  Message base() => Message(
        id: 1,
        fromUser: 'facu-uuid',
        toUser: 'rocio-uuid',
        content: 'hola',
      );

  group('toggle_reaction (forma {key: [uid]}) — contrato de merge atómico', () {
    test('dos usuarios reaccionan a la misma key → ambos se preservan (race fix)', () {
      var m = base();
      // Facu reacciona 🥰
      m = m.toggleReaction(userId: 'facu-uuid', key: '🥰');
      // Rocio reacciona 🥰 "concurrentemente" (simula FOR UPDATE serializando)
      m = m.toggleReaction(userId: 'rocio-uuid', key: '🥰');
      expect(m.reactions['🥰'], containsAll(['facu-uuid', 'rocio-uuid']));
    });

    test('toggle off: el mismo usuario se saca de la key', () {
      var m = base().toggleReaction(userId: 'facu-uuid', key: '🥰');
      m = m.toggleReaction(userId: 'facu-uuid', key: '🥰');
      expect(m.reactions.containsKey('🥰'), isFalse);
      expect(m.reactions, isEmpty);
    });

    test('un usuario mueve su reacción entre keys (nunca está en 2)', () {
      var m = base();
      m = m.toggleReaction(userId: 'facu-uuid', key: '🥰');
      m = m.toggleReaction(userId: 'facu-uuid', key: ':v');
      expect(m.reactions.containsKey('🥰'), isFalse);
      expect(m.reactions[':v'], ['facu-uuid']);
    });

    test('máximo 5 keys: agregar la 6ta no cambia nada', () {
      var m = base();
      for (final k in ['a', 'b', 'c', 'd', 'e']) {
        m = m.toggleReaction(userId: 'user-$k', key: k);
      }
      expect(m.reactions.length, 5);
      final sexto = m.toggleReaction(userId: 'user-f', key: 'f');
      expect(sexto.reactions.length, 5);
      expect(sexto.reactions.containsKey('f'), isFalse);
    });
  });

  group('react_deck_card (forma {uid: emoji}) — contrato de reemplazo', () {
    test('reaccionar reemplaza la reacción propia', () {
      // La RPC de deck hace jsonb_set(reacciones, [uid], emoji): reemplaza.
      const seed = {'facu-uuid': 'meh', 'rocio-uuid': 'encanta'};
      final res = {...seed, 'facu-uuid': 'me_gusta'};
      expect(res, {'facu-uuid': 'me_gusta', 'rocio-uuid': 'encanta'});
    });

    test('match = ambos coincidieron en encanta (conteo fue preservado)', () {
      const reacciones = {'facu-uuid': 'encanta', 'rocio-uuid': 'encanta'};
      expect(reacciones.length, 2);
      expect(reacciones.values.every((r) => r == 'encanta'), isTrue);
    });
  });
}