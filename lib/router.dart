import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';
import 'theme/app_theme.dart';
import 'models/schedule.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/nosotros_screen.dart';
import 'screens/trivia/trivia_screen.dart';
import 'screens/finanzas/finanzas_screen.dart';
import 'screens/galeria/galeria_screen.dart';
import 'screens/favoritos/favoritos_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/ejercicios/ejercicios_screen.dart';
import 'screens/logros/logros_screen.dart';
import 'screens/recompensas/rewards_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/retos_screen.dart';
import 'screens/letters_screen.dart';
import 'screens/metas_screen.dart';
import 'screens/mapa_screen.dart';
import 'screens/calendar/calendar_home_screen.dart';
import 'screens/calendar/schedule_form_screen.dart';
import 'screens/calendar/daily_events_screen.dart';
import 'screens/calendar/class_board_screen.dart';
import 'screens/calendar/class_setup_wizard.dart';
import 'screens/mosaico_wrappers.dart';

/// Nombres canónicos de ruta. Las pantallas pasan su `AppMode` por [GoRouterState.extra];
/// los flujos que devuelven resultado usan `context.push(...)` (propaga el `pop`).
abstract final class RouterRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String nosotros = '/nosotros';
  static const String calendar = '/calendar';
  static const String trivia = '/trivia';
  static const String finanzas = '/finanzas';
  static const String galeria = '/galeria';
  static const String favoritos = '/favoritos';
  static const String notes = '/notes';
  static const String ejercicios = '/ejercicios';
  static const String logros = '/logros';
  static const String rewards = '/rewards';
  static const String chat = '/chat';
  static const String retos = '/retos';
  static const String cartas = '/cartas';
  static const String letters = '/letters';
  static const String metas = '/metas';
  static const String mapa = '/mapa';
  static const String scheduleForm = '/calendar/form';
  static const String dailyEvents = '/calendar/dia';
  static const String classBoard = '/calendar/clases';
  static const String classSetup = '/calendar/setup';
  static const String calendarMosaico = '/calendario-mosaico';
  static const String notesMosaico = '/notes-mosaico';
  static const String ejerciciosMosaico = '/ejercicios-mosaico';
}

/// Lee el `AppMode` que la pantalla lanzó (viene por `extra`) con fallback seguro.
AppMode _mode(GoRouterState state) =>
    state.extra is AppMode ? state.extra as AppMode : AppMode.dark;

/// Clave del navegador raíz (usada por Escape→maybePop y por el router).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final path = state.uri.path;
    final logged = AppState.myId != null;
    if (path == '/') return logged ? RouterRoutes.home : RouterRoutes.login;
    if (path == RouterRoutes.login) return logged ? RouterRoutes.home : null;
    if (path == RouterRoutes.home) return logged ? null : RouterRoutes.login;
    return null;
  },
  routes: [
    GoRoute(
      path: RouterRoutes.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: RouterRoutes.home,
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: RouterRoutes.settings,
      builder: (_, state) => SettingsScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.notifications,
      builder: (_, state) => NotificationsScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.nosotros,
      builder: (_, state) => NosotrosScreen(
        myId: AppState.myId ?? '',
        partnerId: AppState.partnerId,
        mode: _mode(state),
      ),
    ),
    GoRoute(
      path: RouterRoutes.calendar,
      builder: (_, _) => const CalendarHomeScreen(),
    ),
    GoRoute(
      path: RouterRoutes.trivia,
      builder: (_, state) => TriviaScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.finanzas,
      builder: (_, _) => const FinanzasScreen(),
    ),
    GoRoute(
      path: RouterRoutes.galeria,
      builder: (_, _) => const GaleriaScreen(),
    ),
    GoRoute(
      path: RouterRoutes.favoritos,
      builder: (_, _) => const FavoritosScreen(),
    ),
    GoRoute(
      path: RouterRoutes.notes,
      builder: (_, state) => NotesScreen(),
    ),
    GoRoute(
      path: RouterRoutes.ejercicios,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is EjerciciosArgs) {
          return EjerciciosScreen(mode: extra.mode, initialTab: extra.tab);
        }
        return EjerciciosScreen(mode: _mode(state));
      },
    ),
    GoRoute(
      path: RouterRoutes.logros,
      builder: (_, state) => LogrosScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.rewards,
      builder: (_, state) => RewardsScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.chat,
      builder: (_, state) => ChatScreen(
        myId: AppState.myId ?? '',
        partnerId: AppState.partnerId ?? '',
        myName: 'Yo',
        mode: _mode(state),
      ),
    ),
    GoRoute(
      path: RouterRoutes.retos,
      builder: (_, state) => RetosScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.cartas,
      builder: (_, state) => LettersScreen(mode: _mode(state), name: 'Yo'),
    ),
    GoRoute(
      path: RouterRoutes.metas,
      builder: (_, state) => MetasScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.mapa,
      builder: (_, state) => MapaScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.scheduleForm,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Schedule) return ScheduleFormScreen(schedule: extra);
        if (extra is DateTime) {
          return ScheduleFormScreen(initialDate: extra);
        }
        return ScheduleFormScreen();
      },
    ),
    GoRoute(
      path: RouterRoutes.dailyEvents,
      builder: (_, state) => DailyEventsScreen(
        initialDate: state.extra is DateTime ? state.extra as DateTime : DateTime.now(),
      ),
    ),
    GoRoute(
      path: RouterRoutes.classBoard,
      builder: (_, _) => const ClassBoardScreen(),
    ),
    GoRoute(
      path: RouterRoutes.classSetup,
      builder: (_, _) => const ClassSetupWizard(),
    ),
    GoRoute(
      path: RouterRoutes.calendarMosaico,
      builder: (_, _) => const CalendarMosaicoScreen(),
    ),
    GoRoute(
      path: RouterRoutes.notesMosaico,
      builder: (_, _) => const NotesMosaicoScreen(),
    ),
    GoRoute(
      path: RouterRoutes.ejerciciosMosaico,
      builder: (_, state) => EjerciciosMosaicoScreen(mode: _mode(state)),
    ),
  ],
);