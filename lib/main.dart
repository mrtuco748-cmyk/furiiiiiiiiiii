import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'supabase_config.dart';
import 'app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/ai_service.dart';
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
import 'providers/theme_provider.dart';
import 'providers/menu_provider.dart';
import 'database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    ErrorWidget.builder = (FlutterErrorDetails details) => _crashWidget(details.exception.toString(), details.stack?.toString() ?? 'WIDGET CRASH:');

    String? initError;
    bool saved = false;

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

    try { await SupabaseConfig.initialize(); }
    catch (e) { initError = initError ?? 'Supabase: $e'; }

    try { await NotificationService.initialize(); }
    catch (e) { initError = initError ?? 'Notifications: $e'; }

    try { await DatabaseHelper().database; }
    catch (e) { initError = initError ?? 'Database: $e'; }

    if (initError == null) {
      try { AiService().init(); }
      catch (e) { initError = 'AI: $e'; }
    }

    if (initError == null) {
      try { saved = await AppState.loadSession(); }
      catch (e) { initError = 'AppState: $e'; }
    }

    if (initError != null) {
      runApp(_CrashApp(message: initError));
      return;
    }

    runApp(FuriApp(startDirect: saved));
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
  final bool startDirect;
  const FuriApp({super.key, this.startDirect = false});

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
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => MenuProvider()),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'F.U.R.I',
            theme: ThemeData(useMaterial3: true),
            home: startDirect ? const HomeScreen() : const LoginScreen(),
          ),
        ),
      ),
    );
  }
}
