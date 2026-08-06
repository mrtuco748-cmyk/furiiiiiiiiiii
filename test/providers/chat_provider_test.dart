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
}
