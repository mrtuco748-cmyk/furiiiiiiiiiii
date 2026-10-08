import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app_state.dart';
import '../../../models/workout_challenge.dart';
import '../../../providers/workout_provider.dart';
import '../ejercicios_style.dart';
import 'common.dart';

String? _facuId(WorkoutProvider pv) =>
    AppState.identity == 'Facu' ? pv.myId : pv.partnerId;
String? _rocioId(WorkoutProvider pv) =>
    AppState.identity == 'Rocio' ? pv.myId : pv.partnerId;

class RetosTab extends StatelessWidget {
  final double w;
  final double h;
  final WorkoutProvider pv;
  final void Function(WorkoutChallenge c) onChallengeTap;
  final void Function(WorkoutChallenge c) onChallengeLongPress;

  const RetosTab({
    super.key,
    required this.w,
    required this.h,
    required this.pv,
    required this.onChallengeTap,
    required this.onChallengeLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (pv.challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag,
                color: EjerciciosStyle.white.withValues(alpha: 0.35), size: 48),
            const SizedBox(height: 8),
            Text(
              'Sin retos todavía',
              style: GoogleFonts.bangers(
                color: EjerciciosStyle.white.withValues(alpha: 0.45),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.only(bottom: h * 0.14),
      children: [
        for (final c in pv.challenges)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: ChallengeCard(
              w: w,
              c: c,
              pv: pv,
              onTap: () => onChallengeTap(c),
              onLongPress: () => onChallengeLongPress(c),
            ),
          ),
      ],
    );
  }
}

class ChallengeCard extends StatelessWidget {
  final double w;
  final WorkoutChallenge c;
  final WorkoutProvider pv;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChallengeCard({
    super.key,
    required this.w,
    required this.c,
    required this.pv,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final mine = c.createdBy == pv.myId;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: EjerciciosStyle.panelDeco(
          color: c.isCompleted ? EjerciciosStyle.panelLight : EjerciciosStyle.panel,
          borderColor: c.isApproved ? EjerciciosStyle.cyan : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  c.isCompleted
                      ? Icons.emoji_events
                      : (c.isApproved ? Icons.flag : Icons.outlined_flag),
                  color: c.isCompleted ? EjerciciosStyle.cyan : EjerciciosStyle.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.title,
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: c.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (mine)
                  const Icon(Icons.person, color: EjerciciosStyle.facuColor, size: 16),
              ],
            ),
            if (c.description != null) ...[
              const SizedBox(height: 4),
              Text(
                c.description!,
                style: GoogleFonts.bangers(
                  color: EjerciciosStyle.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                DoneBadge('F', c.approvedByUser(_facuId(pv) ?? ''), EjerciciosStyle.facuColor),
                const SizedBox(width: 4),
                DoneBadge('R', c.approvedByUser(_rocioId(pv) ?? ''), EjerciciosStyle.rocioColor),
                const SizedBox(width: 8),
                Text(
                  'aprobado',
                  style: GoogleFonts.bangers(
                    color: EjerciciosStyle.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 10),
                DoneBadge('F', c.completedByUser(_facuId(pv) ?? ''), EjerciciosStyle.facuColor),
                const SizedBox(width: 4),
                DoneBadge('R', c.completedByUser(_rocioId(pv) ?? ''), EjerciciosStyle.rocioColor),
                const SizedBox(width: 8),
                Text(
                  'hecho',
                  style: GoogleFonts.bangers(
                    color: EjerciciosStyle.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (c.social.reactions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  for (final e in c.social.reactions.entries)
                    ReactionChip(e.key, e.value.length),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}