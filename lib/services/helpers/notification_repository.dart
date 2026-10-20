import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_state.dart';
import '../../supabase_config.dart';
import '../local_cache.dart';

class NotificationRepository {
  static RealtimeChannel? _globalChannel;
  static RealtimeChannel? _notifChannel;

  static Future<void> storePushNotification(
    Map<String, dynamic> data,
    String title,
    String body,
  ) async {
    final type = data['type'] as String? ?? 'notification';
    try {
      final myName = (AppState.myName ?? AppState.identity ?? '')
          .trim()
          .toLowerCase()
          .replaceAll('í', 'i');
      final cleanTitle = title.trim().toLowerCase().replaceAll('í', 'i');

      final bool isAuthoredByMe = myName.isNotEmpty &&
          (cleanTitle == myName ||
              (data['from_user'] != null &&
                  data['from_user'] == AppState.myId));

      final targetUserId =
          isAuthoredByMe ? AppState.partnerId : AppState.myId;
      final senderUserId =
          isAuthoredByMe ? AppState.myId : AppState.partnerId;

      if (targetUserId == null) return;

      await SupabaseConfig.client.from('notifications').insert({
        'user_id': targetUserId,
        'from_user': senderUserId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
      });
    } catch (e) {
      debugPrint('NotificationRepository.storePushNotification error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    if (AppState.myId == null) return [];
    try {
      final res = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', AppState.myId!)
          .order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      await LocalCache.setList('cache_notifications', list);
      return list;
    } catch (e) {
      debugPrint('NotificationRepository.getNotifications error: $e');
      final cached = await LocalCache.getList('cache_notifications');
      return cached;
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('NotificationRepository.markAsRead error: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    if (AppState.myId == null) return;
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', AppState.myId!)
          .eq('read', false);
    } catch (e) {
      debugPrint('NotificationRepository.markAllAsRead error: $e');
    }
  }

  static Future<int> getUnreadCount() async {
    if (AppState.myId == null) return 0;
    try {
      final res = await SupabaseConfig.client
          .from('notifications')
          .select('id')
          .eq('user_id', AppState.myId!)
          .eq('read', false);
      return (res as List).length;
    } catch (e) {
      debugPrint('NotificationRepository.getUnreadCount error: $e');
      return 0;
    }
  }

  static void startListeningMessages({
    required void Function(int? msgId, String content) onNewMessageReceived,
    required VoidCallback onNewMessage,
  }) {
    _globalChannel?.unsubscribe();
    if (AppState.myId == null || AppState.partnerId == null) return;

    _globalChannel =
        SupabaseConfig.client.channel('global-notif-${AppState.myId}');

    _globalChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'to_user',
          value: AppState.myId!,
        ),
        callback: (payload) {
          final rawId = payload.newRecord['id'];
          final msgId =
              rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
          final content = payload.newRecord['content'] as String? ?? '';
          if (content.isEmpty) return;
          onNewMessageReceived(msgId, content);
          onNewMessage();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'from_user',
          value: AppState.myId!,
        ),
        callback: (_) {},
      );

    _globalChannel!.subscribe();
  }

  static void startListeningNotifications({
    required void Function(String title, String body, Map<String, dynamic> data)
        onNewNotificationReceived,
    required VoidCallback onNewNotification,
  }) {
    _notifChannel?.unsubscribe();
    if (AppState.myId == null) return;

    _notifChannel =
        SupabaseConfig.client.channel('notifications-${AppState.myId}');

    _notifChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: AppState.myId!,
        ),
        callback: (payload) {
          developer.log('NotificationRepository: nueva notificación via realtime');
          final record = payload.newRecord;
          final title = record['title'] as String? ?? 'F.U.R.I';
          final body = record['body'] as String? ?? '';
          final data = (record['data'] as Map<String, dynamic>?) ?? {};
          if (title.isNotEmpty || body.isNotEmpty) {
            onNewNotificationReceived(title, body, data);
          }
          onNewNotification();
        },
      )
      .subscribe();
  }

  static void stopListening() {
    _globalChannel?.unsubscribe();
    _globalChannel = null;
  }

  static void stopListeningNotifications() {
    _notifChannel?.unsubscribe();
    _notifChannel = null;
  }
}
