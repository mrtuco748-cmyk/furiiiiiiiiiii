import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_service.dart';
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
import '../providers/location_provider.dart';
import '../providers/trivia_provider.dart';

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
    with TickerProviderStateMixin {
  AppMode _mode = AppState.identity == 'Rocio'
      ? AppMode.dark : AppState.identity == 'Facu' ? AppMode.blue : AppMode.flower;
  bool _showDeck = false;
  bool _showPoemas = false;
  bool _notifDrawer = false;
  bool _shortcutPanelOpen = false;
  List<String> _userShortcuts = [];
  late final AnimationController _notifCtrl;
  late final AnimationController _shortcutCtrl;

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

  @override
  void initState() {
    super.initState();
    NotificationService.startListening();
    _loadMode();
    _loadShortcuts();
    _notifCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _shortcutCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
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

  final GlobalKey<_NotificationPanelState> _notifPanelKey = GlobalKey<_NotificationPanelState>();

  void _openNotificationDrawer() {
    if (_shortcutPanelOpen || _shortcutCtrl.value > 0) {
      _closeShortcutPanel();
    }
    _notifCtrl.animateTo(1.0, curve: Curves.easeOutCubic).then((_) {
      if (mounted) setState(() => _notifDrawer = true);
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      _notifPanelKey.currentState?.refresh();
    });
  }

  void _closeNotificationDrawer() {
    _notifCtrl.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
      if (mounted) setState(() => _notifDrawer = false);
    });
  }

  void _openShortcutPanel() {
    if (_notifDrawer || _notifCtrl.value > 0) {
      _closeNotificationDrawer();
    }
    _shortcutCtrl.animateTo(1.0, curve: Curves.easeOutCubic).then((_) {
      if (mounted) setState(() => _shortcutPanelOpen = true);
    });
  }

  void _closeShortcutPanel() {
    _shortcutCtrl.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
      if (mounted) setState(() => _shortcutPanelOpen = false);
    });
  }

  void _handleNotifDragStart(DragStartDetails details) {
    _notifCtrl.stop();
    if (_shortcutPanelOpen || _shortcutCtrl.value > 0) {
      _closeShortcutPanel();
    }
  }

  void _handleNotifDragUpdate(DragUpdateDetails details, double panelWidth) {
    final delta = details.primaryDelta ?? 0;
    _notifCtrl.value = (_notifCtrl.value + delta / panelWidth).clamp(0.0, 1.0);
  }

  void _handleNotifDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 280 || (velocity >= -280 && _notifCtrl.value >= 0.35)) {
      _openNotificationDrawer();
    } else {
      _closeNotificationDrawer();
    }
  }

  void _handleShortcutDragStart(DragStartDetails details) {
    _shortcutCtrl.stop();
    if (_notifDrawer || _notifCtrl.value > 0) {
      _closeNotificationDrawer();
    }
  }

  void _handleShortcutDragUpdate(DragUpdateDetails details, double panelWidth) {
    final delta = details.primaryDelta ?? 0;
    _shortcutCtrl.value = (_shortcutCtrl.value + delta / panelWidth).clamp(0.0, 1.0);
  }

  void _handleShortcutDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 280 || (velocity >= -280 && _shortcutCtrl.value >= 0.35)) {
      _openShortcutPanel();
    } else {
      _closeShortcutPanel();
    }
  }

  Widget _buildTopSlidingDrawer(ThemeSet t, double panelHeight, double panelWidth, double c1) {
    return AnimatedBuilder(
      animation: _notifCtrl,
      builder: (context, _) {
        final progress = _notifCtrl.value;
        final panelLeft = (progress - 1.0) * panelWidth;
        final cardLeft = progress * panelWidth;

        final topBtnColor = t.d;
        final topDotColor = (topBtnColor == t.a) ? t.light : t.a;

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: progress == 0,
                child: GestureDetector(
                  onTap: _closeNotificationDrawer,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5 * progress),
                  ),
                ),
              ),
            ),
            Positioned(
              left: panelLeft,
              top: 0,
              width: panelWidth,
              height: panelHeight,
              child: IgnorePointer(
                ignoring: progress == 0,
                child: GestureDetector(
                  onHorizontalDragStart: _handleNotifDragStart,
                  onHorizontalDragUpdate: (d) => _handleNotifDragUpdate(d, panelWidth),
                  onHorizontalDragEnd: _handleNotifDragEnd,
                  child: _NotificationPanel(
                    key: _notifPanelKey,
                    theme: t,
                  ),
                ),
              ),
            ),
            Positioned(
              left: cardLeft,
              top: 0,
              width: c1,
              height: panelHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _handleNotifDragStart,
                  onHorizontalDragUpdate: (d) => _handleNotifDragUpdate(d, panelWidth),
                  onHorizontalDragEnd: _handleNotifDragEnd,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: topBtnColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.dark, width: 2.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (_) => tbLine(color: topDotColor, borderColor: t.dark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomSlidingDrawer(ThemeSet t, double panelHeight, double panelWidth, double c1) {
    return AnimatedBuilder(
      animation: _shortcutCtrl,
      builder: (context, _) {
        final progress = _shortcutCtrl.value;
        final panelLeft = (progress - 1.0) * panelWidth;
        final cardLeft = progress * panelWidth;

        final bottomBtnColor = t.b;
        final bottomDotColor = (bottomBtnColor == t.a) ? t.d : t.a;

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: progress == 0,
                child: GestureDetector(
                  onTap: _closeShortcutPanel,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5 * progress),
                  ),
                ),
              ),
            ),
            Positioned(
              left: panelLeft,
              top: panelHeight,
              width: panelWidth,
              height: panelHeight,
              child: IgnorePointer(
                ignoring: progress == 0,
                child: GestureDetector(
                  onHorizontalDragStart: _handleShortcutDragStart,
                  onHorizontalDragUpdate: (d) => _handleShortcutDragUpdate(d, panelWidth),
                  onHorizontalDragEnd: _handleShortcutDragEnd,
                  child: _ShortcutPanel(
                    theme: t,
                    userShortcuts: _userShortcuts,
                    onAction: _executeShortcutAction,
                    onManageShortcuts: _openShortcutConfig,
                  ),
                ),
              ),
            ),
            Positioned(
              left: cardLeft,
              top: panelHeight,
              width: c1,
              height: panelHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _handleShortcutDragStart,
                  onHorizontalDragUpdate: (d) => _handleShortcutDragUpdate(d, panelWidth),
                  onHorizontalDragEnd: _handleShortcutDragEnd,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bottomBtnColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.dark, width: 2.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (_) => tbLine(color: bottomDotColor, borderColor: t.dark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: t.b, size: 26),
                const SizedBox(width: 10),
                Text(
                  'ELEGIR ATAJOS',
                  style: GoogleFonts.bangers(
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Tocá para agregar o quitar de la barra',
                        style: GoogleFonts.bangers(
                          fontSize: 13,
                          color: Colors.white54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: _homeShortcuts.length,
                      itemBuilder: (context, i) {
                        final sc = _homeShortcuts[i];
                        final isSelected = _userShortcuts.contains(sc.action);
                        final itemColor = isSelected ? _shortcutColor(t, i) : const Color(0xFF242424);
                        final textColor = isSelected ? Colors.white : Colors.white38;
                        final iconColor = isSelected ? Colors.white : Colors.white38;

                        return TapTile(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _userShortcuts.remove(sc.action);
                              } else {
                                _userShortcuts.add(sc.action);
                              }
                            });
                            setState(() {});
                            _saveShortcuts(_userShortcuts);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: itemColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(sc.icon, color: iconColor, size: 26),
                                const SizedBox(height: 6),
                                Text(
                                  sc.label,
                                  style: GoogleFonts.bangers(
                                    fontSize: 11,
                                    color: textColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TapTile(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: t.b,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'LISTO',
                      style: GoogleFonts.bangers(
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _executeShortcutAction(String action) {
    HapticFeedback.mediumImpact();
    switch (action) {
      case 'open_letters':
        context.push(RouterRoutes.cartas, extra: {'mode': _mode});
        break;
      case 'write_letter':
        context.push(RouterRoutes.cartas, extra: {'create': true, 'mode': _mode});
        break;
      case 'schedule_school':
        context.push(RouterRoutes.calendar, extra: {'create': true, 'createClass': true});
        break;
      case 'open_music':
        context.push(RouterRoutes.music, extra: {'tab': 0});
        break;
      case 'open_playlists':
        context.push(RouterRoutes.music, extra: {'tab': 1});
        break;
      case 'search_music':
        context.push(RouterRoutes.music, extra: {'tab': 2});
        break;
      case 'update_gps':
        _quickUpdateGps();
        break;
      case 'open_map':
        context.push(RouterRoutes.mapa, extra: _mode);
        break;
      case 'open_metas':
        context.push(RouterRoutes.metas);
        break;
      case 'open_retos':
        context.push(RouterRoutes.retos);
        break;
      case 'open_rewards':
        context.push(RouterRoutes.rewards);
        break;
      case 'open_achievements':
        context.push(RouterRoutes.logros);
        break;
      case 'log_workout':
        context.push(RouterRoutes.ejercicios, extra: _mode);
        break;
      default:
        break;
    }
  }

  Future<void> _quickUpdateGps() async {
    HapticFeedback.heavyImpact();
    SoundService().pop();
    final lpv = context.read<LocationProvider>();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF222222),
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF39FF14)),
              ),
              SizedBox(width: 12),
              Text('Actualizando ubicación GPS...', style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor activa la ubicación / GPS del dispositivo')),
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
        }
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await lpv.updateMyLocation(lastKnown.latitude, lastKnown.longitude);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      );
      final ok = await lpv.updateMyLocation(pos.latitude, pos.longitude);
      if (mounted && ok) {
        SoundService().success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF39FF14),
            content: Text(
              '¡Ubicación actualizada con éxito!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar GPS: $e')),
        );
      }
    }
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
    context.push(RouterRoutes.calendar);
  }

  void _openPizarron(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.pizarra, extra: _mode);
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

  void _openEjercicios(double x, double y) {
    context.push(RouterRoutes.ejerciciosMosaico, extra: _mode);
  }

  void _openTrivia(double x, double y) {
    context.push(RouterRoutes.trivia, extra: _mode);
  }

  void _openMazo(double x, double y) {
    context.read<DeckProvider>().load();
    setState(() => _showDeck = true);
  }

  void _openMusic(double x, double y) {
    _confettiAt(x, y);
    context.push(RouterRoutes.music);
  }

  void _openLogros() {
    context.push(RouterRoutes.logros, extra: _mode);
  }

  bool get _canPop {
    final deckPv = context.read<DeckProvider>();
    return _notifCtrl.value == 0 &&
        _shortcutCtrl.value == 0 &&
        !_showDeck &&
        !_showPoemas &&
        deckPv.pendingMatch == null;
  }

  /// Cierra los overlays internos en orden de prioridad y SOLO deja escapar el
  /// back cuando no queda ninguno. Si no, Android saldría de la app directo.
  void _handleBack() {
    if (_notifCtrl.value > 0) {
      _closeNotificationDrawer();
      return;
    }
    if (_shortcutCtrl.value > 0) {
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

final t = getTheme(_mode);

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
            Positioned(
              left: 0,
              top: 0,
              width: c1,
              height: y5 + rh[5],
              child: Container(
                decoration: BoxDecoration(
                  color: t.mid,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: t.dark.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: t.dark.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            block(x2, 0, x4 - x2, rh[0], t.a,
              Center(child: Text(AppState.identity == 'Rocio' ? 'Mis Cosas' : 'Herramientas',
                style: GoogleFonts.bangers(color: t.light, fontWeight: FontWeight.bold, fontSize: w * 0.055))),
              _confettiAt, borderWidth: 5),
            block(x4, 0, c4, rh[0], t.dark, fillIcon(Icons.settings, t.light), (x, y) => _openSettings(), borderWidth: 3),
            block(x2, y1, c2, rh[1], t.b,
              Transform.rotate(angle: -0.05, alignment: Alignment.center, child: fillIcon(Icons.calendar_month, t.dark)),
              _openCalendar, borderWidth: 6),
            block(x3, y1, x4 + c4 - x3, rh[1] + gap + rh[2], t.a,
              _pizarronBlockContent(t, w),
              _openPizarron, borderWidth: 5),
            block(x2, y2, c2, rh[2] + gap + rh[3], t.e,
              Transform.rotate(angle: 0.07, alignment: Alignment.center,
                child: FittedBox(fit: BoxFit.contain, child: SizedBox(width: 120, height: 120,
                  child: Stack(alignment: Alignment.center, children: [
                    Icon(Icons.favorite, color: t.light, size: 110),
                    Icon(Icons.people, color: t.dark, size: 50),
                  ]),
                )),
              ), _openNosotros, borderWidth: 5),
            block(x3, y3, c3, rh[3], t.c,
              Transform.rotate(angle: -0.1, alignment: Alignment.center,
                child: Padding(padding: EdgeInsets.all(w * 0.02),
                  child: Container(decoration: BoxDecoration(color: t.dark, borderRadius: BorderRadius.circular(14)), child: fillIcon(Icons.camera_alt, t.b))),
              ), _openGaleria, borderWidth: 4),
            block(x2, y4, x4 - x2 - gap, rh[4], t.dark,
              Row(children: [
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.style, t.c, t: t, onTap: () => _openMazo(0, 0), onDown: _confettiGlobal))),
                gapW(6),
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.quiz, t.b, t: t, onTap: () => _openTrivia(0, 0), onDown: _confettiGlobal))),
                gapW(6),
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.music_note, t.a, t: t, onTap: () => _openMusic(0, 0), onDown: _confettiGlobal))),
              ]), (x, y) {}, borderWidth: 5),
            Positioned(left: x2, top: y5, width: x4 - x2 - gap, height: rh[5],
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
            if (!_showDeck && !_showPoemas) ...[
              xFloating(w, h),
              _buildBottomSlidingDrawer(t, (y5 + rh[5]) / 2, (w * 0.75).clamp(280.0, 420.0), c1),
              _buildTopSlidingDrawer(t, (y5 + rh[5]) / 2, (w * 0.75).clamp(280.0, 420.0), c1),
            ],
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
        borderRadius: BorderRadius.circular(12),
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
      decoration: BoxDecoration(color: theme.a,
        borderRadius: BorderRadius.circular(18)),
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
          borderRadius: BorderRadius.circular(18)),
        child: child,
      ),
    ),
  ));
}

