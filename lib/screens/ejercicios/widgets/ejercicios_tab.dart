import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app_state.dart';
import '../../../models/workout_log.dart';
import '../../../providers/workout_provider.dart';
import '../ejercicios_style.dart';
import 'common.dart';

class EjerciciosTab extends StatelessWidget {
  final double w;
  final double h;
  final WorkoutProvider pv;
  final void Function(WorkoutLog log) onLogTap;
  final void Function(WorkoutLog log) onLogLongPress;

  const EjerciciosTab({
    super.key,
    required this.w,
    required this.h,
    required this.pv,
    required this.onLogTap,
    required this.onLogLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (pv.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center,
                color: EjerciciosStyle.white.withValues(alpha: 0.35), size: 48),
            const SizedBox(height: 8),
            Text(
              'Sin ejercicios registrados',
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
        for (final log in pv.logs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: LogCard(
              w: w,
              log: log,
              pv: pv,
              onTap: () => onLogTap(log),
              onLongPress: () => onLogLongPress(log),
            ),
          ),
      ],
    );
  }
}

class LogCard extends StatelessWidget {
  final double w;
  final WorkoutLog log;
  final WorkoutProvider pv;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LogCard({
    super.key,
    required this.w,
    required this.log,
    required this.pv,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final mine = log.userId == pv.myId;
    final initial = mine
        ? (AppState.identity?.substring(0, 1).toUpperCase() ?? '?')
        : (AppState.identity == 'Facu' ? 'R' : 'F');
    final userColor = mine
        ? (AppState.identity == 'Facu'
            ? EjerciciosStyle.facuColor
            : EjerciciosStyle.rocioColor)
        : (AppState.identity == 'Facu'
            ? EjerciciosStyle.rocioColor
            : EjerciciosStyle.facuColor);
    final reactions = log.social.reactions;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: EjerciciosStyle.panelDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: userColor,
                    border: Border.all(color: userColor, width: 2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    initial,
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.bg,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.exerciseName,
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (log.summary.isNotEmpty)
                  Text(
                    log.summary,
                    style:
                        GoogleFonts.bangers(color: EjerciciosStyle.cyan, fontSize: 12),
                  ),
              ],
            ),
            if (log.muscleGroup != null) ...[
              const SizedBox(height: 4),
              Text(
                log.muscleGroup!,
                style: GoogleFonts.bangers(
                  color: EjerciciosStyle.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
            if (reactions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  for (final e in reactions.entries)
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