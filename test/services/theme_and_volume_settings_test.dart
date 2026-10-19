import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/services/settings_service.dart';
import 'package:furi_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService & Theme Customization Tests', () {
    test('Default music volume (bgVolume) is 0.10', () async {
      final settings = SettingsService();
      await settings.init();
      expect(settings.bgVolume, closeTo(0.10, 0.001));
    });

    test('Updating music volume updates value and clamps', () async {
      final settings = SettingsService();
      await settings.init();

      await settings.setBgVolume(0.35);
      expect(settings.bgVolume, closeTo(0.35, 0.001));

      await settings.setBgVolume(1.5);
      expect(settings.bgVolume, 1.0);

      await settings.setBgVolume(-0.2);
      expect(settings.bgVolume, 0.0);
    });

    test('ThemeSet copyWith overrides specific block colors', () {
      const base = ThemeSet(
        a: Color(0xFFFF66C4),
        b: Color(0xFF00F0FF),
        c: Color(0xFF00FF66),
        d: Color(0xFFFFDE59),
        e: Color(0xFFFF5757),
        dark: Color(0xFF1A1A1A),
        light: Color(0xFFFFFFFF),
        mid: Color(0xFF2A2A2A),
      );

      final updated = base.copyWith(
        a: const Color(0xFF123456),
        c: const Color(0xFFABCDEF),
      );

      expect(updated.a, const Color(0xFF123456));
      expect(updated.b, base.b);
      expect(updated.c, const Color(0xFFABCDEF));
      expect(updated.d, base.d);
      expect(updated.e, base.e);
      expect(updated.dark, base.dark);
    });

    test('Custom block colors are saved and applied in getTheme()', () async {
      final settings = SettingsService();
      await settings.init();

      expect(settings.isThemeCustomized(AppMode.dark), isFalse);

      const customBlockA = Color(0xFFE91E63);
      await settings.setCustomColor(AppMode.dark, 'a', customBlockA);

      expect(settings.isThemeCustomized(AppMode.dark), isTrue);
      expect(settings.getCustomColor(AppMode.dark, 'a'), customBlockA);

      final theme = getTheme(AppMode.dark);
      expect(theme.a, customBlockA);

      await settings.resetThemeColors(AppMode.dark);
      expect(settings.isThemeCustomized(AppMode.dark), isFalse);

      final resetTheme = getTheme(AppMode.dark);
      expect(resetTheme.a, appThemes[AppMode.dark]!.a);
    });
  });
}
