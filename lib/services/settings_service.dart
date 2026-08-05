import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  static const _keyEnableSound = 'enableSound';
  bool _enableSound = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enableSound = prefs.getBool(_keyEnableSound) ?? true;
  }

  bool get enableSound => _enableSound;

  Future<void> setEnableSound(bool value) async {
    _enableSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableSound, value);
  }
}
