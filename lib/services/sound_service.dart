import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  static final AudioPlayer _player = AudioPlayer()..audioCache.prefix = '';
  static DateTime? _lastClickTime;
  static DateTime? _lastSwooshTime;

  // Lock para evitar que llamadas concurrentes a _play se superpongan.
  static bool _isPlaying = false;

  static const int _swooshDebounceMs = 400;
  static const int _clickDebounceMs = 150;
  static const int _popDebounceMs = 300;

  // Player dedicado para la música de fondo (loop). Separado de _player para
  // que los SFX cortos no lo interrumpan con su stop().
  static final AudioPlayer _bgPlayer = AudioPlayer()..audioCache.prefix = '';
  static bool _bgStarted = false;
  static const double _bgVolume = 0.5;

  // Contexto de audio para SFX: pide foco "transient may duck" en Android para
  // que, al sonar un click/pop, NO pause la música de fondo (solo la baja un
  // instante) y en iOS mezcle con la música en vez de cortarla. Sin esto,
  // Android le da el foco exclusivo al SFX y pausa el reproductor de fondo.
  static final AudioContext _sfxContext = AudioContext(
    android: AudioContextAndroid(
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  // Contexto de audio para la música de fondo: mantiene el foco y mezcla en iOS.
  static final AudioContext _bgContext = AudioContext(
    android: AudioContextAndroid(
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  // Los calls pasan "sounds/xxx"; la clave real del bundle es "Assets/sounds/xxx".
  static const String _assetPrefix = 'Assets/';

  static String _asset(String name) => '$_assetPrefix$name';

  Future<void> _play(String asset, {double volume = 1.0}) async {
    if (_isPlaying) return;
    final enabled = SettingsService().enableSound;
    if (!enabled) return;
    try {
      _isPlaying = true;
      await _player.stop();
      await _player.setAudioContext(_sfxContext);
      await _player.setVolume(volume * SettingsService().sfxVolume);
      await _player.play(AssetSource(_asset(asset)));
    } catch (_) {}
    _isPlaying = false;
  }

  Future<void> click() async {
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!).inMilliseconds < _clickDebounceMs) return;
    _lastClickTime = now;
    HapticFeedback.lightImpact();
    await _play('sounds/click.wav', volume: 0.5);
  }

  Future<void> pop() async {
    final now = DateTime.now();
    if (_lastSwooshTime != null && now.difference(_lastSwooshTime!).inMilliseconds < _popDebounceMs) return;
    _lastSwooshTime = now;
    HapticFeedback.mediumImpact();
    await _play('sounds/pop.wav');
  }

  Future<void> success() async {
    final now = DateTime.now();
    if (_lastSwooshTime != null && now.difference(_lastSwooshTime!).inMilliseconds < _popDebounceMs) return;
    _lastSwooshTime = now;
    HapticFeedback.heavyImpact();
    await _play('sounds/success.wav');
  }

  Future<void> swoosh() async {
    final now = DateTime.now();
    if (_lastSwooshTime != null && now.difference(_lastSwooshTime!).inMilliseconds < _swooshDebounceMs) return;
    _lastSwooshTime = now;
    HapticFeedback.selectionClick();
    await _play('sounds/swoosh.wav');
  }

  void tick() { HapticFeedback.selectionClick(); }
  Future<void> alert() async {
    final now = DateTime.now();
    if (_lastSwooshTime != null && now.difference(_lastSwooshTime!).inMilliseconds < _popDebounceMs) return;
    _lastSwooshTime = now;
    HapticFeedback.heavyImpact();
    await _play('sounds/pop.wav');
  }

  /// Arranca la música de fondo en bucle (si el sonido está habilitado). Se
  /// vuelve a llamar si se re-enciende el sonido en Configuración.
  Future<void> startBackgroundMusic() async {
    if (_bgStarted) return;
    if (!SettingsService().enableSound) return;
    try {
      _bgStarted = true;
      await _bgPlayer.setAudioContext(_bgContext);
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(SettingsService().bgVolume);
      await _bgPlayer.play(AssetSource(_asset('sounds/musicaDeFondo.mp3')));
    } catch (_) {}
  }

  Future<void> updateBgVolume(double volume) async {
    if (_bgStarted) {
      try {
        await _bgPlayer.setVolume(volume);
      } catch (_) {}
    }
  }

  /// Detiene la música de fondo (toggle "Sonidos" apagado).
  Future<void> stopBackgroundMusic() async {
    _bgStarted = false;
    try { await _bgPlayer.stop(); } catch (_) {}
  }

  void dispose() { _isPlaying = false; _player.dispose(); _bgPlayer.dispose(); }
}
