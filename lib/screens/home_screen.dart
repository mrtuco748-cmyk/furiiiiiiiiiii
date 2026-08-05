import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import '../supabase_config.dart';
import '../theme/app_theme.dart';
import '../widgets/tap_tile.dart';
import '../widgets/mode_btn.dart';
import '../widgets/concrete_painter.dart';
import '../services/notification_service.dart';
import '../providers/schedule_provider.dart';
import 'nosotros_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'calendar/calendar_home_screen.dart';
import 'calendar/class_setup_wizard.dart';

import 'finanzas/finanzas_screen.dart';
import 'galeria/galeria_screen.dart';
import 'favoritos/favoritos_screen.dart';
import 'pizarra/pizarra_screen.dart';

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

class _BrutalGridState extends State<_BrutalGrid> {
  AppMode _mode = AppState.identity == 'Rocio'
      ? AppMode.dark : AppState.identity == 'Facu' ? AppMode.blue : AppMode.flower;
  int _unreadNotifications = 0;

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

  Future<void> _checkClassSetup() async {
    try {
      final res = await SupabaseConfig.client.from('schedules').select('id').eq('type', 'Clase').limit(1);
      if ((res as List).isEmpty && mounted) {
        final result = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const ClassSetupWizard()));
        if (result == true) {
          final pv = context.read<ScheduleProvider>();
          if (mounted) pv.loadSchedules();
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    NotificationService.startListening();
    _loadUnread();
    _loadMode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClassSetup());
  }

  Future<void> _loadUnread() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifications = count);
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(mode: _mode),
    ));
  }

  void _openNotifications() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NotificationsScreen(mode: _mode),
    )).then((_) => _loadUnread());
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NosotrosScreen(
        myId: AppState.myId ?? '', partnerId: AppState.partnerId, mode: _mode,
      ),
    ));
  }

  void _confettiAt(double x, double y) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final global = box.localToGlobal(Offset(x, y));
    final screen = MediaQuery.of(context).size;
    Confetti.launch(context, options: ConfettiOptions(
      particleCount: 25, spread: 60, startVelocity: 50, gravity: 0.8, decay: 0.92,
      x: global.dx / screen.width, y: global.dy / screen.height,
      colors: const [Color(0xFFFFDE59), Color(0xFF00F0FF), Color(0xFFFF5757), Color(0xFF00FF66), Color(0xFF7000FF), Color(0xFFFF66C4)],
    ));
  }

  void _openCalendar(double x, double y) {
    _confettiAt(x, y);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const CalendarHomeScreen(),
    ));
  }

  void _openEstudio(double x, double y) {
    _confettiAt(x, y);
  }

  void _openFinanzas(double x, double y) {
    _confettiAt(x, y);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const FinanzasScreen(),
    ));
  }

  void _openGaleria(double x, double y) {
    _confettiAt(x, y);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const GaleriaScreen(),
    ));
  }

  void _openFavoritos(double x, double y) {
    _confettiAt(x, y);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const FavoritosScreen(),
    ));
  }

  void _openPizarra(double x, double y) {
    _confettiAt(x, y);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const PizarraScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
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
            block(0, 0, c1, y5 + rh[5], t.d, LeftButtons(t: t, onTopTap: () => _confettiAt(0, 0), onBottomTap: () => _confettiAt(0, 0)), _confettiAt, borderWidth: 4),
            block(x2, 0, x4 - x2, rh[0], t.a,
              Center(child: Text(AppState.identity == 'Rocio' ? 'Mis Cosas' : 'Herramientas',
                style: GoogleFonts.bangers(color: t.light, fontWeight: FontWeight.bold, fontSize: w * 0.055))),
              _confettiAt, borderWidth: 5),
            block(x4, 0, c4, rh[0], t.dark, notificationBadge(t, _unreadNotifications, _openNotifications), (x, y) => _openSettings(), borderWidth: 3),
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
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.play_arrow, t.d, t: t))),
                gapW(6),
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.image, t.a, t: t))),
                gapW(6),
                Expanded(child: Padding(padding: EdgeInsets.all(w * 0.01), child: miniIcon(Icons.play_arrow, t.b, t: t))),
              ]), _confettiAt, borderWidth: 5),
            Positioned(left: x2, top: y5, width: x4 - x2, height: rh[5],
              child: Row(children: [
                Expanded(flex: 6, child: bottomBtn(t.d, Icons.spa, t.dark, 5, _confettiAt)),
                gapW(6),
                Expanded(flex: 10, child: bottomBtn(t.a, Icons.bar_chart, t.light, 6, _openFinanzas)),
                gapW(6),
                Expanded(flex: 11, child: bottomBtn(t.b, Icons.star, t.dark, 4, _openFavoritos)),
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
          ],
        ));
      },
    );
  }
}

Widget notificationBadge(ThemeSet t, int count, VoidCallback onTapNotif) {
  return Stack(alignment: Alignment.center, children: [
    Transform.rotate(angle: 0.1, alignment: Alignment.center, child: fillIcon(Icons.settings, t.a)),
    Positioned(right: 6, bottom: 6, child: GestureDetector(
      onTap: onTapNotif,
      child: Stack(children: [
        Icon(Icons.notifications, color: t.light, size: 22),
        if (count > 0) Positioned(right: -4, top: -4, child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: t.e, shape: BoxShape.circle, border: Border.all(color: t.dark, width: 2)),
          child: Text(count > 9 ? '9+' : '$count',
            style: GoogleFonts.bangers(fontSize: 10, fontWeight: FontWeight.bold, color: t.light)),
        )),
      ]),
    )),
  ]);
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

Widget miniIcon(IconData icon, Color color, {required ThemeSet t}) {
  return Container(
    decoration: BoxDecoration(color: t.mid, border: Border.all(color: t.mid, width: 3), borderRadius: BorderRadius.circular(10)),
    child: fillIcon(icon, color),
  );
}

Widget bottomBtn(Color color, IconData icon, Color iconColor, int bw, void Function(double x, double y) onTap) {
  return TapTile(
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
  );
}

class LeftButtons extends StatelessWidget {
  final ThemeSet t;
  final VoidCallback onTopTap;
  final VoidCallback onBottomTap;
  const LeftButtons({super.key, required this.t, required this.onTopTap, required this.onBottomTap});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: TapTile(
        onTap: onTopTap,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Container(color: const Color(0xFFFFDE59), child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (_) => tbLine(t)),
          )),
        ),
      )),
      const SizedBox(height: 6),
      Expanded(child: TapTile(
        onTap: onBottomTap,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
          child: Container(color: const Color(0xFF00F0FF), child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (_) => tbLine(t)),
          )),
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
