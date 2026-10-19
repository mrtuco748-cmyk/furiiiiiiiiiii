import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'sound_service.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  static const _keyEnableSound = 'enableSound';
  static const _keyBgVolume = 'bgVolume';
  static const _keySfxVolume = 'sfxVolume';
  static const _keyAppMode = 'appMode';
  static const _keyHomeShortcut = 'homeShortcut';
  static const _keyAutoPlaySwap = 'autoPlaySwap';
  static const _keyZenMode = 'zenMode';
  static const _keyBlockWeight = 'blockWeight';
  static const _keyCustomThemeColors = 'customThemeColors';

  bool _enableSound = true;
  double _bgVolume = 0.10;
  double _sfxVolume = 1.0;
  AppMode _appMode = AppMode.dark;
  String _homeShortcut = 'Mazos';
  bool _autoPlaySwap = false;
  bool _zenMode = false;
  double _blockWeight = 1.0;
  Map<String, Map<String, int>> _customThemeColors = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enableSound = prefs.getBool(_keyEnableSound) ?? true;
    _bgVolume = prefs.getDouble(_keyBgVolume) ?? 0.10;
    _sfxVolume = prefs.getDouble(_keySfxVolume) ?? 1.0;
    final modeName = prefs.getString(_keyAppMode);
    if (modeName != null) {
      _appMode = AppMode.values.firstWhere((e) => e.name == modeName, orElse: () => AppMode.dark);
    }
    _homeShortcut = prefs.getString(_keyHomeShortcut) ?? 'Mazos';
    _autoPlaySwap = prefs.getBool(_keyAutoPlaySwap) ?? false;
    _zenMode = prefs.getBool(_keyZenMode) ?? false;
    _blockWeight = prefs.getDouble(_keyBlockWeight) ?? 1.0;

    final customRaw = prefs.getString(_keyCustomThemeColors);
    if (customRaw != null && customRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(customRaw) as Map<String, dynamic>;
        _customThemeColors = decoded.map((k, v) => MapEntry(
          k,
          (v as Map<String, dynamic>).map((bk, val) => MapEntry(bk, (val as num).toInt())),
        ));
      } catch (_) {}
    }
    notifyListeners();
  }

  bool get enableSound => _enableSound;
  double get bgVolume => _bgVolume;
  double get sfxVolume => _sfxVolume;
  AppMode get appMode => _appMode;
  String get homeShortcut => _homeShortcut;
  bool get autoPlaySwap => _autoPlaySwap;
  bool get zenMode => _zenMode;
  double get blockWeight => _blockWeight;

  Future<void> setEnableSound(bool value) async {
    _enableSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableSound, value);
    notifyListeners();
  }

  Future<void> setBgVolume(double value) async {
    _bgVolume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBgVolume, _bgVolume);
    SoundService().updateBgVolume(_bgVolume);
    notifyListeners();
  }

  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySfxVolume, _sfxVolume);
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

  Future<void> setAutoPlaySwap(bool value) async {
    _autoPlaySwap = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPlaySwap, value);
    notifyListeners();
  }

  Future<void> setZenMode(bool value) async {
    _zenMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyZenMode, value);
    notifyListeners();
  }

  Future<void> setBlockWeight(double value) async {
    _blockWeight = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBlockWeight, value);
    notifyListeners();
  }

  ThemeSet getCustomTheme(AppMode mode, ThemeSet base) {
    final modeMap = _customThemeColors[mode.name];
    if (modeMap == null || modeMap.isEmpty) return base;
    return base.copyWith(
      a: modeMap['a'] != null ? Color(modeMap['a']!) : null,
      b: modeMap['b'] != null ? Color(modeMap['b']!) : null,
      c: modeMap['c'] != null ? Color(modeMap['c']!) : null,
      d: modeMap['d'] != null ? Color(modeMap['d']!) : null,
      e: modeMap['e'] != null ? Color(modeMap['e']!) : null,
      dark: modeMap['dark'] != null ? Color(modeMap['dark']!) : null,
      light: modeMap['light'] != null ? Color(modeMap['light']!) : null,
      mid: modeMap['mid'] != null ? Color(modeMap['mid']!) : null,
    );
  }

  Color? getCustomColor(AppMode mode, String blockKey) {
    final modeMap = _customThemeColors[mode.name];
    if (modeMap != null && modeMap.containsKey(blockKey)) {
      return Color(modeMap[blockKey]!);
    }
    return null;
  }

  Future<void> setCustomColor(AppMode mode, String blockKey, Color color) async {
    _customThemeColors.putIfAbsent(mode.name, () => {});
    _customThemeColors[mode.name]![blockKey] = color.toARGB32();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomThemeColors, jsonEncode(_customThemeColors));
    notifyListeners();
  }

  Future<void> resetThemeColors(AppMode mode) async {
    _customThemeColors.remove(mode.name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomThemeColors, jsonEncode(_customThemeColors));
    notifyListeners();
  }

  bool isThemeCustomized(AppMode mode) {
    final modeMap = _customThemeColors[mode.name];
    return modeMap != null && modeMap.isNotEmpty;
  }
}
