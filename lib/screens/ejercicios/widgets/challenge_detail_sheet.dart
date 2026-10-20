import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/workout_challenge.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';
import 'comments_block.dart';
import 'common.dart';

void showChallengeDetailSheet({
  required BuildContext context,
  required WorkoutChallenge challenge,
  required WorkoutProvider pv,
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
          final live = pv.challenges.firstWhere(
            (ch) => ch.id == challenge.id,
            orElse: () => challenge,
          );
          final mine = live.createdBy == pv.myId;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        live.title,
                        style: GoogleFonts.bangers(
                          color: EjerciciosStyle.cyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (mine && live.id != null)
                      TapTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          confirmDeleteChallenge(context, live, pv);
                        },
                        child: const Icon(Icons.delete_outline, color: EjerciciosStyle.red, size: 20),
                      ),
                    const SizedBox(width: 8),
                    TapTile(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 22),
                    ),
                  ],
                ),
                if (live.description != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      live.description!,
                      style: GoogleFonts.bangers(
                        color: EjerciciosStyle.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        live.approvedByUser(pv.myId) ? Icons.undo : Icons.how_to_reg,
                        live.approvedByUser(pv.myId) ? EjerciciosStyle.cyan : EjerciciosStyle.panelLight,
                        EjerciciosStyle.white,
                        () async {
                          if (live.id == null) return;
                          await pv.toggleChallengeApproval(live.id!);
                          setSheetState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ActionButton(
                        live.completedByUser(pv.myId) ? Icons.undo : Icons.emoji_events,
                        live.completedByUser(pv.myId) ? EjerciciosStyle.cyan : EjerciciosStyle.panelLight,
                        live.completedByUser(pv.myId) ? EjerciciosStyle.darkText : EjerciciosStyle.white,
                        () async {
                          if (live.id == null) return;
                          await pv.toggleChallengeCompletion(live.id!);
                          setSheetState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ReactionBar(
                  live.social.reactions,
                  (key) async {
                    if (live.id == null) return;
                    final ok = await pv.toggleChallengeReaction(live.id!, key);
                    setSheetState(() {});
                    if (!ok) HapticFeedback.heavyImpact();
                  },
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: CommentsBlock(
                      live.social.comments,
                      (text) {
                        if (live.id != null) {
                          pv.addChallengeComment(live.id!, text);
                        }
                      },
                      (commentId) {
                        if (live.id != null) {
                          pv.deleteChallengeComment(live.id!, commentId);
                        }
                      },
                      () => setSheetState(() {}),
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

Future<void> confirmDeleteChallenge(BuildContext context, WorkoutChallenge challenge, WorkoutProvider pv) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: EjerciciosStyle.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Icon(Icons.delete_forever, color: EjerciciosStyle.red, size: 36),
      content: Text(
        '¿Eliminar el reto "${challenge.title}"?',
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
  if (ok == true && challenge.id != null) {
    await pv.deleteChallenge(challenge.id!);
  }
}
