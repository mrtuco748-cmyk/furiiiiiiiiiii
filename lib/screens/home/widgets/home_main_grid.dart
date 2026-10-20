import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../providers/couple_provider.dart';
import '../../../services/settings_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/mode_btn.dart';
import '../../../widgets/responsive_wrapper.dart';
import '../helpers/home_drawer_drag_handler.dart';
import 'home_grid_overlays.dart';
import 'home_grid_tiles.dart';

class HomeMainGrid extends StatelessWidget {
  final AppMode mode;
  final ThemeSet theme;
  final HomeDrawerDragHandler drawerHandler;
  final List<String> userShortcuts;
  final bool showDeck;
  final bool showPoemas;
  final VoidCallback onOpenSettings;
  final void Function(double x, double y) onOpenCalendar;
  final void Function(double x, double y) onOpenPizarron;
  final void Function(double x, double y) onOpenNosotros;
  final void Function(double x, double y) onOpenGaleria;
  final void Function(double x, double y) onOpenMazo;
  final void Function(double x, double y) onOpenTrivia;
  final void Function(double x, double y) onOpenMusic;
  final void Function(double x, double y) onOpenEjercicios;
  final void Function(double x, double y) onOpenFinanzas;
  final void Function(double x, double y) onOpenFavoritos;
  final VoidCallback onOpenLogros;
  final void Function(AppMode mode, Offset g) onModeTap;
  final void Function(double x, double y) onConfettiAt;
  final ValueChanged<Offset> onConfettiGlobal;
  final ValueChanged<String> onShortcutAction;
  final VoidCallback onManageShortcuts;
  final VoidCallback onCloseDeck;
  final VoidCallback onClosePoemas;

