import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import '../models/deck_card.dart';
import '../theme/app_theme.dart';
import '../router.dart';
import '../widgets/tap_tile.dart';
import '../widgets/mode_btn.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../providers/deck_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/rewards_provider.dart';

import 'mazo/deck_overlay.dart';
import 'mazo/deck_match_overlay.dart';

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

class _BrutalGridState extends State<_BrutalGrid>
    with SingleTickerProviderStateMixin {
  AppMode _mode = AppState.identity == 'Rocio'
      ? AppMode.dark : AppState.identity == 'Facu' ? AppMode.blue : AppMode.flower;
  bool _showDeck = false;
  bool _showPoemas = false;
  bool _notifDrawer = false;
  bool _shortcutPanelOpen = false;
  late final AnimationController _drawerCtrl;
  late final Animation<Offset> _drawerSlide;
  late final Animation<double> _drawerFade;

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

  void _onModeTap(AppMode mode) {
    _confettiAt(0, 0);
    setState(() => _mode = mode);
    _saveMode(mode);
  }

  @override
  void initState() {
    super.initState();
    NotificationService.startListening();
    _loadMode();
    _drawerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _drawerSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _drawerCtrl, curve: Curves.easeOutCubic));
    _drawerFade = CurvedAnimation(parent: _drawerCtrl, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDeck());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoupleProvider>().load();
    });
  }

  @override
  void dispose() {
    _drawerCtrl.dispose();
    super.dispose();
  }

  final GlobalKey<_NotificationPanelState> _notifPanelKey = GlobalKey<_NotificationPanelState>();

  void _openNotificationDrawer() {
    if (_shortcutPanelOpen) {
      _closeShortcutPanel();
      return;
    }
    setState(() => _notifDrawer = true);
    _drawerCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 50), () {
      _notifPanelKey.currentState?.refresh();
    });
  }

  void _closeNotificationDrawer() {
    _drawerCtrl.reverse().then((_) {
      if (mounted) setState(() => _notifDrawer = false);
    });
  }

  void _openShortcutPanel() {
    if (_notifDrawer) {
      _closeNotificationDrawer();
      return;
    }
    setState(() => _shortcutPanelOpen = true);
    _drawerCtrl.forward(from: 0);
  }

  void _closeShortcutPanel() {
    _drawerCtrl.reverse().then((_) {
      if (mounted) setState(() => _shortcutPanelOpen = false);
    });
  }

  /// Panel de notificaciones que se desliza desde la izquierda con animación.
  /// Se posiciona a la altura del botón superior izquierdo.
  Widget _notificationDrawer(ThemeSet t, double panelHeight, double left, double panelWidth) {
    final visible = _notifDrawer || _drawerCtrl.isAnimating;
    if (!visible) return const SizedBox.shrink();
    return Positioned(
      left: left, top: 0,
      width: panelWidth, height: panelHeight,
      child: AnimatedBuilder(
        animation: _drawerCtrl,
        builder: (context, _) {
          return IgnorePointer(
            ignoring: !(_notifDrawer || _drawerCtrl.isAnimating),
            child: Stack(children: [
              GestureDetector(
                onTap: _closeNotificationDrawer,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.5 * _drawerFade.value)),
              ),
              SlideTransition(
                position: _drawerSlide,
                child: _NotificationPanel(key: _notifPanelKey, theme: t, onClose: _closeNotificationDrawer),
              ),
            ]),
          );
        },
      ),
    );
  }

  /// Panel de accesos rápidos que se desliza desde la izquierda.
  /// Se posiciona a la altura del botón inferior izquierdo.
  Widget _shortcutPanelDrawer(ThemeSet t, double panelHeight, double left, double panelWidth) {
    final visible = _shortcutPanelOpen || _drawerCtrl.isAnimating;
    if (!visible) return const SizedBox.shrink();
    return Positioned(
      left: left, top: panelHeight,
      width: panelWidth, height: panelHeight,
      child: AnimatedBuilder(
        animation: _drawerCtrl,
        builder: (context, _) {
          return IgnorePointer(
            ignoring: !(_shortcutPanelOpen || _drawerCtrl.isAnimating),
            child: Stack(children: [
              GestureDetector(
                onTap: _closeShortcutPanel,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.5 * _drawerFade.value)),
              ),
              SlideTransition(
                position: _drawerSlide,
                child: _ShortcutPanel(theme: t, onClose: _closeShortcutPanel, onAction: _executeShortcutAction, onConfig: _openShortcutConfig),
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _initDeck() async {
    final pv = context.read<DeckProvider>();
    await pv.load();
    if (!mounted) return;
    if (pv.pendingFor(AppState.myId).isNotEmpty) {
      setState(() => _showDeck = true);
    }
  }

  void _openSettings() {
    context.push(RouterRoutes.settings, extra: _mode);
  }

  void _openShortcutConfig() {
    final t = getTheme(_mode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: t.a, width: 4),
        ),
        title: Text('Crear desde Inicio',
            style: GoogleFonts.bangers(fontSize: 24, color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
               _scBtn(ctx, 'Carta', Icons.edit, () => _executeShortcutAction('create_letter'), t),
               _scBtn(ctx, 'Nota', Icons.note_add, () => _executeShortcutAction('create_note'), t),
               _scBtn(ctx, 'Favorito', Icons.add_circle, () => _executeShortcutAction('create_favorite'), t),
               _scBtn(ctx, 'Evento', Icons.event, () => _executeShortcutAction('create_event'), t),
               _scBtn(ctx, 'Reto', Icons.flag, () => _executeShortcutAction('create_challenge'), t),
               _scBtn(ctx, 'Meta', Icons.emoji_events, () => _executeShortcutAction('create_goal'), t),
               _scBtn(ctx, 'Finanzas', Icons.account_balance_wallet, () => _executeShortcutAction('create_transaction'), t),
               _scBtn(ctx, 'Pregunta', Icons.chat_bubble_outline, () => _executeShortcutAction('create_question'), t),
               _scBtn(ctx, 'Galería', Icons.photo_camera_front, () => _executeShortcutAction('create_gallery'), t),
               _scBtn(ctx, 'Tarea', Icons.task_alt, () => _executeShortcutAction('create_task'), t),
               _scBtn(ctx, 'Clase', Icons.school, () => _executeShortcutAction('create_class'), t),
               _scBtn(ctx, 'Recordator', Icons.alarm, () => _executeShortcutAction('create_reminder'), t),
            ],
          ),
        ),
      ),
    );
  }

  void _executeShortcutAction(String action) {
    switch (action) {
      case 'create_letter':
        context.push(RouterRoutes.letters, extra: {'create': true, 'mode': _mode});
        break;
      case 'create_note':
        context.push(RouterRoutes.letters, extra: {'create': true, 'mode': _mode});
        break;
      case 'create_favorite':
        context.push(RouterRoutes.favoritos, extra: {'create': true});
        break;
      case 'create_event':
        context.push(RouterRoutes.scheduleForm, extra: {'create': true});
        break;
      case 'create_challenge':
        context.push(RouterRoutes.retos, extra: {'create': true});
        break;
      case 'create_goal':
        context.push(RouterRoutes.metas, extra: {'create': true});
        break;
      case 'create_transaction':
        context.push(RouterRoutes.finanzas, extra: {'create': true});
        break;
      case 'create_question':
        context.push(RouterRoutes.trivia, extra: {'create': true});
        break;
      case 'create_gallery':
        context.push(RouterRoutes.galeria, extra: {'create': true});
        break;
      case 'create_task':
        // Las tareas no tienen ruta propia aún; ir a configuración
        _openSettings();
        break;
      case 'create_class':
        context.push(RouterRoutes.calendarMosaico, extra: {'createClass': true});
        break;
      case 'create_reminder':
        context.push(RouterRoutes.calendarMosaico, extra: {'createReminder': true});
        break;
      default:
        break;
    }
  }

  Widget _scBtn(BuildContext ctx, String name, IconData icon, VoidCallback onTap, ThemeSet t) {
    return TapTile(
      onTap: () {
        // HapticFeedback.heavyImpact();
        onTap();
        Navigator.pop(ctx);
      },
      child: Container(
        decoration: BoxDecoration(
          color: t.c,
          border: Border.all(color: t.c, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: t.dark, size: 28),
            const SizedBox(height: 4),
            Text(name, style: GoogleFonts.bangers(color: t.dark, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  ThemeSet mutedTheme(ThemeSet t) {
    Color dim(Color c) {
      final hsl = HSLColor.fromColor(c);
      return hsl.withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0))
          .withLightness((hsl.lightness * 0.9).clamp(0.0, 1.0)).toColor();
    }
    return ThemeSet(
      a: dim(t.a), b: dim(t.b), c: dim(t.c), d: dim(t.d), e: dim(t.e),
      dark: Color.lerp(t.dark, const Color(0xFF000000), 0.15)!,
      light: Color.lerp(t.light, const Color(0xFF999999), 0.2)!,
      mid: Color.lerp(t.mid, const Color(0xFF000000), 0.15)!,
    );
  }

  void _openNosotros(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.nosotros, extra: _mode);
  }

  void _confettiAt(double x, double y) {
    _confettiColorsFor(context, x: x, y: y);
  }

  /// Confeti en la posición global del toque (usado por botones chicos que no
  /// conocen sus coordenadas de canvas: pesa/finanzas/favoritos/modos/mini).
  void _confettiGlobal(Offset g) {
    _confettiColorsFor(context, x: g.dx, y: g.dy);
  }

  void _openCalendar(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.calendarMosaico);
  }

  void _openEstudio(double x, double y) {
    // Sin navegación por ahora (botón decorativo).
    _confettiAt(x, y);
  }

  void _openFinanzas(double x, double y) {
    context.push(RouterRoutes.finanzas);
  }

  void _openGaleria(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.galeria);
  }

  void _openFavoritos(double x, double y) {
    context.push(RouterRoutes.favoritos);
  }

  void _openPizarra(double x, double y) {
    context.push(RouterRoutes.letters, extra: _mode);
  }

  void _openEjercicios(double x, double y) {
    context.push(RouterRoutes.ejerciciosMosaico, extra: _mode);
  }

  void _openTrivia(double x, double y) {
    context.push(RouterRoutes.trivia, extra: _mode);
  }

  void _openPoemas(double x, double y) {
    context.read<DeckProvider>().load();
    setState(() => _showPoemas = true);
  }

  void _openMazo(double x, double y) {
    context.read<DeckProvider>().load();
    setState(() => _showDeck = true);
  }

  void _openLogros() {
    context.push(RouterRoutes.logros, extra: _mode);
  }

  bool get _canPop {
    final deckPv = context.read<DeckProvider>();
    return !_notifDrawer &&
        !_shortcutPanelOpen &&
        !_showDeck &&
        !_showPoemas &&
        deckPv.pendingMatch == null;
  }

  /// Cierra los overlays internos en orden de prioridad y SOLO deja escapar el
  /// back cuando no queda ninguno. Si no, Android saldría de la app directo.
  void _handleBack() {
    if (_notifDrawer) {
      _closeNotificationDrawer();
      return;
    }
    if (_shortcutPanelOpen) {
      _closeShortcutPanel();
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
      child: ResponsiveWrapper(
      builder: (context, w, h) {
        final gap = w * 0.025;
        final c1 = w * 0.1;
        final c4 = w * 0.13;
        final rem = w - c1 - c4 - gap * 3;
        final c2 = rem * 1.13 / 1.96;
        final c3 = rem * 0.83 / 1.96;
        final x2 = c1 + gap;
        final x3 = x2 + c2 + gap;
        final x4 = x3 + c3 + gap;
        final rh = [
          (h - 5 * gap) * 0.127, (h - 5 * gap) * 0.218, (h - 5 * gap) * 0.218,
          (h - 5 * gap) * 0.114, (h - 5 * gap) * 0.114, (h - 5 * gap) * 0.209,
        ];
        final y1 = rh[0] + gap;
        final y2 = y1 + rh[1] + gap;
        final y3 = y2 + rh[2] + gap;
        final y4 = y3 + rh[3] + gap;
        final y5 = y4 + rh[4] + gap;

final raw = getTheme(_mode);
                final t = raw;

                return SizedBox(width: w, height: h, child: Stack(
                  children: [
            bg(w, h),
            Consumer<CoupleProvider>(
              builder: (context, couplePv, _) {
                final zenMode = Provider.of<SettingsService>(context, listen: false).zenMode;
                if (zenMode) return const SizedBox.shrink();
                return Positioned(right: c4 * 0.15, top: 4,
                  child: coupleTile(couplePv, t, onTap: () => _openLogros()));
              },
            ),
             block(0, 0, c1, y5 + rh[5], t.d, LeftButtons(t: t, onTopTap: _openNotificationDrawer, onBottomTap: _openShortcutPanel, onSwipeRight: _openNotificationDrawer, onDown: _confettiGlobal), _confettiAt, borderWidth: 4),
            block(x2, 0, x4 - x2, rh[0], t.a,
              Center(child: Text(AppState.identity == 'Rocio' ? 'Mis Cosas' : 'Herramientas',
                style: GoogleFonts.bangers(color: t.light, fontWeight: FontWeight.bold, fontSize: w * 0.055))),
              _confettiAt, borderWidth: 5),
            block(x4, 0, c4, rh[0], t.dark, fillIcon(Icons.settings, t.light), (x, y) => _openSettings(), borderWidth: 3),
            block(x2, y1, c2, rh[1], t.b,
              Transform.rotate(angle: -0.05, alignment: Alignment.center, child: fillIcon(Icons.calendar_month, t.dark)),
              _openCalendar, borderWidth: 6),
            block(x3, y1, x4 + c4 - x3, rh[1], t.a, fillIcon(Icons.school, t.dark), _openEstudio, borderWidth: 5),
            block(x2, y2, c2, rh[2] + gap + rh[3], t.e,
              Transform.rotate(angle: 0.07, alignment: Alignment.center,
                child: FittedBox(fit: BoxFit.contain, child: SizedBox(width: 120, height: 120,
                  child: Stack(alignment: Alignment.center, children: [
                    Icon(Icons.favorite, color: t.light, size: 110),
                    Icon(Icons.people, color: t.dark, size: 50),
                  ]),
                )),
              ), _openNosotros, borderWidth: 5),
            block(x3, y2, x4 + c4 - x3, rh[2], t.a,
              Transform.rotate(angle: 0.08, alignment: Alignment.center,
                child: Container(margin: EdgeInsets.all(w * 0.03),
                  decoration: BoxDecoration(color: t.c, border: Border.all(color: t.dark, width: 5), borderRadius: BorderRadius.circular(16))),
              ), _openPizarra, borderWidth: 5),
            block(x3, y3, c3, rh[3], t.c,
              Transform.rotate(angle: -0.1, alignment: Alignment.center,
                child: Padding(padding: EdgeInsets.all(w * 0.02),
                  child: Container(decoration: BoxDecoration(color: t.dark, borderRadius: BorderRadius.circular(14)), child: fillIcon(Icons.camera_alt, t.b))),
              ), _openGaleria, borderWidth: 4),
            block(x2, y4, x4 - x2, rh[4], t.dark,
              Row(children: [
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.style, t.c, t: t, onTap: () => _openMazo(0, 0), onDown: _confettiGlobal))),
                gapW(6),
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.quiz, t.b, t: t, onTap: () => _openTrivia(0, 0), onDown: _confettiGlobal))),
                gapW(6),
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.auto_stories, t.a, t: t, onTap: () => _openPoemas(0, 0), onDown: _confettiGlobal))),
              ]), (x, y) {}, borderWidth: 5),
            Positioned(left: x2, top: y5, width: x4 - x2, height: rh[5],
              child: Row(children: [
                Expanded(flex: 6, child: bottomBtn(const Color(0xFF39FF14), Icons.fitness_center, const Color(0xFF062B06), 5, _openEjercicios, _confettiGlobal)),
                gapW(6),
                Expanded(flex: 10, child: bottomBtn(t.a, Icons.bar_chart, t.light, 6, _openFinanzas, _confettiGlobal)),
                gapW(6),
                Expanded(flex: 11, child: bottomBtn(t.b, Icons.star, t.dark, 4, _openFavoritos, _confettiGlobal)),
              ]),
            ),
            modosBlock(x4, y3, c4, rh[3] + gap + rh[4], t, [
              ModeBtn(AppMode.flower, Icons.local_florist, _mode == AppMode.flower, _onModeTap),
              ModeBtn(AppMode.green, Icons.circle, _mode == AppMode.green, _onModeTap, iconColor: const Color(0xFF39FF14)),
              ModeBtn(AppMode.dark, Icons.dark_mode, _mode == AppMode.dark, _onModeTap),
            ]),
            modosBlock(x4, y5, c4, rh[5], t, [
              ModeBtn(AppMode.blue, Icons.circle, _mode == AppMode.blue, _onModeTap, iconColor: const Color(0xFF00E5FF)),
              ModeBtn(AppMode.heart, Icons.favorite, _mode == AppMode.heart, _onModeTap),
            ]),
            xFloating(w, h),
            if (_showDeck)
              Positioned.fill(
                child: DeckOverlay(
                  onClose: () => setState(() => _showDeck = false),
                ),
              ),
            if (_showPoemas)
              Positioned.fill(
                child: DeckOverlay(
                  category: DeckCategory.poemas,
                  onClose: () => setState(() => _showPoemas = false),
                ),
              ),
             _notificationDrawer(t, (y5 + rh[5]) / 2, 0, w * 0.7),
            _shortcutPanelDrawer(t, (y5 + rh[5]) / 2, 0, w * 0.7),
            Consumer<DeckProvider>(
              builder: (context, deckPv, _) {
                final match = deckPv.pendingMatch;
                if (match == null) return const SizedBox.shrink();
                return Positioned.fill(
                  child: DeckMatchOverlay(
                    card: match,
                    onDone: () {
                      final rw = context.read<RewardsProvider>();
                      final cid = match.id;
                      if (cid != null) {
                        rw.awardOnce(AppState.myId ?? '', 'match-$cid', 5);
                        final partner = AppState.partnerId;
                        if (partner != null) {
                          rw.awardOnce(partner, 'match-$cid', 5);
                        }
                      }
                      deckPv.consumeMatch();
                    },
                  ),
                );
              },
            ),
          ],
        ));
      },
    ));
  }
}

