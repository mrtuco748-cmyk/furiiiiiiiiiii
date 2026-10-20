import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/couple_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/concrete_painter.dart';
import '../../../widgets/tap_tile.dart';

const confettiColors = [
  Color(0xFFFFDE59),
  Color(0xFF00F0FF),
  Color(0xFFFF5757),
  Color(0xFF00FF66),
  Color(0xFF7000FF),
  Color(0xFFFF66C4),
];

void confettiColorsFor(BuildContext ctx, {required double x, required double y}) {
  final screen = MediaQuery.of(ctx).size;
  Confetti.launch(
    ctx,
    options: ConfettiOptions(
      particleCount: 25,
      spread: 60,
      startVelocity: 50,
      gravity: 0.8,
      decay: 0.92,
      x: (x / screen.width).clamp(0.05, 0.95),
      y: (y / screen.height).clamp(0.05, 0.95),
      colors: confettiColors,
    ),
  );
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Color(0xFFFFDE59),
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            '${pv.coupleStreak}',
            style: GoogleFonts.bangers(
              color: t.light,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget modosBlock(double l, double t, double w, double h, ThemeSet theme, List<Widget> btns) {
  return Positioned(
    left: l,
    top: t,
    width: w,
    height: h,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: theme.a, borderRadius: BorderRadius.circular(18)),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: btns),
      ),
    ),
  );
}

Widget gapW(double w) => SizedBox(width: w);

Widget fillIcon(IconData icon, Color color) {
  return FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)),
  );
}

Widget bg(double w, double h) {
  return Positioned.fill(child: CustomPaint(painter: ConcretePainter()));
}

Widget xFloating(double w, double h) {
  return Positioned(
    right: w * 0.02,
    top: h * 0.45,
    child: Transform.rotate(
      angle: 0.3,
      child: Container(width: 4, height: 30, color: const Color(0xFFFFDE59)),
    ),
  );
}

Widget block(
  double l,
  double t,
  double w,
  double h,
  Color bg,
  Widget child,
  void Function(double x, double y) onTap, {
  int borderWidth = 3,
}) {
  return Positioned(
    left: l,
    top: t,
    width: w,
    height: h,
    child: TapTile(
      onTap: () => onTap(l + w / 2, t + h / 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
          child: child,
        ),
      ),
    ),
  );
}

Widget pizarronBlockContent(ThemeSet t, double w) {
  return Center(
    child: Icon(
      Icons.space_dashboard_rounded,
      color: t.dark,
      size: w * 0.26,
    ),
  );
}

Widget miniIcon(
  IconData icon,
  Color color, {
  required ThemeSet t,
  VoidCallback? onTap,
  ValueChanged<Offset>? onDown,
}) {
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

Widget bottomBtn(
  Color color,
  IconData icon,
  Color iconColor,
  int bw,
  void Function(double x, double y) onTap,
  ValueChanged<Offset>? onDown,
) {
  return GestureDetector(
    onTapDown: onDown == null ? null : (d) => onDown(d.globalPosition),
    child: TapTile(
      onTap: () => onTap(0, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
          child: Padding(padding: const EdgeInsets.all(8), child: fillIcon(icon, iconColor)),
        ),
      ),
    ),
  );
}
