import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();
  static DateTime? _lastClickTime;

  Future<void> _play(String asset, {double volume = 1.0}) async {
    final enabled = SettingsService().enableSound;
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> click() async {
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!).inMilliseconds < 150) return;
    _lastClickTime = now;
    HapticFeedback.lightImpact();
    await _play('sounds/click.wav', volume: 0.5);
  }

  Future<void> pop() async {
    HapticFeedback.mediumImpact();
    await _play('sounds/pop.wav');
  }

  Future<void> success() async {
    HapticFeedback.heavyImpact();
    await _play('sounds/success.wav');
  }

  Future<void> swoosh() async {
    HapticFeedback.selectionClick();
    await _play('sounds/swoosh.wav');
  }

  void tick() { HapticFeedback.selectionClick(); }
  Future<void> alert() async { HapticFeedback.heavyImpact(); await _play('sounds/pop.wav'); }
  void dispose() { _player.dispose(); }
}
