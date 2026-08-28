import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/rewards.dart';
import '../../providers/rewards_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loca_screen.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/app_feedback.dart';

/// Recompensas estilo "Nosotros": un bloque por recompensa (check = cumplida,
/// círculo = pendiente), tile de balance con swap (saldo/total/cumplidas) y el
/// alta (+) fija en la columna lateral.
class RewardsScreen extends StatefulWidget {
  final AppMode mode;
  const RewardsScreen({super.key, required this.mode});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RewardsProvider>().load();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Consumer<RewardsProvider>(
      builder: (context, pv, _) {
        final rewards = pv.rewards;
        final entries = <LocaEntry>[
          LocaEntry(
            icon: Icons.monetization_on,
            color: const Color(0xFFFFD700),
            iconColor: const Color(0xFF1A1A1A),
            swapBuilder: (_) => _statsSwap(pv, t),
            autoPlaySwap: true,
          ),
          if (pv.hasError && rewards.isEmpty)
            LocaEntry(icon: Icons.cloud_off, color: const Color(0xFFFF0000), onTap: () => context.read<RewardsProvider>().load()),
          for (var i = 0; i < rewards.length; i++)
            LocaEntry(
              icon: rewards[i].fulfilled ? Icons.check_circle : Icons.radio_button_unchecked,
              color: rewards[i].fulfilled ? const Color(0xFF1B5E28) : const Color(0xFF2A2A2A),
              iconColor: rewards[i].fulfilled ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
              label: rewards[i].title,
              panel: i,
            ),
          LocaEntry(
            icon: Icons.add,
            color: const Color(0xFFFFD700),
            iconColor: const Color(0xFF1A1A1A),
            label: 'agregar',
            onTap: _addRewardDialog,
            isAction: true,
          ),
        ];
        return LocaScreen(
          seed: 61,
          theme: t,
          entries: entries,
          panels: [
            for (var i = 0; i < rewards.length; i++)
              (_, close) => _rewardPanel(close, pv, rewards[i], t),
          ],
        );
      },
    );
  }

  Widget _statsSwap(RewardsProvider pv, ThemeSet t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${pv.myBalance} 🪙', style: GoogleFonts.bangers(color: t.light, fontSize: 34, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 6),
          Text('${pv.totalEarned} total · ${pv.fulfilledRewards.length} cumplidas',
            style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.6), fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _rewardPanel(VoidCallback close, RewardsProvider pv, CoupleReward r, ThemeSet t) {
    final ful = r.fulfilled;
    return LocaScreen.panel(
      color: const Color(0xFF2A2A2A),
      borderColor: ful ? const Color(0xFF39FF14) : const Color(0xFFFFD700),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(children: [
            Text(r.emoji, style: const TextStyle(fontSize: 22)),
            const Spacer(),
            LocaScreen.closeIcon(close, ful ? const Color(0xFF39FF14) : const Color(0xFFFFD700), Icons.close),
          ]),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(r.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(r.title, textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('Cuesta ${r.cost} 🪙',
                  style: GoogleFonts.bangers(color: ful ? const Color(0xFF39FF14) : Colors.white54, fontSize: 14)),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Spacer(),
            TapTile(
              onTap: () { HapticFeedback.heavyImpact(); pv.toggleFulfilled(r.id!); if (mounted) AppFeedback.success(context, '¡Deseo cumplido!', celebration: true); },
              child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: ful ? const Color(0xFF39FF14) : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: ful ? const Color(0xFF39FF14) : const Color(0xFF1A1A1A), width: 2)), child: Icon(ful ? Icons.undo : Icons.check, color: ful ? const Color(0xFF1A1A1A) : const Color(0xFF39FF14), size: 24)),
            ),
            const SizedBox(width: 8),
            TapTile(
              onTap: () { HapticFeedback.heavyImpact(); pv.deleteReward(r.id!); },
              child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFCC0000), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCC0000), width: 2)), child: const Icon(Icons.delete, color: Colors.white, size: 24)),
            ),
            const SizedBox(width: 8),
          ]),
        ),
        const SizedBox(height: 14),
      ]),
    );
  }

  Future<void> _addRewardDialog() async {
    _titleCtrl.clear();
    const cost = 10;
    final t = getTheme(widget.mode);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFFFD700), width: 4)),
        title: const Icon(Icons.card_giftcard, color: Colors.white, size: 34),
        content: TextField(
          controller: _titleCtrl,
          autofocus: true,
          style: GoogleFonts.bangers(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '¿Qué se ganan?',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Icon(Icons.close, color: Colors.white, size: 26),
          ),
          TextButton(
            onPressed: () {
              final title = _titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.of(ctx).pop();
              context.read<RewardsProvider>().addReward(title, '🎁', cost);
              if (mounted) AppFeedback.saved(context, 'Recompensa creada');
            },
            child: Icon(Icons.check, color: t.c, size: 28),
          ),
        ],
      ),
    );
  }
}