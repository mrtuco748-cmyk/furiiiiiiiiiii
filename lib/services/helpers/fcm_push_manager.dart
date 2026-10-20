import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../app_state.dart';
import '../../supabase_config.dart';
import 'notification_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;
  final msgId = data['message_id'];
  if (msgId != null) {
    final id = int.tryParse(msgId.toString());
    if (id != null) {
      await FcmPushManager.markMessageDelivered(id);
    }
  }
}

class FcmPushManager {
  static StreamSubscription<String>? _tokenRefreshSub;

  static bool get supportsMessaging =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> registerTokenAfterLogin(
      FirebaseMessaging? fcm, bool firebaseAvailable) async {
    if (!firebaseAvailable || fcm == null || !supportsMessaging) return;
    try {
      final token = await fcm.getToken();
      if (token != null) await storeToken(token);

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = fcm.onTokenRefresh.listen((token) {
        storeToken(token);
      });
    } catch (e) {
      debugPrint('FcmPushManager.registerTokenAfterLogin error: $e');
    }
  }

  static Future<void> requestPermission(FirebaseMessaging? fcm) async {
    if (fcm == null) return;
    await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> storeToken(String token) async {
    if (AppState.myId == null) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await SupabaseConfig.client
          .from('device_tokens')
          .delete()
          .eq('token', token)
          .neq('user_id', AppState.myId!);

      final existing = await SupabaseConfig.client
          .from('device_tokens')
          .select('id')
          .eq('user_id', AppState.myId!)
          .eq('token', token)
          .maybeSingle();
      if (existing == null) {
        await SupabaseConfig.client.from('device_tokens').insert({
          'user_id': AppState.myId!,
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'created_at': nowUtc,
        });
      } else {
        await SupabaseConfig.client.from('device_tokens').update({
          'created_at': nowUtc,
        }).eq('id', existing['id']);
      }
    } catch (e) {
      debugPrint('FcmPushManager.storeToken error: $e');
    }
  }

  static Future<void> markMessageDelivered(int messageId) async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await SupabaseConfig.client
          .from('messages')
          .update({'delivered_at': nowUtc})
          .eq('id', messageId)
          .filter('delivered_at', 'is', 'null');
    } catch (e) {
      debugPrint('FcmPushManager.markMessageDelivered error: $e');
    }
  }

  static void listenFCMForeground(
    FirebaseMessaging? fcm,
    void Function(String title, String body, Map<String, dynamic> data)
        onShowInApp,
  ) {
    if (fcm == null) return;
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      final msgId = data['message_id'];
      if (msgId != null) {
        final id = int.tryParse(msgId.toString());
        if (id != null) {
          unawaited(markMessageDelivered(id));
        }
      }

      final title =
          message.notification?.title ?? (data['title'] as String?) ?? '';
      final body =
          message.notification?.body ?? (data['body'] as String?) ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        onShowInApp(title.isNotEmpty ? title : 'F.U.R.I', body, data);
        NotificationRepository.storePushNotification(data, title, body);
      }
    });
  }

  static Future<void> sendPushToPartner({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final partnerId = AppState.partnerId;
    if (partnerId == null || partnerId.isEmpty) return;
    try {
      await SupabaseConfig.client.functions.invoke(
        'send-push',
        body: {
          'user_id': partnerId,
          'title': title,
          'body': body,
          'data': data,
        },
      );
    } catch (e) {
      debugPrint('FcmPushManager.sendPushToPartner error: $e');
    }
  }
}
