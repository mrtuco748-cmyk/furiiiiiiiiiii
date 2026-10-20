import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'music_notification_manager.dart';

class LocalNotificationsInitializer {
  static Future<void> initialize(
    FlutterLocalNotificationsPlugin localNotifications, {
    required void Function(String actionId) onMusicAction,
    required void Function(Map<String, dynamic> data) onNotificationTap,
  }) async {
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification_fox');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId != null && response.actionId!.isNotEmpty) {
          onMusicAction(response.actionId!);
        } else if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          onNotificationTap(data);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidImpl = localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();

        const musicChannel = AndroidNotificationChannel(
          'furi_music_channel',
          'F.U.R.I Música',
          description: 'Controles multimedia de música de F.U.R.I',
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        );
        await androidImpl.createNotificationChannel(musicChannel);
      }
    }
  }
}
