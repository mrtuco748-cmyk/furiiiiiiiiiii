import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:furi_app/main.dart';
import 'package:furi_app/providers/theme_provider.dart';
import 'package:furi_app/providers/menu_provider.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('FuriApp registers providers in MultiProvider', (tester) async {
    await tester.pumpWidget(const FuriApp());
    expect(find.byType(MultiProvider), findsOneWidget);
  });

  test('ThemeProvider loads and defaults to dark mode', () {
    final provider = ThemeProvider();
    expect(provider.darkMode, isTrue);
    expect(provider.themeMode, ThemeMode.dark);
  });

  test('ThemeProvider toggles dark mode', () async {
    final provider = ThemeProvider();
    await provider.setDarkMode(false);
    expect(provider.darkMode, isFalse);
    expect(provider.themeMode, ThemeMode.light);
    await provider.setDarkMode(true);
    expect(provider.darkMode, isTrue);
  });

  test('MenuProvider initializes empty', () {
    final provider = MenuProvider();
    expect(provider.menus, isEmpty);
    expect(provider.isLoading, isFalse);
  });
}
