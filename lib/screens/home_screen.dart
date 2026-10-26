import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../providers/couple_provider.dart';
import '../providers/deck_provider.dart';
import '../providers/location_provider.dart';
import '../providers/trivia_provider.dart';
import '../router.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'home/helpers/home_drawer_drag_handler.dart';
import 'home/helpers/home_shortcut_handler.dart';
import 'home/widgets/home_grid_tiles.dart';
import 'home/widgets/home_main_grid.dart';
import 'home/widgets/home_notification_panel.dart';
import 'home/widgets/home_shortcut_config_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: SafeArea(child: _BrutalGrid()),
    );
  }
}

class _BrutalGrid extends StatefulWidget {
  const _BrutalGrid();

  @override
  State<_BrutalGrid> createState() => _BrutalGridState();
}

class _BrutalGridState extends State<_BrutalGrid> with TickerProviderStateMixin {
  AppMode _mode = AppState.identity == 'Rocio'
      ? AppMode.dark
      : AppState.identity == 'Facu'
          ? AppMode.blue
          : AppMode.flower;
  bool _showDeck = false;
  bool _showPoemas = false;
  List<String> _userShortcuts = [];
  late final AnimationController _notifCtrl;
  late final AnimationController _shortcutCtrl;
  final GlobalKey<NotificationPanelState> _notifPanelKey = GlobalKey<NotificationPanelState>();
  late final HomeDrawerDragHandler _drawerHandler;

  @override
  void initState() {
    super.initState();
    NotificationService.startListening();
    _loadMode();
    _loadShortcuts();
    _notifCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _shortcutCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _drawerHandler = HomeDrawerDragHandler(
      notifCtrl: _notifCtrl,
      shortcutCtrl: _shortcutCtrl,
      notifPanelKey: _notifPanelKey,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDeck());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoupleProvider>().load();
      context.read<LocationProvider>().initAutoLocation();
      context.read<TriviaProvider>().load();
    });
  }

  @override
  void dispose() {
    _notifCtrl.dispose();
    _shortcutCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('appMode');
    if (saved != null && mounted) {
      setState(() => _mode = AppMode.values.firstWhere((m) => m.name == saved, orElse: () => _mode));
    }
  }

  Future<void> _saveMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appMode', mode.name);
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('user_home_shortcuts');
    if (saved != null && mounted) {
      setState(() => _userShortcuts = List<String>.from(saved));
    }
  }

  Future<void> _saveShortcuts(List<String> shortcuts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_home_shortcuts', shortcuts);
  }

  void _onModeTap(AppMode mode, Offset g) {
    _confettiGlobal(g);
    setState(() => _mode = mode);
    _saveMode(mode);
  }

  Future<void> _initDeck() async {
    final pv = context.read<DeckProvider>();
    await pv.load();
    if (!mounted) return;
    if (pv.pendingFor(AppState.myId).isNotEmpty) {
      setState(() => _showDeck = true);
    }
  }

  void _openSettings() => context.push(RouterRoutes.settings, extra: _mode);

  void _openShortcutConfig() {
    showShortcutConfigDialog(
      context: context,
      theme: getTheme(_mode),
      currentShortcuts: _userShortcuts,
      onSave: (list) {
        setState(() => _userShortcuts = list);
        _saveShortcuts(list);
      },
    );
  }

  void _openNosotros(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.nosotros, extra: _mode);
  }

  void _confettiAt(double x, double y) => confettiColorsFor(context, x: x, y: y);
  void _confettiGlobal(Offset g) => confettiColorsFor(context, x: g.dx, y: g.dy);

  void _openCalendar(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.calendar);
  }

  void _openPizarron(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.pizarra, extra: _mode);
  }

  void _openFinanzas(double x, double y) => context.push(RouterRoutes.finanzas);

  void _openGaleria(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.galeria);
  }

  void _openFavoritos(double x, double y) => context.push(RouterRoutes.favoritos);
  void _openEjercicios(double x, double y) => context.push(RouterRoutes.ejerciciosMosaico, extra: _mode);
  void _openTrivia(double x, double y) => context.push(RouterRoutes.trivia, extra: _mode);

  void _openMazo(double x, double y) {
    context.read<DeckProvider>().load();
    setState(() => _showDeck = true);
  }

  void _openMusic(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.music);
  }

  void _openHerramientas(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.herramientas, extra: _mode);
  }

  void _openLogros() => context.push(RouterRoutes.logros, extra: _mode);

  bool get _canPop {
    final deckPv = context.read<DeckProvider>();
    return _notifCtrl.value == 0 &&
        _shortcutCtrl.value == 0 &&
        !_showDeck &&
        !_showPoemas &&
        deckPv.pendingMatch == null;
  }

  void _handleBack() {
    if (_notifCtrl.value > 0) {
      _drawerHandler.closeNotificationDrawer();
      return;
    }
    if (_shortcutCtrl.value > 0) {
      _drawerHandler.closeShortcutPanel();
      return;
    }
    if (_showDeck) {
      setState(() => _showDeck = false);
      return;
    }
    if (_showPoemas) {
      setState(() => _showPoemas = false);
      return;
    }
    final deckPv = context.read<DeckProvider>();
    if (deckPv.pendingMatch != null) {
      deckPv.consumeMatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: HomeMainGrid(
        mode: _mode,
        theme: getTheme(_mode),
        drawerHandler: _drawerHandler,
        userShortcuts: _userShortcuts,
        showDeck: _showDeck,
        showPoemas: _showPoemas,
        onOpenSettings: _openSettings,
        onOpenCalendar: _openCalendar,
        onOpenPizarron: _openPizarron,
        onOpenNosotros: _openNosotros,
        onOpenGaleria: _openGaleria,
        onOpenMazo: _openMazo,
        onOpenTrivia: _openTrivia,
        onOpenMusic: _openMusic,
        onOpenEjercicios: _openEjercicios,
        onOpenFinanzas: _openFinanzas,
        onOpenFavoritos: _openFavoritos,
        onOpenHerramientas: _openHerramientas,
        onOpenLogros: _openLogros,
        onModeTap: _onModeTap,
        onConfettiAt: _confettiAt,
        onConfettiGlobal: _confettiGlobal,
        onShortcutAction: (action) => HomeShortcutHandler.execute(context, action, _mode),
        onManageShortcuts: _openShortcutConfig,
        onCloseDeck: () => setState(() => _showDeck = false),
        onClosePoemas: () => setState(() => _showPoemas = false),
      ),
    );
  }
}
