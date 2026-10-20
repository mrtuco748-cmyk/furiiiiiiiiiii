import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/workout_log.dart';
import '../../../models/workout_routine.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';
import 'comments_block.dart';
import 'common.dart';
import 'improvement_block.dart';

void showLogDetailSheet({
  required BuildContext context,
  required WorkoutLog log,
  required WorkoutProvider pv,
  required void Function(RoutineItem prefill) onPrefill,
  required void Function(WorkoutLog existing) onEdit,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: EjerciciosStyle.panel,
    barrierColor: Colors.black26,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final live = pv.logs.firstWhere(
            (l) => l.id == log.id,
            orElse: () => log,
          );
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        live.exerciseName,
                        style: GoogleFonts.bangers(
                          color: EjerciciosStyle.cyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TapTile(
                      onTap: () {
                        Navigator.pop(ctx);
                        onPrefill(
                          RoutineItem(
                            exerciseName: live.exerciseName,
                            series: live.series,
                            reps: live.reps,
                            weight: live.weight,
                            restSeconds: live.restSeconds,
                            notes: live.notes,
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.trending_up, color: EjerciciosStyle.cyan, size: 20),
                      ),
                    ),
                    if (live.id != null) ...[
                      const SizedBox(width: 8),
                      TapTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          onEdit(live);
                        },
                        child: const Icon(Icons.edit, color: Color(0xFF00D4FF), size: 20),
                      ),
                      const SizedBox(width: 8),
                      TapTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          confirmDeleteLog(context, live, pv);
                        },
                        child: const Icon(Icons.delete_outline, color: EjerciciosStyle.red, size: 20),
                      ),
                    ],
                    const SizedBox(width: 8),
                    TapTile(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 22),
                    ),
                  ],
                ),
                if (live.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      live.summary,
                      style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ReactionBar(
                  live.social.reactions,
                  (key) async {
                    if (live.id == null) return;
                    final ok = await pv.toggleLogReaction(live.id!, key);
                    setSheetState(() {});
                    if (!ok) {
                      HapticFeedback.heavyImpact();
                    }
                  },
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ImprovementBlock(live: live, pv: pv),
                        const SizedBox(height: 12),
                        CommentsBlock(
                          live.social.comments,
                          (text) {
                            if (live.id != null) {
                              pv.addLogComment(live.id!, text);
                            }
                          },
                          (commentId) {
                            if (live.id != null) {
                              pv.deleteLogComment(live.id!, commentId);
                            }
                          },
                          () => setSheetState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> confirmDeleteLog(BuildContext context, WorkoutLog log, WorkoutProvider pv) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: EjerciciosStyle.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Icon(Icons.delete_forever, color: EjerciciosStyle.red, size: 36),
      content: Text(
        '¿Eliminar "${log.exerciseName}"?',
        style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
      ),
      actions: [
        TapTile(
          onTap: () => Navigator.pop(ctx, false),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EjerciciosStyle.panelLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 20),
          ),
        ),
        TapTile(
          onTap: () => Navigator.pop(ctx, true),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EjerciciosStyle.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: EjerciciosStyle.white, size: 20),
          ),
        ),
      ],
    ),
  );
  if (ok == true && log.id != null) {
    await pv.deleteLog(log.id!);
  }
}
