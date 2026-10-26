import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/nosotros_screen.dart';
import 'screens/trivia/trivia_screen.dart';
import 'screens/finanzas/finanzas_screen.dart';
import 'screens/galeria/galeria_screen.dart';
import 'screens/galeria/pinterest_screen.dart';
import 'screens/favoritos/favoritos_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/ejercicios/ejercicios_screen.dart';
import 'screens/logros/logros_screen.dart';
import 'screens/recompensas/rewards_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/retos_screen.dart';
import 'screens/letters_screen.dart';
import 'screens/metas_screen.dart';
import 'screens/mapa_screen.dart';
import 'screens/milanote/milanote_screen.dart';
import 'screens/music/music_screen.dart';
import 'screens/mosaico_wrappers.dart';
import 'screens/herramientas/herramientas_screen.dart';
import 'screens/herramientas/dibujo/dibujo_screen.dart';
import 'screens/herramientas/comic/comic_editor_screen.dart';
import 'screens/herramientas/comic/comic_reader_screen.dart';
import 'screens/herramientas/comic/models/comic_project.dart';
import 'router_routes.dart';

export 'router_routes.dart';

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
      builder: (_, state) {
        final extra = state.extra;
        final openCreate = extra is Map &&
            (extra['create'] == true ||
                extra['createClass'] == true ||
                extra['createReminder'] == true);
        return CalendarScreen(openCreate: openCreate);
      },
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
      path: RouterRoutes.pinterest,
      builder: (_, _) => const PinterestScreen(),
    ),
    GoRoute(
      path: RouterRoutes.favoritos,
      builder: (_, _) => const FavoritosScreen(),
    ),
    GoRoute(
      path: RouterRoutes.milanote,
      builder: (_, state) => MilanoteScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.notes,
      builder: (_, state) => MilanoteScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.pizarra,
      builder: (_, state) => MilanoteScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.music,
      builder: (_, state) {
        final extra = state.extra;
        final tab = (extra is Map && extra['tab'] is int) ? (extra['tab'] as int) : 0;
        return MusicScreen(initialTab: tab);
      },
    ),
    GoRoute(
      path: RouterRoutes.ejercicios,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is EjerciciosArgs) {
          return EjerciciosScreen(
            mode: extra.mode,
            initialTab: extra.tab,
            isPopup: extra.isPopup,
          );
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
      builder: (_, _) => const CalendarScreen(openCreate: true),
    ),
    GoRoute(
      path: RouterRoutes.dailyEvents,
      builder: (_, _) => const CalendarScreen(),
    ),
    GoRoute(
      path: RouterRoutes.classBoard,
      builder: (_, _) => const CalendarScreen(),
    ),
    GoRoute(
      path: RouterRoutes.classSetup,
      builder: (_, _) => const CalendarScreen(),
    ),
    GoRoute(
      path: RouterRoutes.calendarMosaico,
      builder: (_, state) {
        final extra = state.extra;
        final openCreate = extra is Map &&
            (extra['create'] == true ||
                extra['createClass'] == true ||
                extra['createReminder'] == true);
        return CalendarScreen(openCreate: openCreate);
      },
    ),
    GoRoute(
      path: RouterRoutes.notesMosaico,
      builder: (_, _) => const NotesMosaicoScreen(),
    ),
    GoRoute(
      path: RouterRoutes.ejerciciosMosaico,
      builder: (_, state) => EjerciciosMosaicoScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.herramientas,
      builder: (_, state) => HerramientasScreen(mode: _mode(state)),
    ),
    GoRoute(
      path: RouterRoutes.dibujo,
      builder: (_, _) => const DibujoScreen(),
    ),
    GoRoute(
      path: RouterRoutes.comic,
      builder: (_, state) {
        final project = state.extra is ComicProject ? state.extra as ComicProject : null;
        return ComicEditorScreen(initialProject: project);
      },
    ),
    GoRoute(
      path: RouterRoutes.comicReader,
      builder: (_, state) {
        final project = state.extra as ComicProject;
        return ComicReaderScreen(project: project);
      },
    ),
  ],
);