import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'router.dart';
import 'supabase_config.dart';
import 'app_state.dart';
import 'services/notification_service.dart';
import 'services/ai_service.dart';
import 'services/settings_service.dart';
import 'services/sound_service.dart';
import 'providers/schedule_provider.dart';
import 'providers/event_type_provider.dart';
import 'providers/class_schedule_provider.dart';
import 'providers/class_type_provider.dart';
import 'providers/sync_provider.dart';

import 'providers/study_provider.dart';
import 'providers/finances_provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/board_data_provider.dart';
import 'providers/board_provider_v2.dart';
import 'providers/workout_provider.dart';
import 'providers/couple_provider.dart';
import 'providers/couple_achievements_provider.dart';
import 'providers/trivia_provider.dart';
import 'providers/rewards_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/location_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/menu_provider.dart';
import 'database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    ErrorWidget.builder = (FlutterErrorDetails details) => _crashWidget(details.exception.toString(), details.stack?.toString() ?? 'WIDGET CRASH:');

    String? initError;

    final bool isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    try {
      if (isDesktop) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfiNoIsolate;
      }
    } catch (e) { initError = 'SQLite FFI: $e'; }

    try { await dotenv.load(fileName: '.env'); }
    catch (e) { initError = initError ?? 'dotenv: $e'; }

    try { await initializeDateFormatting('es'); }
    catch (e) { initError = initError ?? 'intl: $e'; }

    try { await SupabaseConfig.initialize(); }
    catch (e) { initError = initError ?? 'Supabase: $e'; }

    try { await NotificationService.initialize(); }
    catch (e) { initError = initError ?? 'Notifications: $e'; }

    try { await DatabaseHelper().database; }
    catch (e) { initError = initError ?? 'Database: $e'; }

    try { await SettingsService().init(); }
    catch (e) { initError = initError ?? 'Settings: $e'; }

    try { await SoundService().startBackgroundMusic(); }
    catch (e) { initError = initError ?? 'Sound: $e'; }

    if (initError == null) {
      try { AiService().init(); }
      catch (e) { initError = 'AI: $e'; }
    }

    if (initError == null) {
      try { await AppState.loadSession(); }
      catch (e) { initError = 'AppState: $e'; }
    }

    if (initError != null) {
      runApp(_CrashApp(message: initError));
      return;
    }

    runApp(const FuriApp());
  }, (error, stack) {
    runApp(_CrashApp(message: 'UNCAUGHT: $error\n$stack'));
  });
}

class _CrashApp extends StatelessWidget {
  final String message;
  const _CrashApp({super.key, required this.message});
  @override
  Widget build(BuildContext context) => MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(message, style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
          ),
        ),
      ));
}

Widget _crashWidget(String error, String prefix) => MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText('$prefix\n$error', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
        ),
      ),
    ));

class GoBackIntent extends Intent {
  const GoBackIntent();
}

class FuriApp extends StatelessWidget {
  const FuriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): GoBackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          GoBackIntent: CallbackAction<GoBackIntent>(
            onInvoke: (_) => navigatorKey.currentState?.maybePop(),
          ),
        },
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ScheduleProvider()),
            ChangeNotifierProvider(create: (_) => EventTypeProvider()),
            ChangeNotifierProvider(create: (_) => ClassTypeProvider()),
            ChangeNotifierProvider(create: (_) => ClassScheduleProvider()),
            ChangeNotifierProvider(create: (_) => SyncProvider()),

            ChangeNotifierProvider(create: (_) => StudyProvider()),
            ChangeNotifierProvider(create: (_) => FinancesProvider()),
            ChangeNotifierProvider(create: (_) => GalleryProvider()),
            ChangeNotifierProvider(create: (_) => FavoritesProvider()),
            ChangeNotifierProvider(create: (_) => BoardDataProvider()),
            ChangeNotifierProvider(create: (_) => BoardProviderV2()),
            ChangeNotifierProvider(create: (_) => WorkoutProvider()),
            ChangeNotifierProvider(create: (_) => CoupleProvider()),
            ChangeNotifierProvider(create: (_) => CoupleAchievementsProvider()),
            ChangeNotifierProvider(create: (_) => TriviaProvider()),
            ChangeNotifierProvider(create: (_) => RewardsProvider()),
            ChangeNotifierProvider(create: (_) => DeckProvider()),
            ChangeNotifierProvider(create: (_) => LocationProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => MenuProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
            title: 'F.U.R.I',
            theme: ThemeData(useMaterial3: true),
          ),
        ),
      ),
    );
  }
}
