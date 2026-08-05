import 'package:flutter/material.dart';
import '../app_state.dart';

enum AppMode { flower, green, dark, blue, heart }

class ThemeSet {
  final Color a, b, c, d, e, dark, light, mid;
  const ThemeSet({
    required this.a, required this.b, required this.c,
    required this.d, required this.e,
    required this.dark, required this.light, required this.mid,
  });
}

ThemeSet getTheme(AppMode mode) {
  final t = appThemes[mode]!;
  if (AppState.identity == 'Rocio') return _mutedTheme(t);
  return t;
}

ThemeSet _mutedTheme(ThemeSet t) {
  Color dim(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withSaturation((hsl.saturation * 0.55).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.92).clamp(0.0, 1.0)).toColor();
  }
  return ThemeSet(
    a: dim(t.a), b: dim(t.b), c: dim(t.c), d: dim(t.d), e: dim(t.e),
    dark: Color.lerp(t.dark, const Color(0xFF000000), 0.15)!,
    light: Color.lerp(t.light, const Color(0xFFAAAAAA), 0.15)!,
    mid: Color.lerp(t.mid, const Color(0xFF000000), 0.15)!,
  );
}

// Clay theme constants for calendar/event system (from Gastronomia-App)
const clayPurple = Color(0xFF7B2D8E);
const clayDarkPurple = Color(0xFF4A1C5E);
const clayLilac = Color(0xFFC9A8E8);
const clayLightLilac = Color(0xFFE8D5F5);
const claySoftPurple = Color(0xFF9B59B6);
const clayBg = Color(0xFFF0E6F6);
const clayLight = Color(0xFFF5EDFB);
const clayShadow = Color(0xFFD4C0E3);
const clayDarkShadow = Color(0xFFB8A0CC);
const clayDarkBg = Color(0xFF1A1025);
const clayDarkSurface = Color(0xFF2D1B3E);
const clayDarkCard = Color(0xFF362548);
const clayDarkElevated = Color(0xFF3F2953);
const clayDarkText = Color(0xFFE8D5F5);
const clayDarkTextSecondary = Color(0xFFC9A8E8);
const clayDarkHint = Color(0xFF7B2D8E);

BoxDecoration clayCard([BuildContext? context]) {
  final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return BoxDecoration(
      color: clayDarkCard,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(6, 6), blurRadius: 12),
        BoxShadow(color: clayDarkElevated.withValues(alpha: 0.3), offset: const Offset(-4, -4), blurRadius: 12),
      ],
    );
  }
  return BoxDecoration(
    color: clayLight,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: clayDarkShadow.withValues(alpha: 0.4), offset: const Offset(6, 6), blurRadius: 12),
      BoxShadow(color: Colors.white.withValues(alpha: 0.7), offset: const Offset(-4, -4), blurRadius: 12),
    ],
  );
}

extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textColor => isDark ? clayDarkText : clayDarkPurple;
  Color get secondaryColor => isDark ? clayDarkTextSecondary : clayPurple;
  Color get surfaceColor => isDark ? clayDarkCard : clayLight;
  Color get scaffoldColor => isDark ? clayDarkBg : clayBg;
  Color get chipColor => isDark ? clayDarkElevated : clayLightLilac;
}

const appThemes = <AppMode, ThemeSet>{
  AppMode.flower: ThemeSet(
    a: Color(0xFFFF66C4), b: Color(0xFF00F0FF), c: Color(0xFF00FF66),
    d: Color(0xFFFFDE59), e: Color(0xFFFF5757),
    dark: Color(0xFF1A1A1A), light: Color(0xFFFFFFFF), mid: Color(0xFF2A2A2A),
  ),
  AppMode.green: ThemeSet(
    a: Color(0xFF00FF66), b: Color(0xFF00F0FF), c: Color(0xFFFFDE59),
    d: Color(0xFFFF66C4), e: Color(0xFF7000FF),
    dark: Color(0xFF1B2E1B), light: Color(0xFFF1F8E9), mid: Color(0xFF263A26),
  ),
  AppMode.dark: ThemeSet(
    a: Color(0xFF7000FF), b: Color(0xFF00F0FF), c: Color(0xFF00FF66),
    d: Color(0xFFFF66C4), e: Color(0xFFFF5757),
    dark: Color(0xFF0D0D0D), light: Color(0xFFE0E0E0), mid: Color(0xFF1E1E1E),
  ),
  AppMode.blue: ThemeSet(
    a: Color(0xFF00F0FF), b: Color(0xFFFFDE59), c: Color(0xFF00FF66),
    d: Color(0xFFFF66C4), e: Color(0xFF7000FF),
    dark: Color(0xFF0D2137), light: Color(0xFFE3F2FD), mid: Color(0xFF1A334A),
  ),
  AppMode.heart: ThemeSet(
    a: Color(0xFFFF5757), b: Color(0xFFFF66C4), c: Color(0xFF00F0FF),
    d: Color(0xFFFFDE59), e: Color(0xFF7000FF),
    dark: Color(0xFF2D0A0A), light: Color(0xFFFFF5F5), mid: Color(0xFF3D1414),
  ),
};
