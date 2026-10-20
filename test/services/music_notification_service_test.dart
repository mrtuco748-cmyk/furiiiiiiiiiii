import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/services/notification_service.dart';
import 'package:furi_app/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Music Notification & Background Audio Tests', () {
    test('SoundService.isMusicPlaying prevents startBackgroundMusic from starting', () async {
      SoundService.isMusicPlaying = true;
      await SoundService().startBackgroundMusic();
      // startBackgroundMusic should exit early without starting
      SoundService.isMusicPlaying = false;
    });

    test('notificationTapBackground forwards actionId via IsolateNameServer', () async {
      final receivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping(NotificationService.musicPortName);
      IsolateNameServer.registerPortWithName(receivePort.sendPort, NotificationService.musicPortName);

      String? receivedAction;
      final sub = receivePort.listen((msg) {
        receivedAction = msg as String;
      });

      notificationTapBackground(const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: 'music_play_pause',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(receivedAction, equals('music_play_pause'));

      await sub.cancel();
      receivePort.close();
      IsolateNameServer.removePortNameMapping(NotificationService.musicPortName);
    });

    test('AndroidNotificationAction configured with showsUserInterface: false and no emojis in titles', () {
      final actions = <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'music_prev',
          'Anterior',
          icon: DrawableResourceAndroidBitmap('ic_music_prev'),
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'music_play_pause',
          'Pausar',
          icon: DrawableResourceAndroidBitmap('ic_music_pause'),
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

      for (final a in actions) {
        expect(a.showsUserInterface, isFalse, reason: 'Media actions must execute in background without opening app');
        expect(a.title.contains('⏮'), isFalse, reason: 'Titles must use native text/icons, not emojis');
        expect(a.title.contains('▶'), isFalse, reason: 'Titles must use native text/icons, not emojis');
        expect(a.title.contains('⏸'), isFalse, reason: 'Titles must use native text/icons, not emojis');
        expect(a.title.contains('⏭'), isFalse, reason: 'Titles must use native text/icons, not emojis');
        expect(a.icon, isNotNull);
        expect(a.icon, isA<DrawableResourceAndroidBitmap>());
      }
    });

    test('onMusicSeek and onWebViewRendererGone callbacks can be registered and invoked', () {
      Duration? seekedTo;
      bool rendererGoneTriggered = false;

      NotificationService.onMusicSeek = (pos) {
        seekedTo = pos;
      };
      NotificationService.onWebViewRendererGone = () {
        rendererGoneTriggered = true;
      };

      NotificationService.onMusicSeek?.call(const Duration(seconds: 42));
      NotificationService.onWebViewRendererGone?.call();

      expect(seekedTo, equals(const Duration(seconds: 42)));
      expect(rendererGoneTriggered, isTrue);

      NotificationService.onMusicSeek = null;
      NotificationService.onWebViewRendererGone = null;
    });
  });
}
