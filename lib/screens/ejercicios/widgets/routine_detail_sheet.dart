import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/workout_routine.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

void showRoutineDetailSheet({
  required BuildContext context,
  required WorkoutRoutine routine,
  required WorkoutProvider pv,
  required Future<RoutineItem?> Function() onPromptItem,
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
          final live = pv.routines.firstWhere(
            (r) => r.id == routine.id,
            orElse: () => routine,
          );
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      live.name,
                      style: GoogleFonts.bangers(
                        color: EjerciciosStyle.cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TapTile(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (var i = 0; i < live.items.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  live.items[i].exerciseName,
                                  style: GoogleFonts.bangers(
                                    color: EjerciciosStyle.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              TapTile(
                                onTap: () async {
                                  final removed = live.removeItem(i);
                                  await pv.updateRoutine(removed);
                                  setSheetState(() {});
                                },
                                child: const Icon(Icons.close, color: EjerciciosStyle.red, size: 18),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TapTile(
                  onTap: () async {
                    final item = await onPromptItem();
                    if (item == null) return;
                    final updated = pv.routines.firstWhere(
                      (r) => r.id == routine.id,
                      orElse: () => routine,
                    );
                    await pv.updateRoutine(updated.addItem(item));
                    setSheetState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EjerciciosStyle.cyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: EjerciciosStyle.darkText, size: 22),
                  ),
                ),
                const SizedBox(height: 8),
                TapTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    confirmDeleteRoutine(context, routine, pv);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EjerciciosStyle.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: EjerciciosStyle.white, size: 22),
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

Future<void> confirmDeleteRoutine(BuildContext context, WorkoutRoutine routine, WorkoutProvider pv) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: EjerciciosStyle.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Icon(Icons.delete_forever, color: EjerciciosStyle.red, size: 36),
      content: Text(
        '¿Eliminar la rutina "${routine.name}"?',
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
  if (ok == true && routine.id != null) {
    await pv.deleteRoutine(routine.id!);
  }
}