Widget coupleTile(CoupleProvider pv, ThemeSet t, {VoidCallback? onTap}) {
  if (pv.loading && pv.coupleStreak == 0) return const SizedBox.shrink();
  return TapTile(
    onTap: onTap ?? () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.c,
        border: Border.all(color: t.c, width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_fire_department,
            color: const Color(0xFFFFDE59), size: 18),
        const SizedBox(width: 5),
        Text('${pv.coupleStreak}',
            style: GoogleFonts.bangers(
                color: t.light, fontWeight: FontWeight.bold, fontSize: 18)),
      ]),
    ),
  );
}

Widget modosBlock(double l, double t, double w, double h, ThemeSet theme, List<Widget> btns) {
  return Positioned(left: l, top: t, width: w, height: h, child: ClipRRect(
    borderRadius: BorderRadius.circular(18),
      child: Container(
      decoration: BoxDecoration(color: theme.a, border: Border.all(color: theme.a, width: 4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: btns),
    ),
  ));
}

Widget gapW(double w) => SizedBox(width: w);

Widget fillIcon(IconData icon, Color color) {
  return FittedBox(fit: BoxFit.contain,
    child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)));
}

/// Lanza confeti en una posición dado en píxeles de pantalla.
void _confettiColorsFor(BuildContext ctx, {required double x, required double y}) {
  final screen = MediaQuery.of(ctx).size;
  Confetti.launch(ctx, options: ConfettiOptions(
    particleCount: 25, spread: 60, startVelocity: 50, gravity: 0.8, decay: 0.92,
    x: (x / screen.width).clamp(0.05, 0.95),
    y: (y / screen.height).clamp(0.05, 0.95),
    colors: _confettiColors,
  ));
}

