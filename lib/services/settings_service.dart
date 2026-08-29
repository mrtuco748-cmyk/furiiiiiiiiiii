import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  static const _keyEnableSound = 'enableSound';
  static const _keyBgVolume = 'bgVolume';
  static const _keySfxVolume = 'sfxVolume';
  static const _keyAppMode = 'appMode';
  static const _keyHomeShortcut = 'homeShortcut';

  bool _enableSound = true;
  double _bgVolume = 0.5;
  double _sfxVolume = 1.0;
  AppMode _appMode = AppMode.dark;
  String _homeShortcut = 'Mazos';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enableSound = prefs.getBool(_keyEnableSound) ?? true;
    _bgVolume = prefs.getDouble(_keyBgVolume) ?? 0.5;
    _sfxVolume = prefs.getDouble(_keySfxVolume) ?? 1.0;
    final modeName = prefs.getString(_keyAppMode);
    if (modeName != null) {
      _appMode = AppMode.values.firstWhere((e) => e.name == modeName, orElse: () => AppMode.dark);
    }
    _homeShortcut = prefs.getString(_keyHomeShortcut) ?? 'Mazos';
    notifyListeners();
  }

  bool get enableSound => _enableSound;
  double get bgVolume => _bgVolume;
  double get sfxVolume => _sfxVolume;
  AppMode get appMode => _appMode;
  String get homeShortcut => _homeShortcut;

  Future<void> setEnableSound(bool value) async {
    _enableSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableSound, value);
    notifyListeners();
  }

  Future<void> setBgVolume(double value) async {
    _bgVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBgVolume, value);
    notifyListeners();
  }

  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySfxVolume, value);
    notifyListeners();
  }

  Future<void> setAppMode(AppMode value) async {
    _appMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppMode, value.name);
    notifyListeners();
  }

  Future<void> setHomeShortcut(String value) async {
    _homeShortcut = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHomeShortcut, value);
    notifyListeners();
  }
}
