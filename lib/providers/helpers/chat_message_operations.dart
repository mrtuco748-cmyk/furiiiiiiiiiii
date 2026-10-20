import 'package:flutter/widgets.dart';

import '../../app_state.dart';
import '../../models/message.dart';
import '../../services/chat_media_service.dart';
import '../../services/notification_service.dart';
import '../../supabase_config.dart';
import 'chat_read_receipts.dart';

class ChatMessageOperations {
  final String myId;
  final String partnerId;
  final ChatMediaService media;
  final List<Message> Function() getMessages;
  final Map<int, String> Function() getLocalPaths;
  final Set<int> downloading;
  final void Function(bool val) setSending;
  final void Function(String? err) setError;
  final void Function() clearReply;
  final VoidCallback onNotify;

  ChatMessageOperations({
    required this.myId,
    required this.partnerId,
    required this.media,
    required this.getMessages,
    required this.getLocalPaths,
    required this.downloading,
    required this.setSending,
    required this.setError,
    required this.clearReply,
    required this.onNotify,
  });

  Future<Message?> insertMessage(Map<String, dynamic> payload) async {
    setSending(true);
    setError(null);
    onNotify();
    try {
      final row = await SupabaseConfig.client
          .from('messages')
          .insert(payload)
          .select()
          .single();
      final msg = Message.fromMap(Map<String, dynamic>.from(row as Map));
      final messages = getMessages();
      if (!messages.any((m) => m.id == msg.id)) {
        messages.add(msg);
      }
      clearReply();
      onNotify();

      if (partnerId.isNotEmpty) {
        final senderName = AppState.myName ?? 'Tu pareja';
        NotificationService.sendPushToPartner(
          title: senderName,
          body: msg.previewText,
          data: {
            'type': 'message',
            'message_id': msg.id.toString(),
            'from_user': myId,
          },
        );
      }

      return msg;
    } catch (e) {
      setError(e.toString());
      onNotify();
      rethrow;
    } finally {
      setSending(false);
      onNotify();
    }
  }

  Future<void> sendMedia({
    required String localPath,
    required String messageType,
    required String fileName,
    String? mimeType,
    int? size,
    String caption = '',
    Message? replyTo,
  }) async {
    if (partnerId.isEmpty) return;
    setSending(true);
    setError(null);
    onNotify();
    try {
      final cached = await media.copyToLocalCache(
        sourcePath: localPath,
        preferredName: fileName,
      );
      final storagePath = await media.uploadFile(
        localPath: cached,
        ownerId: myId,
        fileName: fileName,
      );
      final row = await SupabaseConfig.client
          .from('messages')
          .insert({
            'from_user': myId,
            'to_user': partnerId,
            'content': caption.trim().isEmpty ? fileName : caption.trim(),
            'message_type': messageType,
            'attachment_url': storagePath,
            'attachment_name': fileName,
            'attachment_mime': mimeType,
            'attachment_size': size,
            'cloud_deleted': false,
            if (replyTo != null) 'reply_to_id': replyTo.id,
            if (replyTo != null) 'reply_content': replyTo.previewText,
          })
          .select()
          .single();
      final inserted = Message.fromMap(Map<String, dynamic>.from(row as Map));
      await media.bindLocalPath(
        messageId: inserted.id,
        localPath: cached,
        fileName: fileName,
        mimeType: mimeType,
      );
      final localPaths = getLocalPaths();
      localPaths[inserted.id] = cached;
      final withLocal = inserted.copyWith(localPath: cached);
      final messages = getMessages();
      final idx = messages.indexWhere((m) => m.id == withLocal.id);
      if (idx == -1) {
        messages.add(withLocal);
      } else {
        messages[idx] = withLocal;
      }
      clearReply();
    } catch (e) {
      setError(e.toString());
      onNotify();
      rethrow;
    } finally {
      setSending(false);
      onNotify();
    }
  }

  Future<void> toggleReaction(Message msg, String key) async {
    final next = msg.toggleReaction(userId: myId, key: key);
    if (identical(next, msg) &&
        !msg.canAddReactionKey(key) &&
        msg.myReactionKey(myId) != key) {
      setError('Maximo 5 reacciones por mensaje');
      onNotify();
      return;
    }
    final messages = getMessages();
    final idx = messages.indexWhere((m) => m.id == msg.id);
    if (idx >= 0) {
      messages[idx] = next;
      onNotify();
    }
    try {
      final res = await SupabaseConfig.client.rpc(
        'toggle_reaction',
        params: {
          'target_table': 'messages',
          'target_col': 'reactions',
          'row_id': msg.id,
          'reaction_key': key,
          'user_id': myId,
        },
      );
      if (res != null) {
        final authoritative = Message.parseReactions(res);
        final li = messages.indexWhere((m) => m.id == msg.id);
        if (li >= 0) {
          messages[li] = messages[li].copyWith(reactions: authoritative);
          onNotify();
        }
      }

      final wasAdded = next.myReactionKey(myId) == key;
      if (wasAdded && msg.fromUser != myId && partnerId.isNotEmpty) {
        final preview = msg.previewText.trim();
        final previewSnippet =
            preview.length > 35 ? '${preview.substring(0, 35)}...' : preview;
        final senderName = AppState.myName ?? 'Tu pareja';
        NotificationService.sendPushToPartner(
          title: '$senderName reaccionó $key',
          body: previewSnippet.isNotEmpty
              ? 'A tu mensaje: "$previewSnippet"'
              : 'Reaccionó a tu mensaje',
          data: {
            'type': 'reaction',
            'message_id': msg.id.toString(),
          },
        );
      }
    } catch (e) {
      if (idx >= 0) {
        messages[idx] = msg;
      }
      setError(e.toString());
      onNotify();
    }
  }

  Future<void> downloadMedia(Message msg) async {
    if (!msg.needsCloudDownload || msg.attachmentUrl == null) return;
    if (downloading.contains(msg.id)) return;
    downloading.add(msg.id);
    onNotify();
    try {
      final local = await media.downloadAndKeepLocal(
        messageId: msg.id,
        storagePath: msg.attachmentUrl!,
        fileName: msg.attachmentName,
        mimeType: msg.attachmentMime,
      );
      final localPaths = getLocalPaths();
      localPaths[msg.id] = local;
      final messages = getMessages();
      final idx = messages.indexWhere((m) => m.id == msg.id);
      if (idx >= 0) {
        messages[idx] = messages[idx].copyWith(localPath: local);
      }
      onNotify();

      if (msg.toUser == myId && !msg.cloudDeleted) {
        await media.deleteFromCloud(msg.attachmentUrl!);
        await SupabaseConfig.client.from('messages').update({
          'attachment_url': null,
          'cloud_deleted': true,
        }).eq('id', msg.id);
        if (idx >= 0) {
          messages[idx] = messages[idx].copyWith(
            cloudDeleted: true,
            clearAttachmentUrl: true,
            localPath: local,
          );
        }
        onNotify();
      }
    } catch (e) {
      setError(e.toString());
      onNotify();
    } finally {
      downloading.remove(msg.id);
      onNotify();
    }
  }

  Future<void> markIncomingRead() => ChatReadReceipts.markIncomingRead(
        myId: myId,
        messages: getMessages(),
        onNotify: onNotify,
      );

  Future<void> markIncomingDelivered({Set<int>? onlyThese}) =>
      ChatReadReceipts.markIncomingDelivered(
        myId: myId,
        messages: getMessages(),
        onNotify: onNotify,
        onlyThese: onlyThese,
      );
}
