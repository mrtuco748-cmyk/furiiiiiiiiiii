import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  // El AudioCache de audioplayers antepone "assets/" por defecto al resolver
  // el asset por rootBundle. Como este proyecto declara los assets con la ruta
  // real "Assets/sounds/<archivo>.wav" (A mayúscula, preservada tal cual en el
  // bundle), hay que vaciar ese prefijo del cache para que rootBundle.load()
  // reciba la clave exacta. Sin esto buscaba "assets/Assets/sounds/..." →
  // clave inexistente → el catch traga el fallo → silencio en TODAS las
  // plataformas.
  static final AudioPlayer _player = AudioPlayer()..audioCache.prefix = '';
  static DateTime? _lastClickTime;

  // Player dedicado para la música de fondo (loop). Separado de _player para
  // que los SFX cortos no lo interrumpan con su stop().
  static final AudioPlayer _bgPlayer = AudioPlayer()..audioCache.prefix = '';
  static bool _bgStarted = false;
  static const double _bgVolume = 0.4;

  // Los calls pasan "sounds/xxx"; la clave real del bundle es "Assets/sounds/xxx".
  static const String _assetPrefix = 'Assets/';

  static String _asset(String name) => '$_assetPrefix$name';

  Future<void> _play(String asset, {double volume = 1.0}) async {
    final enabled = SettingsService().enableSound;
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource(_asset(asset)));
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

  /// Arranca la música de fondo en bucle (si el sonido está habilitado). Se
  /// vuelve a llamar si se re-enciende el sonido en Configuración.
  Future<void> startBackgroundMusic() async {
    if (_bgStarted) return;
    if (!SettingsService().enableSound) return;
    try {
      _bgStarted = true;
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(_bgVolume);
      await _bgPlayer.play(AssetSource(_asset('sounds/musicaDeFondo.mp3')));
    } catch (_) {}
  }

  /// Detiene la música de fondo (toggle "Sonidos" apagado).
  Future<void> stopBackgroundMusic() async {
    _bgStarted = false;
    try { await _bgPlayer.stop(); } catch (_) {}
  }

  void dispose() { _player.dispose(); _bgPlayer.dispose(); }
}
