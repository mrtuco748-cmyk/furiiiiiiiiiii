import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final actionId = notificationResponse.actionId;
  if (actionId != null && actionId.isNotEmpty) {
    final sendPort = IsolateNameServer.lookupPortByName(
        MusicNotificationManager.musicPortName);
    if (sendPort != null) {
      sendPort.send(actionId);
    }
  }
}

class MusicNotificationManager {
  static const int musicNotificationId = 99999;
  static const String musicPortName = 'furi_music_isolate_port';

  static void Function(String actionId)? onMusicAction;
  static void Function(Duration position)? onMusicSeek;
  static VoidCallback? onWebViewRendererGone;

  static ReceivePort? _musicReceivePort;
  static const MethodChannel _musicServiceChannel =
      MethodChannel('com.furiapp.furi_app/music_service');
  static bool _musicChannelInitialized = false;

  static bool get supportsMessaging =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static void ensureMusicChannelInitialized() {
    if (_musicChannelInitialized || kIsWeb || !Platform.isAndroid) return;
    _musicChannelInitialized = true;
    _musicServiceChannel.setMethodCallHandler((call) async {
      if (call.method == 'onMusicAction') {
        final args = call.arguments;
        if (args is Map) {
          final actionId = args['actionId']?.toString();
          final posRaw = args['positionMs'];
          if (actionId == 'webview_renderer_gone') {
            onWebViewRendererGone?.call();
          } else if (actionId == 'music_seek' && posRaw is num) {
            onMusicSeek?.call(Duration(milliseconds: posRaw.toInt()));
          } else if (actionId != null && actionId.isNotEmpty) {
            onMusicAction?.call(actionId);
          }
        }
      }
    });
  }

  static void setupIsolatePort() {
    try {
      _musicReceivePort?.close();
      _musicReceivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping(musicPortName);
      IsolateNameServer.registerPortWithName(
          _musicReceivePort!.sendPort, musicPortName);
      _musicReceivePort!.listen((message) {
        if (message is String) {
          onMusicAction?.call(message);
        }
      });
    } catch (e) {
      debugPrint('MusicNotificationManager isolate port setup error: $e');
    }
  }

  static Future<void> protectAndroidWebViews() async {
    if (kIsWeb || !Platform.isAndroid) return;
    ensureMusicChannelInitialized();
    try {
      await _musicServiceChannel.invokeMethod('protectWebViews');
    } catch (e) {
      debugPrint('MusicNotificationManager.protectAndroidWebViews error: $e');
    }
  }

  static Future<void> updateMusicNotification({
    required FlutterLocalNotificationsPlugin localNotifications,
    required bool isInitialized,
    required String title,
    required String artist,
    required bool isPlaying,
    String thumbnailUrl = '',
    int positionMs = 0,
    int durationMs = 0,
  }) async {
    if (!supportsMessaging) return;
    if (Platform.isAndroid) {
      ensureMusicChannelInitialized();
      try {
        await _musicServiceChannel.invokeMethod('updateMediaState', {
          'title': title,
          'artist': artist.isNotEmpty ? artist : 'F.U.R.I Música',
          'thumbnailUrl': thumbnailUrl,
          'isPlaying': isPlaying,
          'positionMs': positionMs,
          'durationMs': durationMs,
        });
        return;
      } catch (e) {
        debugPrint('MusicNotificationManager updateMediaState fallback: $e');
      }
    }

    if (!isInitialized) return;
    try {
      final actions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'music_prev',
          'Anterior',
          icon: DrawableResourceAndroidBitmap('ic_music_prev'),
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'music_play_pause',
          isPlaying ? 'Pausar' : 'Reproducir',
          icon: DrawableResourceAndroidBitmap(
              isPlaying ? 'ic_music_pause' : 'ic_music_play'),
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'music_next',
          'Siguiente',
          icon: DrawableResourceAndroidBitmap('ic_music_next'),
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ];

      final androidDetails = AndroidNotificationDetails(
        'furi_media_playback_v3',
        'F.U.R.I Reproductor de Música',
        channelDescription:
            'Controles de reproducción y barra de progreso de música de F.U.R.I',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: isPlaying,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: false,
        actions: actions,
        category: AndroidNotificationCategory.transport,
        color: const Color(0xFF00F0FF),
        playSound: false,
        enableVibration: false,
        visibility: NotificationVisibility.public,
      );

      await localNotifications.show(
        musicNotificationId,
        title,
        artist.isNotEmpty ? artist : 'F.U.R.I Música',
        NotificationDetails(android: androidDetails),
        payload: jsonEncode({'type': 'music'}),
      );
    } catch (e) {
      debugPrint('MusicNotificationManager.updateMusicNotification error: $e');
    }
  }

  static Future<void> updateMusicProgress({
    required bool isPlaying,
    required int positionMs,
    required int durationMs,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    ensureMusicChannelInitialized();
    try {
      await _musicServiceChannel.invokeMethod('updateMediaProgress', {
        'isPlaying': isPlaying,
        'positionMs': positionMs,
        'durationMs': durationMs,
      });
    } catch (e) {
      debugPrint('MusicNotificationManager.updateMusicProgress error: $e');
    }
  }

  static Future<void> cancelMusicNotification({
    required FlutterLocalNotificationsPlugin localNotifications,
    required bool isInitialized,
  }) async {
    if (!supportsMessaging) return;
    if (Platform.isAndroid) {
      ensureMusicChannelInitialized();
      try {
        await _musicServiceChannel.invokeMethod('stopMediaService');
      } catch (e) {
        debugPrint('MusicNotificationManager.stopMediaService error: $e');
      }
    }
    if (!isInitialized) return;
    try {
      await localNotifications.cancel(musicNotificationId);
    } catch (e) {
      debugPrint('MusicNotificationManager.cancelMusicNotification error: $e');
    }
  }
}