Widget _pizarronBlockContent(ThemeSet t, double w) {
  return Center(
    child: Icon(
      Icons.space_dashboard_rounded,
      color: t.dark,
      size: w * 0.26,
    ),
  );
}

Widget miniIcon(IconData icon, Color color, {required ThemeSet t, VoidCallback? onTap, ValueChanged<Offset>? onDown}) {
  final inner = Container(
    decoration: BoxDecoration(color: t.mid, borderRadius: BorderRadius.circular(10)),
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
        decoration: BoxDecoration(color: color,
          borderRadius: BorderRadius.circular(18)),
        child: Padding(padding: const EdgeInsets.all(8), child: fillIcon(icon, iconColor)),
      ),
    ),
    ),
  );
}

Widget tbLine({required Color color, required Color borderColor}) {
  return Container(
    width: 22,
    height: 14,
    margin: const EdgeInsets.symmetric(vertical: 3.5),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: borderColor, width: 2),
      borderRadius: BorderRadius.circular(7),
    ),
  );
}

/// Panel de notificaciones que se desliza desde la izquierda. Lista las
/// notificaciones (leídas/no leídas), permite abrir y darse por aludido.
class _NotificationPanel extends StatefulWidget {
  final ThemeSet theme;
  const _NotificationPanel({super.key, required this.theme});

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
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    if (mounted) {
      setState(() {
        for (final n in _items) {
          n['read'] = true;
        }
      });
    }
  }

  String _formatTitle(String? rawTitle) {
    final title = (rawTitle ?? '').trim();
    final myName = (AppState.myName ?? AppState.identity ?? 'Yo').trim();
    final partnerName = AppState.partnerName;

    if (_matchesName(title, myName)) {
      return partnerName;
    }
    return title.isNotEmpty ? title : partnerName;
  }

  String _formatBody(String? rawBody) {
    String body = (rawBody ?? '').trim();
    if (body.isEmpty) return '';

    final myName = (AppState.myName ?? AppState.identity ?? 'Yo').trim();
    final partnerName = AppState.partnerName;

    final myVariants = [myName, myName.replaceAll('í', 'i').replaceAll('Í', 'I')];
    for (final v in myVariants) {
      if (v.isNotEmpty && body.contains(v)) {
        body = body.replaceAll(v, partnerName);
      }
    }
    return body;
  }

  bool _matchesName(String text, String name) {
    if (text.isEmpty || name.isEmpty) return false;
    final t = text.trim().toLowerCase().replaceAll('í', 'i');
    final n = name.trim().toLowerCase().replaceAll('í', 'i');
    return t == n;
  }

  void _open(Map<String, dynamic> n) {
    final id = (n['id'] as num?)?.toInt();
    if (id != null) {
      NotificationService.markAsRead(id);
    }
    if (mounted) setState(() => n['read'] = true);
    final type = (n['data'] is Map) ? (n['data'] as Map)['type'] as String? : null;
    final route = type == null ? null : routeForNotificationType(type);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(_formatTitle(n['title']?.toString()),
            style: GoogleFonts.bangers(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(_formatBody(n['body']?.toString()),
            style: GoogleFonts.bangers(fontSize: 14, color: Colors.white70)),
        actions: [
          if (route != null)
            TapTile(
              onTap: () {
                Navigator.pop(ctx);
                context.push(route);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: widget.theme.b, borderRadius: BorderRadius.circular(10)),
                child: Text('VER', style: GoogleFonts.bangers(color: Colors.white, fontSize: 13)),
              ),
            ),
          TapTile(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF242424), borderRadius: BorderRadius.circular(10)),
              child: Text('CERRAR', style: GoogleFonts.bangers(color: Colors.white70, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Material(
      color: const Color(0xFF101010),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(height: 1, color: t.d),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Icon(Icons.notifications_rounded, color: t.a, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'NOTIFICACIONES',
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (_items.any((n) => n['read'] != true))
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Text(
                          'LEER TODAS',
                          style: GoogleFonts.bangers(
                            color: t.b,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _body(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeSet t) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            TapTile(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: t.a, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.refresh, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, color: Colors.white38, size: 48),
            const SizedBox(height: 8),
            Text(
              'SIN NOTIFICACIONES',
              style: GoogleFonts.bangers(color: Colors.white38, fontSize: 14, letterSpacing: 1),
            ),
          ],
        ),
      );
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
              ),
              child: Row(children: [
                Icon(read ? Icons.mark_email_read : Icons.markunread, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_formatTitle(n['title']?.toString()), maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                  if ((n['body']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_formatBody(n['body']?.toString()), maxLines: 2, overflow: TextOverflow.ellipsis,
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

class _ShortcutDef {
  final String label;
  final IconData icon;
  final String action;
  const _ShortcutDef(this.label, this.icon, this.action);
}

const _homeShortcuts = [
  _ShortcutDef('Cartas', Icons.mail_rounded, 'open_letters'),
  _ShortcutDef('Escribir Carta', Icons.edit_note_rounded, 'write_letter'),
  _ShortcutDef('Agendar Escuela', Icons.school_rounded, 'schedule_school'),
  _ShortcutDef('Música', Icons.headphones_rounded, 'open_music'),
  _ShortcutDef('Playlists', Icons.queue_music_rounded, 'open_playlists'),
  _ShortcutDef('Buscar Música', Icons.youtube_searched_for_rounded, 'search_music'),
  _ShortcutDef('Actualizar GPS', Icons.my_location_rounded, 'update_gps'),
  _ShortcutDef('Ver Mapa', Icons.map_rounded, 'open_map'),
  _ShortcutDef('Metas', Icons.emoji_events_rounded, 'open_metas'),
  _ShortcutDef('Retos', Icons.flag_rounded, 'open_retos'),
  _ShortcutDef('Recompensas', Icons.card_giftcard_rounded, 'open_rewards'),
  _ShortcutDef('Logros', Icons.military_tech_rounded, 'open_achievements'),
  _ShortcutDef('Nuevo Ejercicio', Icons.fitness_center_rounded, 'log_workout'),
];

Color _shortcutColor(ThemeSet t, int i) {
  final palette = [t.a, t.b, t.c, t.d, t.e];
  return palette[i % palette.length];
}

class _ShortcutPanel extends StatelessWidget {
  final ThemeSet theme;
  final List<String> userShortcuts;
  final ValueChanged<String> onAction;
  final VoidCallback onManageShortcuts;

  const _ShortcutPanel({
    required this.theme,
    required this.userShortcuts,
    required this.onAction,
    required this.onManageShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final activeDefs = <_ShortcutDef>[];
    for (final action in userShortcuts) {
      final def = _homeShortcuts.firstWhere(
        (s) => s.action == action,
        orElse: () => const _ShortcutDef('', Icons.help_outline, ''),
      );
      if (def.action.isNotEmpty) {
        activeDefs.add(def);
      }
    }

    return Material(
      color: const Color(0xFF101010),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(height: 1, color: t.d),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded, color: t.b, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'ATAJOS',
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: activeDefs.isEmpty
                    ? Center(
                        child: TapTile(
                          onTap: onManageShortcuts,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: t.b,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_rounded, color: Colors.white, size: 44),
                                const SizedBox(height: 6),
                                Text(
                                  'ATAJOS',
                                  style: GoogleFonts.bangers(
                                    color: Colors.white,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : GridView.count(
                        crossAxisCount: 3,
                        padding: const EdgeInsets.all(12),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          for (var i = 0; i < activeDefs.length; i++)
                            _scItem(
                              activeDefs[i].icon,
                              activeDefs[i].label,
                              _shortcutColor(t, i),
                              () => onAction(activeDefs[i].action),
                            ),
                          TapTile(
                            onTap: onManageShortcuts,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF242424),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, color: t.b, size: 30),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ATAJOS',
                                    style: GoogleFonts.bangers(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _scItem(IconData icon, String label, Color color, VoidCallback onTap) {
  return TapTile(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: color,
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