const _confettiColors = [
  Color(0xFFFFDE59), Color(0xFF00F0FF), Color(0xFFFF5757),
  Color(0xFF00FF66), Color(0xFF7000FF), Color(0xFFFF66C4),
];

Widget bg(double w, double h) {
  return Positioned.fill(child: CustomPaint(painter: ConcretePainter()));
}

Widget xFloating(double w, double h) {
  return Positioned(right: w * 0.02, top: h * 0.45,
    child: Transform.rotate(angle: 0.3, child: Container(width: 4, height: 30, color: const Color(0xFFFFDE59))));
}

Widget block(double l, double t, double w, double h, Color bg, Widget child,
    void Function(double x, double y) onTap, {int borderWidth = 3}) {
  return Positioned(left: l, top: t, width: w, height: h, child: TapTile(
    onTap: () => onTap(l + w / 2, t + h / 2),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: bg,
          border: Border.all(color: bg, width: borderWidth.toDouble()),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
        child: child,
      ),
    ),
  ));
}

Widget miniIcon(IconData icon, Color color, {required ThemeSet t, VoidCallback? onTap, ValueChanged<Offset>? onDown}) {
  final inner = Container(
    decoration: BoxDecoration(color: t.mid, border: Border.all(color: t.mid, width: 3), borderRadius: BorderRadius.circular(10)),
    child: fillIcon(icon, color),
  );
  if (onTap == null) return inner;
  return GestureDetector(
    onTapDown: onDown == null ? null : (d) => onDown(d.globalPosition),
    child: TapTile(onTap: onTap, child: inner),
  );
}

