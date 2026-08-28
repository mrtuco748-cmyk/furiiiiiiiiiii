import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/couple_achievement.dart';
import '../../providers/couple_achievements_provider.dart';
import '../../router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loca_screen.dart';

/// Logros estilo "Nosotros": un bloque por logro (check = desbloqueado, candado
/// = pendiente), tile de conteo con swap ("X de N"), y la cajita de recompensas
/// como acción fija en la columna lateral.
class LogrosScreen extends StatefulWidget {
  final AppMode mode;
  const LogrosScreen({super.key, required this.mode});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CoupleAchievementsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Consumer<CoupleAchievementsProvider>(
      builder: (context, pv, _) {
        final earned = pv.earnedCodes;
        final all = CoupleAchievements.all;
        final entries = <LocaEntry>[
          LocaEntry(
            icon: Icons.emoji_events,
            color: const Color(0xFFFFD700),
            iconColor: const Color(0xFF1A1A1A),
            swapBuilder: (_) => _countSwap(earned.length, all.length, t),
            autoPlaySwap: true,
          ),
          if (pv.hasError)
            LocaEntry(
              icon: Icons.cloud_off,
              color: const Color(0xFFFF0000),
              onTap: () => context.read<CoupleAchievementsProvider>().load(),
            ),
          for (var i = 0; i < all.length; i++)
            LocaEntry(
              icon: earned.contains(all[i].code) ? Icons.check_circle : Icons.lock,
              color: earned.contains(all[i].code) ? t.c : const Color(0xFF252525),
              iconColor: earned.contains(all[i].code) ? Colors.white : const Color(0xFF666666),
              label: all[i].title,
              panel: i,
            ),
          LocaEntry(
            icon: Icons.card_giftcard,
            color: const Color(0xFFFFD700),
            iconColor: const Color(0xFF1A1A1A),
            label: 'recompensas',
            onTap: () => context.push(RouterRoutes.rewards, extra: widget.mode),
            isAction: true,
          ),
        ];
        return LocaScreen(
          seed: 31,
          theme: t,
          entries: entries,
          panels: [
            for (var i = 0; i < all.length; i++)
              (_, close) => _achPanel(close, all[i], earned.contains(all[i].code), t),
          ],
        );
      },
    );
  }

  Widget _countSwap(int earned, int total, ThemeSet t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$earned / $total', style: GoogleFonts.bangers(color: t.light, fontSize: 30, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }

  Widget _achPanel(VoidCallback close, CoupleAchievement def, bool earned, ThemeSet t) {
    return LocaScreen.panel(
      color: earned ? t.c : const Color(0xFF252525),
      borderColor: earned ? t.c : const Color(0xFF252525),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(children: [
            Icon(Icons.emoji_events, color: earned ? Colors.white : const Color(0xFF555555), size: 22),
            const Spacer(),
            LocaScreen.closeIcon(close, earned ? t.c : const Color(0xFF3A3A3A), Icons.close),
          ]),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(def.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(def.title, textAlign: TextAlign.center,
                    style: GoogleFonts.bangers(color: earned ? Colors.white : const Color(0xFF777777), fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(def.description, textAlign: TextAlign.center,
                    style: TextStyle(color: earned ? t.light : const Color(0xFF888888), fontSize: 13)),
                ]),
              ),
            ),
          ),
        ),
        if (!earned) ...[
          const SizedBox(height: 2),
          Text('Pendiente · toca de nuevo', style: GoogleFonts.bangers(color: const Color(0xFF666666), fontSize: 12)),
        ],
        const SizedBox(height: 12),
      ]),
    );
  }
}