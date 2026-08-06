import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/message.dart';

void main() {
  Message base({
    Map<String, List<String>>? reactions,
    int? replyToId,
    String messageType = 'text',
    String? attachmentUrl,
  }) =>
      Message(
        id: 1,
        fromUser: 'facu',
        toUser: 'rocio',
        content: 'hola',
        replyToId: replyToId,
        messageType: messageType,
        attachmentUrl: attachmentUrl,
        reactions: reactions,
      );

  test('fromMap parsea reply_to_id int y reactions JSONB', () {
    final msg = Message.fromMap({
      'id': 42,
      'from_user': 'facu',
      'to_user': 'rocio',
      'content': 'hola',
      'reply_to_id': 7,
      'reply_content': 'previo',
      'message_type': 'image',
      'attachment_url': 'facu/a.jpg',
      'attachment_name': 'a.jpg',
      'attachment_mime': 'image/jpeg',
      'cloud_deleted': false,
      'reactions': {
        '🥰': ['facu'],
        'xD': ['rocio', 'facu'],
      },
      'created_at': '2026-08-05T12:00:00.000Z',
    });

    expect(msg.id, 42);
    expect(msg.replyToId, 7);
    expect(msg.replyContent, 'previo');
    expect(msg.messageType, 'image');
    expect(msg.attachmentUrl, 'facu/a.jpg');
    expect(msg.attachmentName, 'a.jpg');
    expect(msg.attachmentMime, 'image/jpeg');
    expect(msg.cloudDeleted, false);
    expect(msg.reactions['🥰'], ['facu']);
    expect(msg.reactions['xD'], ['rocio', 'facu']);
  });

  test('fromMap tolera id string y reply_to_id null', () {
    final msg = Message.fromMap({
      'id': '99',
      'from_user': 'a',
      'to_user': 'b',
      'content': 'x',
    });
    expect(msg.id, 99);
    expect(msg.replyToId, isNull);
    expect(msg.reactions, isEmpty);
    expect(msg.messageType, 'text');
  });

  test('toMap serializa campos de media y reacciones', () {
    final map = base(
      replyToId: 3,
      messageType: 'video',
      attachmentUrl: 'path/v.mp4',
      reactions: {
        '😍': ['facu'],
      },
    ).copyWith(
      replyContent: 'cita',
      attachmentName: 'v.mp4',
      attachmentMime: 'video/mp4',
    ).toMap();

    expect(map['reply_to_id'], 3);
    expect(map['reply_content'], 'cita');
    expect(map['message_type'], 'video');
    expect(map['attachment_url'], 'path/v.mp4');
    expect(map['attachment_name'], 'v.mp4');
    expect(map['attachment_mime'], 'video/mp4');
    expect(map['reactions'], {
      '😍': ['facu'],
    });
  });
test('defaultReactionEmojis son los 6 pedidos', () {

    expect(Message.defaultReactionEmojis, ['🥰', '😘', '😍', ':v', 'xD', ':0']);
  });

  test('toggleReaction agrega reaccion nueva', () {
    final next = base().toggleReaction(userId: 'facu', key: '🥰');
    expect(next.reactions['🥰'], ['facu']);
    expect(next.reactionCount, 1);
  });

  test('toggleReaction quita si ya reacciono con la misma', () {
    final msg = base(reactions: {
      '🥰': ['facu'],
    });
    final next = msg.toggleReaction(userId: 'facu', key: '🥰');
    expect(next.reactions.containsKey('🥰'), false);
    expect(next.reactionCount, 0);
  });

  test('toggleReaction mueve la reaccion del usuario a otra key', () {
    final msg = base(reactions: {
      '🥰': ['facu', 'rocio'],
    });
    final next = msg.toggleReaction(userId: 'facu', key: 'xD');
    expect(next.reactions['🥰'], ['rocio']);
    expect(next.reactions['xD'], ['facu']);
  });

  test('toggleReaction no agrega 6ta key distinta (max 5)', () {
    final msg = base(reactions: {
      'a': ['u1'],
      'b': ['u2'],
      'c': ['u3'],
      'd': ['u4'],
      'e': ['u5'],
    });
    final next = msg.toggleReaction(userId: 'facu', key: 'nueva');
    expect(next.reactions.length, 5);
    expect(next.reactions.containsKey('nueva'), false);
    expect(next.canAddReactionKey('nueva'), false);
  });

  test('toggleReaction permite unirse a key existente aunque haya 5', () {
    final msg = base(reactions: {
      'a': ['u1'],
      'b': ['u2'],
      'c': ['u3'],
      'd': ['u4'],
      '🥰': ['rocio'],
    });
    final next = msg.toggleReaction(userId: 'facu', key: '🥰');
    expect(next.reactions['🥰'], ['rocio', 'facu']);
    expect(next.reactions.length, 5);
  });

  test('reactionCount cuenta keys distintas', () {
    final msg = base(reactions: {
      '🥰': ['facu', 'rocio'],
      'xD': ['facu'],
    });
    expect(msg.reactionCount, 2);
  });

  test('myReactionKey devuelve la reaccion del usuario', () {
    final msg = base(reactions: {
      '😘': ['rocio'],
      'xD': ['facu'],
    });
    expect(msg.myReactionKey('facu'), 'xD');
    expect(msg.myReactionKey('rocio'), '😘');
    expect(msg.myReactionKey('otro'), isNull);
  });

  test('isMedia distingue tipos de adjunto', () {
    expect(base(messageType: 'text').isMedia, false);
    expect(base(messageType: 'image').isMedia, true);
    expect(base(messageType: 'video').isMedia, true);
    expect(base(messageType: 'voice').isMedia, true);
    expect(base(messageType: 'gif').isMedia, true);
    expect(base(messageType: 'document').isMedia, true);
  });

  test('needsCloudDownload cuando hay url y no cloud_deleted', () {
    final pending = base(
      messageType: 'image',
      attachmentUrl: 'facu/x.jpg',
    );
    expect(pending.needsCloudDownload, true);

    final done = pending.copyWith(cloudDeleted: true, clearAttachmentUrl: true);
    expect(done.needsCloudDownload, false);
    expect(done.attachmentUrl, isNull);
  });

  test('previewText para reply banner segun tipo', () {
    expect(base(messageType: 'text').copyWith(content: 'hola').previewText, 'hola');
    expect(
      base(messageType: 'image').copyWith(content: '').previewText,
      'Imagen',
    );
    expect(
      base(messageType: 'image').copyWith(content: 'atardecer').previewText,
      'atardecer',
    );
    expect(
      base(messageType: 'voice').copyWith(content: '').previewText,
      'Audio',
    );
    expect(
      base(messageType: 'video').copyWith(content: '').previewText,
      'Video',
    );
    expect(base(messageType: 'gif').copyWith(content: '').previewText, 'GIF');
    expect(
      base(messageType: 'document')
          .copyWith(attachmentName: 'cv.pdf', content: '')
          .previewText,
      'cv.pdf',
    );
  });
}