Widget bottomBtn(Color color, IconData icon, Color iconColor, int bw,
    void Function(double x, double y) onTap, ValueChanged<Offset>? onDown) {
  return GestureDetector(
    onTapDown: onDown == null ? null : (d) => onDown(d.globalPosition),
    child: TapTile(
      onTap: () => onTap(0, 0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: color, border: Border.all(color: color, width: bw.toDouble()),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
        child: Padding(padding: const EdgeInsets.all(8), child: fillIcon(icon, iconColor)),
      ),
    ),
    ),
  );
}

class LeftButtons extends StatefulWidget {
  final ThemeSet t;
  final VoidCallback onTopTap;
  final VoidCallback onBottomTap;
  final VoidCallback? onSwipeRight;
  final ValueChanged<Offset>? onDown;
  const LeftButtons({super.key, required this.t, required this.onTopTap, required this.onBottomTap, this.onSwipeRight, this.onDown});

  @override
  State<LeftButtons> createState() => _LeftButtonsState();
}

class _LeftButtonsState extends State<LeftButtons> {
  double _dragDx = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(children: [
      Expanded(child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onDown == null ? null : (d) => widget.onDown!(d.globalPosition),
        onTap: widget.onTopTap,
        onHorizontalDragStart: (_) => _dragDx = 0,
        onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
        onHorizontalDragEnd: widget.onSwipeRight == null
            ? null
            : (d) {
                final opened =
                    _dragDx > 60 || (d.primaryVelocity ?? 0) > 250;
                _dragDx = 0;
                if (opened) {
                  widget.onSwipeRight!();
                }
              },
        onHorizontalDragCancel: () => _dragDx = 0,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Container(color: const Color(0xFFFFDE59), child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (_) => tbLine(t)),
          )),
        ),
      )),
      const SizedBox(height: 6),
      Expanded(child: GestureDetector(
        onTapDown: widget.onDown == null ? null : (d) => widget.onDown!(d.globalPosition),
        child: TapTile(
          onTap: widget.onBottomTap,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Container(color: const Color(0xFF00F0FF), child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (_) => tbLine(t)),
            )),
          ),
        ),
      )),
    ]);
  }
}

