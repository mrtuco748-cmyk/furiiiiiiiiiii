import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ScheduledNotificationService {
  static bool _tzReady = false;

  static Future<void> ensureTz() async {
    if (_tzReady) return;
    _tzReady = true;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('ScheduledNotificationService.ensureTz error: $e');
      try {
        tzdata.initializeTimeZones();
        final offset = DateTime.now().timeZoneOffset;
        tz.setLocalLocation(tz.Location(
          'device-local',
          [tz.minTime],
          [0],
          [tz.TimeZone(offset.inSeconds, isDst: false, abbreviation: 'loc')],
        ));
      } catch (e2) {
        debugPrint(
            'ScheduledNotificationService.ensureTz fallback error: $e2');
      }
    }
  }

  static Future<void> scheduleNotification({
    required FlutterLocalNotificationsPlugin localNotifications,
    required bool isInitialized,
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!isInitialized) return;
    try {
      await ensureTz();
      if (!scheduledDate.isAfter(DateTime.now())) return;
      const androidDetails = AndroidNotificationDetails(
        'furi_notifications',
        'F.U.R.I Notificaciones',
        channelDescription: 'Notificaciones de la app F.U.R.I',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_notification_fox',
        color: Color(0xFFFF7A00),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      debugPrint(
          'ScheduledNotificationService.scheduleNotification error: $e');
    }
  }

  static Future<void> cancel({
    required FlutterLocalNotificationsPlugin localNotifications,
    required bool isInitialized,
    required int id,
  }) async {
    if (!isInitialized) return;
    try {
      await localNotifications.cancel(id);
    } catch (e) {
      debugPrint('ScheduledNotificationService.cancel error: $e');
    }
  }
}
