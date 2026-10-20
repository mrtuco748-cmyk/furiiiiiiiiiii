import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../models/music_track.dart';
import '../../services/notification_service.dart';
import '../../services/sound_service.dart';

class MusicAudioController {
  final AudioPlayer player = AudioPlayer();
  final VoidCallback onNotify;
  final void Function() onTrackCompleted;

  MusicAudioController({
    required this.onNotify,
    required this.onTrackCompleted,
  });

  PlayerState playerState = PlayerState.stopped;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isSwitchingTrack = false;
  DateTime _lastNotifProgressSync = DateTime.fromMillisecondsSinceEpoch(0);

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  static final AudioContext mediaAudioContext = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  void init({
    required VoidCallback onPlayPrevious,
    required VoidCallback onTogglePlayPause,
    required VoidCallback onPause,
    required VoidCallback onPlayNext,
    required VoidCallback onStop,
    required MusicTrack? Function() getCurrentTrack,
  }) {
    player.setAudioContext(mediaAudioContext);

    NotificationService.onMusicAction = (actionId) {
      if (actionId == 'music_prev') {
        onPlayPrevious();
      } else if (actionId == 'music_play_pause') {
        onTogglePlayPause();
      } else if (actionId == 'music_play') {
        if (playerState != PlayerState.playing) onTogglePlayPause();
      } else if (actionId == 'music_pause') {
        if (playerState == PlayerState.playing) onPause();
      } else if (actionId == 'music_next') {
        onPlayNext();
      } else if (actionId == 'music_stop') {
        onStop();
      }
    };

    NotificationService.onMusicSeek = (pos) => seek(pos, getCurrentTrack());

    _posSub = player.onPositionChanged.listen((p) {
      position = p;
      onNotify();
      final now = DateTime.now();
      final current = getCurrentTrack();
      if (current != null && now.difference(_lastNotifProgressSync).inMilliseconds >= 1500) {
        _lastNotifProgressSync = now;
        syncNotificationProgress(current);
      }
    });

    _durSub = player.onDurationChanged.listen((d) {
      duration = d;
      onNotify();
      final current = getCurrentTrack();
      if (current != null && d.inMilliseconds > 0) syncNotificationProgress(current);
    });

    _stateSub = player.onPlayerStateChanged.listen((s) {
      if (isSwitchingTrack && (s == PlayerState.stopped || s == PlayerState.completed)) return;
      playerState = s;
      SoundService.isMusicPlaying = (s == PlayerState.playing || s == PlayerState.paused);
      if (s == PlayerState.playing) SoundService().stopBackgroundMusic();
      onNotify();
      final current = getCurrentTrack();
      if (current != null) {
        syncFullNotification(track: current, isPlaying: s == PlayerState.playing);
      } else {
        NotificationService.cancelMusicNotification();
      }
    });

    _completeSub = player.onPlayerComplete.listen((_) => onTrackCompleted());
  }

  int effectiveDurationMs(MusicTrack track) {
    if (duration.inMilliseconds > 0) return duration.inMilliseconds;
    if (track.durationSeconds > 0) return track.durationSeconds * 1000;
    return 0;
  }

  void syncFullNotification({required MusicTrack track, required bool isPlaying}) {
    NotificationService.updateMusicNotification(
      title: track.title,
      artist: track.artist,
      thumbnailUrl: track.thumbnailUrl,
      isPlaying: isPlaying,
      positionMs: position.inMilliseconds,
      durationMs: effectiveDurationMs(track),
    );
  }

  void syncNotificationProgress(MusicTrack track) {
    NotificationService.updateMusicProgress(
      isPlaying: playerState == PlayerState.playing || isSwitchingTrack,
      positionMs: position.inMilliseconds,
      durationMs: effectiveDurationMs(track),
    );
  }

  Future<void> playTrack(MusicTrack track) async {
    isSwitchingTrack = true;
    position = Duration.zero;
    duration = track.durationSeconds > 0 ? Duration(seconds: track.durationSeconds) : Duration.zero;
    playerState = PlayerState.playing;
    SoundService.isMusicPlaying = true;
    SoundService().stopBackgroundMusic();
    syncFullNotification(track: track, isPlaying: true);
    onNotify();

    try {
      await player.setAudioContext(mediaAudioContext);
      Source source;
      if (track.localPath.isNotEmpty && await File(track.localPath).exists()) {
        source = DeviceFileSource(track.localPath);
      } else if (track.audioUrl.isNotEmpty) {
        source = UrlSource(track.audioUrl);
      } else {
        return;
      }
      await player.stop();
      await player.play(source);
    } catch (e) {
      developer.log('MusicAudioController.playTrack error: $e');
    } finally {
      isSwitchingTrack = false;
    }
  }

  Future<void> pause(MusicTrack? track) async {
    await player.pause();
    if (track != null) syncFullNotification(track: track, isPlaying: false);
  }

  Future<void> resume(MusicTrack? track) async {
    await player.setAudioContext(mediaAudioContext);
    SoundService.isMusicPlaying = true;
    SoundService().stopBackgroundMusic();
    await player.resume();
    if (track != null) syncFullNotification(track: track, isPlaying: true);
  }

  Future<void> stop() async {
    isSwitchingTrack = false;
    await player.stop();
    position = Duration.zero;
    SoundService.isMusicPlaying = false;
    NotificationService.cancelMusicNotification();
    onNotify();
  }

  Future<void> seek(Duration pos, MusicTrack? track) async {
    position = pos;
    onNotify();
    await player.seek(pos);
    if (track != null) syncNotificationProgress(track);
  }

  void dispose() {
    NotificationService.cancelMusicNotification();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    player.dispose();
  }
}