Widget tbLine(ThemeSet t) {
  return Container(width: 22, height: 16, margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(color: t.b, border: Border.all(color: t.dark, width: 3),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 0)]));
}

/// Panel de notificaciones que se desliza desde la izquierda. Lista las
/// notificaciones (leídas/no leídas), permite abrir y darse por aludido.
class _NotificationPanel extends StatefulWidget {
  final ThemeSet theme;
  final VoidCallback onClose;
  const _NotificationPanel({Key? key, required this.theme, required this.onClose}) : super(key: key);

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await NotificationService.getNotifications();
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (mounted) { _loading = false; _error = e.toString(); }
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    if (mounted) setState(() {
      for (final n in _items) { n['read'] = true; }
    });
  }

  void _open(Map<String, dynamic> n) {
    final id = (n['id'] as num?)?.toInt();
    if (id != null) {
      NotificationService.markAsRead(id);
    }
    if (mounted) setState(() => n['read'] = true);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: widget.theme.a, width: 4),
        ),
        title: Text(n['title']?.toString() ?? '',
            style: GoogleFonts.bangers(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(n['body']?.toString() ?? '',
            style: GoogleFonts.bangers(fontSize: 14, color: Colors.white70)),
        actions: [
          TapTile(onTap: () => Navigator.pop(ctx), child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: widget.theme.a, borderRadius: BorderRadius.circular(10), border: Border.all(color: widget.theme.a, width: 2)),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Material(
      color: const Color(0xFF101010),
      child: SafeArea(child: Column(children: [
        Container(height: 1, color: t.d),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(children: [
            Icon(Icons.notifications, color: t.a, size: 24),
            const Spacer(),
            if (_items.isNotEmpty)
              TapTile(onTap: _markAllRead, child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.done_all, color: t.c, size: 22),
              )),
            const SizedBox(width: 4),
            TapTile(onTap: widget.onClose, child: Padding(
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            )),
          ]),
        ),
        Expanded(child: _body(t)),
      ])),
    );
  }

  Widget _body(ThemeSet t) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
        const SizedBox(height: 12),
        TapTile(onTap: _load, child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: t.a, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.a, width: 2)),
          child: const Icon(Icons.refresh, color: Colors.white, size: 24),
        )),
      ]));
    }
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.notifications_none, color: Colors.white38, size: 56),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final n = _items[i];
        final read = n['read'] == true;
        final color = read ? Colors.white38 : t.a;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _open(n),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: read ? const Color(0xFF1A1A1A) : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: read ? const Color(0xFF2A2A2A) : color, width: 2),
              ),
              child: Row(children: [
                Icon(read ? Icons.mark_email_read : Icons.markunread, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['title']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                  if ((n['body']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(n['body'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11)),
                  ],
                ])),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _ShortcutPanel extends StatelessWidget {
  final ThemeSet theme;
  final VoidCallback onClose;
  final ValueChanged<String> onAction;
  final VoidCallback onConfig;

  const _ShortcutPanel({
    super.key,
    required this.theme,
    required this.onClose,
    required this.onAction,
    required this.onConfig,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Material(
      color: const Color(0xFF101010),
      child: SafeArea(child: Column(children: [
        Container(height: 1, color: t.d),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(children: [
            Icon(Icons.shortcut, color: t.a, size: 24),
            const Spacer(),
            TapTile(onTap: onConfig, child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.settings, color: t.dark, size: 24),
            )),
            const SizedBox(width: 4),
            TapTile(onTap: onClose, child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, color: t.dark, size: 24),
            )),
          ]),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(12),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _scItem(Icons.edit, 'Carta', t.a, () => onAction('create_letter')),
              _scItem(Icons.note_add, 'Nota', t.c, () => onAction('create_note')),
              _scItem(Icons.add_circle, 'Favorito', t.c, () => onAction('create_favorite')),
              _scItem(Icons.event, 'Evento', t.b, () => onAction('create_event')),
              _scItem(Icons.flag, 'Reto', t.d, () => onAction('create_challenge')),
              _scItem(Icons.emoji_events, 'Meta', t.e, () => onAction('create_goal')),
              _scItem(Icons.account_balance_wallet, 'Finanzas', t.d, () => onAction('create_transaction')),
              _scItem(Icons.chat_bubble_outline, 'Pregunta', t.a, () => onAction('create_question')),
              _scItem(Icons.photo_camera_front, 'Galería', t.b, () => onAction('create_gallery')),
              _scItem(Icons.task_alt, 'Tarea', t.c, () => onAction('create_task')),
              _scItem(Icons.school, 'Clase', t.b, () => onAction('create_class')),
              _scItem(Icons.alarm, 'Recordator', t.a, () => onAction('create_reminder')),
            ],
          ),
        ),
      ])),
    );
  }
}

Widget _scItem(IconData icon, String label, Color color, VoidCallback onTap) {
  return TapTile(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFFFFF), size: 28),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.bangers(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