  const HomeMainGrid({
    super.key,
    required this.mode,
    required this.theme,
    required this.drawerHandler,
    required this.userShortcuts,
    required this.showDeck,
    required this.showPoemas,
    required this.onOpenSettings,
    required this.onOpenCalendar,
    required this.onOpenPizarron,
    required this.onOpenNosotros,
    required this.onOpenGaleria,
    required this.onOpenMazo,
    required this.onOpenTrivia,
    required this.onOpenMusic,
    required this.onOpenEjercicios,
    required this.onOpenFinanzas,
    required this.onOpenFavoritos,
    required this.onOpenLogros,
    required this.onModeTap,
    required this.onConfettiAt,
    required this.onConfettiGlobal,
    required this.onShortcutAction,
    required this.onManageShortcuts,
    required this.onCloseDeck,
    required this.onClosePoemas,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return ResponsiveWrapper(
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
          (h - 5 * gap) * 0.127,
          (h - 5 * gap) * 0.218,
          (h - 5 * gap) * 0.218,
          (h - 5 * gap) * 0.114,
          (h - 5 * gap) * 0.114,
          (h - 5 * gap) * 0.209,
        ];
        final y1 = rh[0] + gap;
        final y2 = y1 + rh[1] + gap;
        final y3 = y2 + rh[2] + gap;
        final y4 = y3 + rh[3] + gap;
        final y5 = y4 + rh[4] + gap;

        final drawerHeight = (y5 + rh[5]) / 2;
        final drawerWidth = (w * 0.75).clamp(280.0, 420.0);

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              bg(w, h),
              Consumer<CoupleProvider>(
                builder: (context, couplePv, _) {
                  final zenMode = Provider.of<SettingsService>(context, listen: false).zenMode;
                  if (zenMode) return const SizedBox.shrink();
                  return Positioned(
                    right: c4 * 0.15,
                    top: 4,
                    child: coupleTile(couplePv, t, onTap: onOpenLogros),
                  );
                },
              ),
              Positioned(
                left: 0,
                top: 0,
                width: c1,
                height: y5 + rh[5],
                child: Container(
                  decoration: BoxDecoration(color: t.mid, borderRadius: BorderRadius.circular(18)),
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
              block(
                x2, 0, x4 - x2, rh[0], t.a,
                Center(
                  child: Text(
                    AppState.identity == 'Rocio' ? 'Mis Cosas' : 'Herramientas',
                    style: GoogleFonts.bangers(color: t.light, fontWeight: FontWeight.bold, fontSize: w * 0.055),
                  ),
                ),
                onConfettiAt,
                borderWidth: 5,
              ),
              block(x4, 0, c4, rh[0], t.dark, fillIcon(Icons.settings, t.light), (x, y) => onOpenSettings(), borderWidth: 3),
              block(
                x2, y1, c2, rh[1], t.b,
                Transform.rotate(angle: -0.05, alignment: Alignment.center, child: fillIcon(Icons.calendar_month, t.dark)),
                onOpenCalendar,
                borderWidth: 6,
              ),
              block(x3, y1, x4 + c4 - x3, rh[1] + gap + rh[2], t.a, pizarronBlockContent(t, w), onOpenPizarron, borderWidth: 5),
              block(
                x2, y2, c2, rh[2] + gap + rh[3], t.e,
                Transform.rotate(
                  angle: 0.07,
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.favorite, color: t.light, size: 110),
                          Icon(Icons.people, color: t.dark, size: 50),
                        ],
                      ),
                    ),
                  ),
                ),
                onOpenNosotros,
                borderWidth: 5,
              ),
              block(
                x3, y3, c3, rh[3], t.c,
                Transform.rotate(
                  angle: -0.1,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.02),
                    child: Container(
                      decoration: BoxDecoration(color: t.dark, borderRadius: BorderRadius.circular(14)),
                      child: fillIcon(Icons.camera_alt, t.b),
                    ),
                  ),
                ),
                onOpenGaleria,
                borderWidth: 4,
              ),
              block(
                x2, y4, x4 - x2 - gap, rh[4], t.dark,
                Row(children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(w * 0.01),
                      child: miniIcon(Icons.style, t.c, t: t, onTap: () => onOpenMazo(0, 0), onDown: onConfettiGlobal),
                    ),
                  ),
                  gapW(6),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(w * 0.01),
                      child: miniIcon(Icons.quiz, t.b, t: t, onTap: () => onOpenTrivia(0, 0), onDown: onConfettiGlobal),
                    ),
                  ),
                  gapW(6),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(w * 0.01),
                      child: miniIcon(Icons.music_note, t.a, t: t, onTap: () => onOpenMusic(0, 0), onDown: onConfettiGlobal),
                    ),
                  ),
                ]),
                (x, y) {},
                borderWidth: 5,
              ),
              Positioned(
                left: x2,
                top: y5,
                width: x4 - x2 - gap,
                height: rh[5],
                child: Row(children: [
                  Expanded(
                    flex: 6,
                    child: bottomBtn(
                      const Color(0xFF39FF14),
                      Icons.fitness_center,
                      const Color(0xFF062B06),
                      5,
                      onOpenEjercicios,
                      onConfettiGlobal,
                    ),
                  ),
                  gapW(6),
                  Expanded(
                    flex: 10,
                    child: bottomBtn(t.a, Icons.bar_chart, t.light, 6, onOpenFinanzas, onConfettiGlobal),
                  ),
                  gapW(6),
                  Expanded(
                    flex: 11,
                    child: bottomBtn(t.b, Icons.star, t.dark, 4, onOpenFavoritos, onConfettiGlobal),
                  ),
                ]),
              ),
              modosBlock(x4, y3, c4, rh[3] + gap + rh[4], t, [
                ModeBtn(AppMode.flower, Icons.local_florist, mode == AppMode.flower, onModeTap),
                ModeBtn(AppMode.green, Icons.circle, mode == AppMode.green, onModeTap, iconColor: const Color(0xFF39FF14)),
                ModeBtn(AppMode.dark, Icons.dark_mode, mode == AppMode.dark, onModeTap),
              ]),
              modosBlock(x4, y5, c4, rh[5], t, [
                ModeBtn(AppMode.blue, Icons.circle, mode == AppMode.blue, onModeTap, iconColor: const Color(0xFF00E5FF)),
                ModeBtn(AppMode.heart, Icons.favorite, mode == AppMode.heart, onModeTap),
              ]),
              HomeGridOverlays(
                theme: t,
                drawerHeight: drawerHeight,
                drawerWidth: drawerWidth,
                c1: c1,
                screenWidth: w,
                screenHeight: h,
                drawerHandler: drawerHandler,
                userShortcuts: userShortcuts,
                onShortcutAction: onShortcutAction,
                onManageShortcuts: onManageShortcuts,
                showDeck: showDeck,
                showPoemas: showPoemas,
                onCloseDeck: onCloseDeck,
                onClosePoemas: onClosePoemas,
              ),
            ],
          ),
        );
      },
    );
  }
}
