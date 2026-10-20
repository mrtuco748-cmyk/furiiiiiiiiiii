import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';

import '../../models/message.dart';
import '../../supabase_config.dart';

class ChatReadReceipts {
  static Future<void> markIncomingRead({
    required String myId,
    required List<Message> messages,
    required VoidCallback onNotify,
  }) async {
    final unread = messages
        .where((m) => m.toUser == myId && !m.read)
        .map((m) => m.id)
        .toList();
    if (unread.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await SupabaseConfig.client.from('messages').update({
        'read': true,
        'read_at': now,
        'delivered_at': now,
      }).inFilter('id', unread);
      for (var i = 0; i < messages.length; i++) {
        if (unread.contains(messages[i].id)) {
          messages[i] = messages[i].copyWith(
            read: true,
            readAt: DateTime.now(),
            deliveredAt: messages[i].deliveredAt ?? DateTime.now(),
          );
        }
      }
      onNotify();
    } catch (e) {
      developer.log('markIncomingRead fallo: $e');
    }
  }

  static Future<void> markIncomingDelivered({
    required String myId,
    required List<Message> messages,
    required VoidCallback onNotify,
    Set<int>? onlyThese,
  }) async {
    final undelivered = (onlyThese ??
            messages
                .where((m) => m.toUser == myId && m.deliveredAt == null)
                .map((m) => m.id)
                .toList())
        .toList();
    if (undelivered.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await SupabaseConfig.client.from('messages').update({
        'delivered_at': now,
      }).inFilter('id', undelivered);
      for (var i = 0; i < messages.length; i++) {
        if (undelivered.contains(messages[i].id)) {
          messages[i] = messages[i].copyWith(deliveredAt: DateTime.now());
        }
      }
      onNotify();
    } catch (e) {
      developer.log('markIncomingDelivered fallo: $e');
    }
  }
}
