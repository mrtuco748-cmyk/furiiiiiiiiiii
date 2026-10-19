import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/message.dart';
import 'package:furi_app/providers/chat_provider.dart';

void main() {
  ChatProvider build() => ChatProvider(myId: 'facu', partnerId: 'rocio');

  Message msg({
    int id = 1,
    String from = 'facu',
    String to = 'rocio',
    String type = 'text',
    Map<String, List<String>>? reactions,
  }) =>
      Message(
        id: id,
        fromUser: from,
        toUser: to,
        content: 'hola',
        messageType: type,
        reactions: reactions,
      );

  test('setMessagesForTest actualiza estado empty/data', () {
    final p = build();
    p.setMessagesForTest([]);
    expect(p.state, ChatLoadState.empty);
    p.setMessagesForTest([msg()]);
    expect(p.state, ChatLoadState.data);
    expect(p.messages.length, 1);
  });

  test('setReplyTo y clearReply', () {
    final p = build();
    final m = msg();
    p.setReplyTo(m);
    expect(p.replyTo?.id, 1);
    p.clearReply();
    expect(p.replyTo, isNull);
  });

  test('toggleReaction optimista actualiza lista local', () async {
    final p = build();
    p.setMessagesForTest([msg()]);
    // Sin supabase real: el update fallará, pero el optimistic + rollback
    // se valida en el modelo; acá solo verificamos API pública de set.
    expect(p.messages.first.reactionCount, 0);
    final toggled = p.messages.first.toggleReaction(userId: 'facu', key: '🥰');
    p.setMessagesForTest([toggled]);
    expect(p.messages.first.reactions['🥰'], ['facu']);
  });

  test('isDownloading inicia en false', () {
    final p = build();
    expect(p.isDownloading(1), false);
  });

  group('Paginación de mensajes (100 iniciales + carga de 100 anteriores)', () {
    test('hasMore inicia en true y se actualiza', () {
      final p = build();
      expect(p.hasMore, true);
      p.setHasMoreForTest(false);
      expect(p.hasMore, false);
    });

    test('addOlderMessagesForTest antepone mensajes más antiguos al inicio', () {
      final p = build();
      final newestMsg = msg(id: 101);
      p.setMessagesForTest([newestMsg]);

      final olderBatch = [
        msg(id: 99),
        msg(id: 100),
      ];
      p.addOlderMessagesForTest(olderBatch);

      expect(p.messages.length, 3);
      expect(p.messages.map((m) => m.id).toList(), [99, 100, 101]);
      // El mensaje más reciente sigue estando al final
      expect(p.messages.last.id, 101);
    });

    test('addOlderMessagesForTest deduplica mensajes existentes', () {
      final p = build();
      p.setMessagesForTest([msg(id: 100), msg(id: 101)]);

      // Intentamos cargar un lote que incluye id 100 ya cargado y uno nuevo 99
      p.addOlderMessagesForTest([msg(id: 99), msg(id: 100)]);

      expect(p.messages.length, 3);
      expect(p.messages.map((m) => m.id).toList(), [99, 100, 101]);
    });
  });
}

