import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/message.dart';
import '../../supabase_config.dart';

class ChatMessageSyncResult {
  final List<Message> messages;
  final bool hasMore;

  const ChatMessageSyncResult({
    required this.messages,
    required this.hasMore,
  });
}

class ChatMessageSync {
  static Future<ChatMessageSyncResult> fetchInitialMessages({
    required String myId,
    required Map<int, String> localPaths,
    required List<Message> currentMessages,
  }) async {
    final data = await SupabaseConfig.client
        .from('messages')
        .select('*')
        .or('from_user.eq.$myId,to_user.eq.$myId')
        .order('created_at', ascending: false)
        .limit(100);
    final newestFirst = List<Map<String, dynamic>>.from(data as List);
    final hasMore = newestFirst.length >= 100;
    final fetched = newestFirst.reversed.map((row) {
      final id = Message.fromMap(row).id;
      return Message.fromMap(row, localPath: localPaths[id]);
    }).toList();

    final byId = <int, Message>{};
    for (final m in currentMessages) {
      byId[m.id] = m;
    }
    for (final m in fetched) {
      byId[m.id] = m;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(0))
          .compareTo(b.createdAt ?? DateTime(0)));

    return ChatMessageSyncResult(messages: merged, hasMore: hasMore);
  }

  static Future<ChatMessageSyncResult?> fetchOlderMessages({
    required String myId,
    required DateTime oldest,
    required Map<int, String> localPaths,
    required Set<int> existingIds,
  }) async {
    try {
      final data = await SupabaseConfig.client
          .from('messages')
          .select('*')
          .or('from_user.eq.$myId,to_user.eq.$myId')
          .lt('created_at', oldest.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(100);
      final rows = List<Map<String, dynamic>>.from(data as List);
      final hasMore = rows.length >= 100;
      final older = rows.reversed
          .map((row) {
            final m = Message.fromMap(row);
            return m.copyWith(localPath: localPaths[m.id]);
          })
          .where((m) => !existingIds.contains(m.id))
          .toList();
      return ChatMessageSyncResult(
        messages: older,
        hasMore: older.isEmpty ? false : hasMore,
      );
    } catch (e) {
      developer.log('fetchOlderMessages error: $e');
      return null;
    }
  }

  static RealtimeChannel subscribeMessages({
    required String myId,
    required Map<int, String> localPaths,
    required void Function(Message msg) onInsert,
    required void Function(Message msg) onUpdate,
  }) {
    return SupabaseConfig.client
        .channel('chat-$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            final msg = Message.fromMap(
              row,
              localPath: localPaths[Message.fromMap(row).id],
            );
            if (msg.fromUser != myId && msg.toUser != myId) return;
            onInsert(msg);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            final updated = Message.fromMap(row);
            onUpdate(updated);
          },
        )
        .subscribe();
  }
}
