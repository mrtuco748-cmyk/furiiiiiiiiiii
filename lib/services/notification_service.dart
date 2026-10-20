import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_state.dart';
import '../firebase_options.dart';
import 'helpers/fcm_push_manager.dart';
import 'helpers/local_notifications_initializer.dart';
import 'helpers/music_notification_manager.dart';
import 'helpers/notification_repository.dart';
import 'helpers/scheduled_notification_service.dart';

export 'helpers/music_notification_manager.dart' show notificationTapBackground;

class InAppNotificationItem {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? fromUser;
  final DateTime timestamp;

  InAppNotificationItem({
    required this.title,
    required this.body,
    this.data = const {},
    this.fromUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static FirebaseMessaging? _fcm;
  static bool _initialized = false;
  static bool _firebaseAvailable = false;

  static final StreamController<InAppNotificationItem>
      _inAppNotificationStream =
      StreamController<InAppNotificationItem>.broadcast();
  static Stream<InAppNotificationItem> get inAppNotificationStream =>
      _inAppNotificationStream.stream;

  static void showInAppNotification(InAppNotificationItem item) {
    if (!_inAppNotificationStream.isClosed) {
      _inAppNotificationStream.add(item);
    }
  }

  static void Function(String actionId)? get onMusicAction =>
      MusicNotificationManager.onMusicAction;
  static set onMusicAction(void Function(String actionId)? fn) =>
      MusicNotificationManager.onMusicAction = fn;

  static void Function(Duration position)? get onMusicSeek =>
      MusicNotificationManager.onMusicSeek;
  static set onMusicSeek(void Function(Duration position)? fn) =>
      MusicNotificationManager.onMusicSeek = fn;

  static VoidCallback? get onWebViewRendererGone =>
      MusicNotificationManager.onWebViewRendererGone;
  static set onWebViewRendererGone(VoidCallback? fn) =>
      MusicNotificationManager.onWebViewRendererGone = fn;

  static const int musicNotificationId =
      MusicNotificationManager.musicNotificationId;
  static const String musicPortName = MusicNotificationManager.musicPortName;

  static void Function(Map<String, dynamic> data)? onNotificationTap;
  static VoidCallback? onNewMessage;
  static VoidCallback? onNewNotification;

  static bool get _supportsMessaging => FcmPushManager.supportsMessaging;

  static Future<void> protectAndroidWebViews() =>
      MusicNotificationManager.protectAndroidWebViews();

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    MusicNotificationManager.ensureMusicChannelInitialized();
    MusicNotificationManager.setupIsolatePort();

    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      _firebaseAvailable = true;
      debugPrint('[FURI] Firebase core OK');
    } catch (e) {
      _firebaseAvailable = false;
      debugPrint('[FURI] Firebase core error: $e');
    }

    if (_firebaseAvailable && _supportsMessaging) {
      try {
        _fcm = FirebaseMessaging.instance;
        debugPrint('[FURI] Firebase messaging OK');
      } catch (e) {
        _firebaseAvailable = false;
        debugPrint('[FURI] Firebase messaging error: $e');
      }
    } else {
      _fcm = null;
    }

    await LocalNotificationsInitializer.initialize(
      _localNotifications,
      onMusicAction: (action) =>
          MusicNotificationManager.onMusicAction?.call(action),
      onNotificationTap: (data) => onNotificationTap?.call(data),
    );

    if (_firebaseAvailable && _fcm != null) {
      await FcmPushManager.requestPermission(_fcm);
      FcmPushManager.listenFCMForeground(_fcm, (title, body, data) {
        showInAppNotification(InAppNotificationItem(
          title: title,
          body: body,
          data: data,
        ));
      });
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);
    }
  }

  static Future<void> registerToken() async => registerTokenAfterLogin();

  static Future<void> registerTokenAfterLogin() async =>
      FcmPushManager.registerTokenAfterLogin(_fcm, _firebaseAvailable);

  static Future<void> markMessageDelivered(int messageId) =>
      FcmPushManager.markMessageDelivered(messageId);

  static Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    showInAppNotification(InAppNotificationItem(
      title: title,
      body: body,
      data: data,
    ));
  }

  static Future<void> updateMusicNotification({
    required String title,
    required String artist,
    required bool isPlaying,
    String thumbnailUrl = '',
    int positionMs = 0,
    int durationMs = 0,
  }) =>
      MusicNotificationManager.updateMusicNotification(
        localNotifications: _localNotifications,
        isInitialized: _initialized,
        title: title,
        artist: artist,
        isPlaying: isPlaying,
        thumbnailUrl: thumbnailUrl,
        positionMs: positionMs,
        durationMs: durationMs,
      );

  static Future<void> updateMusicProgress({
    required bool isPlaying,
    required int positionMs,
    required int durationMs,
  }) =>
      MusicNotificationManager.updateMusicProgress(
        isPlaying: isPlaying,
        positionMs: positionMs,
        durationMs: durationMs,
      );

  static Future<void> cancelMusicNotification() =>
      MusicNotificationManager.cancelMusicNotification(
        localNotifications: _localNotifications,
        isInitialized: _initialized,
      );

  static Future<void> sendPushToPartner({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) =>
      FcmPushManager.sendPushToPartner(
        title: title,
        body: body,
        data: data,
      );

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) =>
      ScheduledNotificationService.scheduleNotification(
        localNotifications: _localNotifications,
        isInitialized: _initialized,
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );

  static Future<void> cancel(int id) =>
      ScheduledNotificationService.cancel(
        localNotifications: _localNotifications,
        isInitialized: _initialized,
        id: id,
      );

  static Future<List<Map<String, dynamic>>> getNotifications() =>
      NotificationRepository.getNotifications();

  static Future<void> markAsRead(int notificationId) =>
      NotificationRepository.markAsRead(notificationId);

  static Future<void> markAllAsRead() =>
      NotificationRepository.markAllAsRead();

  static Future<int> getUnreadCount() =>
      NotificationRepository.getUnreadCount();

  static void startListening() {
    NotificationRepository.startListeningMessages(
      onNewMessageReceived: (msgId, content) {
        if (msgId != null) {
          unawaited(markMessageDelivered(msgId));
        }
        showInAppNotification(InAppNotificationItem(
          title: AppState.partnerName.isNotEmpty
              ? AppState.partnerName
              : 'Nuevo mensaje',
          body: content,
          data: {
            'type': 'message',
            if (msgId != null) 'message_id': msgId.toString(),
          },
        ));
      },
      onNewMessage: () => onNewMessage?.call(),
    );

    registerToken();
    startListeningNotifications();
  }

  static void startListeningNotifications() {
    NotificationRepository.startListeningNotifications(
      onNewNotificationReceived: (title, body, data) {
        showInAppNotification(InAppNotificationItem(
          title: title,
          body: body,
          data: data,
        ));
      },
      onNewNotification: () => onNewNotification?.call(),
    );
  }

  static void stopListening() => NotificationRepository.stopListening();

  static void stopListeningNotifications() =>
      NotificationRepository.stopListeningNotifications();
}
