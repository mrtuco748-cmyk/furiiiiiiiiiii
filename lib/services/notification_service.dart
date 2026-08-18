import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../supabase_config.dart';
import '../app_state.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService._handleMessage(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static FirebaseMessaging? _fcm;
  static bool _initialized = false;
  static bool _firebaseAvailable = false;
  static StreamSubscription<String>? _tokenRefreshSub;

  /// Firebase Messaging solo tiene plugin nativo en Android/iOS.
  /// En desktop (Windows, macOS) el MethodChannel no existe y lanza
  /// MissingPluginException; por eso se desactiva fuera de móvil.
  static bool get _supportsMessaging =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static void Function(Map<String, dynamic> data)? onNotificationTap;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _firebaseAvailable = true;
      print('[FURI] Firebase core OK');
    } catch (e) {
      _firebaseAvailable = false;
      print('[FURI] Firebase core error: $e');
    }
    if (_firebaseAvailable && _supportsMessaging) {
      try {
        _fcm = FirebaseMessaging.instance;
        print('[FURI] Firebase messaging OK');
      } catch (e) {
        _firebaseAvailable = false;
        print('[FURI] Firebase messaging error: $e');
      }
    } else {
      _fcm = null;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          onNotificationTap?.call(data);
        }
      },
    );

    if (_firebaseAvailable && _fcm != null) {
      await _requestPermission();
      _listenFCMForeground();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  static Future<void> registerTokenAfterLogin() async {
    if (!_firebaseAvailable || _fcm == null || !_supportsMessaging) return;
    try {
      final token = await _fcm!.getToken();
      if (token != null) await _storeToken(token);

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm!.onTokenRefresh.listen((token) {
        _storeToken(token);
      });
    } catch (e) {
      debugPrint('NotificationService.registerTokenAfterLogin error: $e');
    }
  }

  static Future<void> _requestPermission() async {
    if (_fcm == null) return;
    await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _storeToken(String token) async {
    if (AppState.myId == null) return;
    try {
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
        });
      }
    } catch (e) {
      debugPrint('NotificationService._storeToken error: $e');
    }
  }

  static void _listenFCMForeground() {
    if (_fcm == null) return;
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data.containsKey('type') && message.data['type'] == 'message') {
        return;
      }
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      final data = message.data;
      _showLocalNotification(title, body, data);
    });
  }

  static void _handleMessage(RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    final data = message.data;
    if (title.isNotEmpty || body.isNotEmpty) {
      _showLocalNotification(title, body, data);
    }
  }

  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    if (!_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'furi_notifications',
        'F.U.R.I Notificaciones',
        channelDescription: 'Notificaciones de la app F.U.R.I',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
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

      final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('NotificationService._showLocalNotification error: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    await _showLocalNotification(title, body, data);
  }

  static bool _tzReady = false;

  /// Inicializa la zona horaria del dispositivo para `zonedSchedule`.
  /// Sin esto, `tz.local` queda en UTC y los recordatorios programados se
  /// disparan desfasados. Fallback: ubicación construida con el offset
  /// actual (suficiente para zonas sin DST, como Argentina).
  static Future<void> _ensureTz() async {
    if (_tzReady) return;
    _tzReady = true;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('NotificationService._ensureTz error: $e');
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
        debugPrint('NotificationService._ensureTz fallback error: $e2');
      }
    }
  }

  /// Programa un recordatorio local para una fecha futura.
  /// No-op seguro en desktop (flutter_local_notifications no soporta
  /// zonedSchedule en Windows/Linux).
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_initialized) return;
    try {
      await _ensureTz();
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
      await _localNotifications.zonedSchedule(
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
      debugPrint('NotificationService.scheduleNotification error: $e');
    }
  }

  static Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      debugPrint('NotificationService.cancel error: $e');
    }
  }

  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    if (!_firebaseAvailable) return;
    try {
      await SupabaseConfig.client.functions.invoke(
        'send-push',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data,
        },
      );
    } catch (e) {
      debugPrint('Error sending push: $e');
    }
  }

  static Future<void> storeNotification({
    required String type,
    required String title,
    required String body,
    String? fromUserId,
    Map<String, dynamic> data = const {},
    String? targetUserId,
  }) async {
    final uid = targetUserId ?? AppState.partnerId;
    if (uid == null) return;
    try {
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': uid,
        'from_user': fromUserId ?? AppState.myId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
      });
    } catch (e) {
      debugPrint('NotificationService.storeNotification error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    if (AppState.myId == null) return [];
    try {
      final res = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', AppState.myId!)
          .order('created_at', ascending: false)
          .limit(50);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('NotificationService.getNotifications error: $e');
      return [];
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('NotificationService.markAsRead error: $e');
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
      debugPrint('NotificationService.markAllAsRead error: $e');
    }
  }

  static RealtimeChannel? _globalChannel;
  static VoidCallback? onNewMessage;

  static void startListening() {
    _globalChannel?.unsubscribe();
    if (AppState.myId == null || AppState.partnerId == null) return;

    _globalChannel = SupabaseConfig.client.channel('global-notif-${AppState.myId}');

    _globalChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'to_user', value: AppState.myId!),
        callback: (payload) {
          final content = payload.newRecord['content'] as String? ?? '';
          if (content.isEmpty) return;
          _showLocalNotification('Nuevo mensaje', content, {'type': 'message'});
          onNewMessage?.call();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'from_user', value: AppState.myId!),
        callback: (payload) {},
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final updated = payload.newRecord;
          final reactions = updated['reactions'];
          if (reactions != null && (reactions as Map).isNotEmpty) {
            final fromUser = updated['from_user'] as String? ?? '';
            if (fromUser == AppState.partnerId) {
              _showLocalNotification('Reacción', 'Alguien reaccionó a tu mensaje', {'type': 'reaction'});
            }
          }
        },
      );

    _globalChannel!.subscribe();
  }

  static void stopListening() {
    _globalChannel?.unsubscribe();
    _globalChannel = null;
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
      debugPrint('NotificationService.getUnreadCount error: $e');
      return 0;
    }
  }
}
