import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/exercise_catalog.dart';
import '../../../models/workout_log.dart';
import '../../../models/workout_routine.dart';
import '../../../models/workout_stats.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';
import 'challenge_form_dialogs.dart';

String itemSummary(RoutineItem it) {
  final seriesTxt =
      it.series != null && it.reps != null ? '${it.series}x${it.reps}' : '';
  final w = it.weight;
  final weightTxt = w == null
      ? ''
      : (w == w.roundToDouble() ? '${w.round()}kg' : '${w}kg');
  return [seriesTxt, weightTxt].where((s) => s.isNotEmpty).join(' @ ');
}

Widget libraryChips(WorkoutProvider pv, TextEditingController ctrl) {
  final names = {
    ...WorkoutStats.distinctExerciseNames(pv.logs),
    for (final g in ExerciseCatalog.groups) ...ExerciseCatalog.exercisesFor(g),
  }.toList();
  if (names.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: names.take(18).map((n) {
      final active = ctrl.text.trim() == n;
      return TapTile(
        onTap: () {
          HapticFeedback.selectionClick();
          ctrl.text = n;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: EjerciciosStyle.panelDeco(
            color: active ? EjerciciosStyle.lime : EjerciciosStyle.field,
            radius: 10,
            bw: 1.5,
          ),
          child: Text(
            n,
            style: GoogleFonts.bangers(
              color: active ? EjerciciosStyle.darkText : EjerciciosStyle.white,
              fontSize: 12,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

Future<RoutineItem?> promptRoutineItem(BuildContext context, WorkoutProvider pv) async {
  final nameCtrl = TextEditingController();
  final seriesCtrl = TextEditingController();
  final repsCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final restCtrl = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => customFormDialog(
      context: ctx,
      title: 'Agregar ejercicio',
      fields: [
        libraryChips(pv, nameCtrl),
        const SizedBox(height: 6),
        ejercicioField(nameCtrl, 'Nombre *', autofocus: true),
        ejercicioNumField(seriesCtrl, 'Series'),
        ejercicioNumField(repsCtrl, 'Reps'),
        ejercicioDecimalField(weightCtrl, 'Peso (kg)'),
        ejercicioNumField(restCtrl, 'Descanso (seg)'),
      ],
      onOk: () => nameCtrl.text.trim().isNotEmpty,
    ),
  );
  if (saved != true) return null;
  final name = nameCtrl.text.trim();
  if (name.isEmpty) return null;
  return RoutineItem(
    exerciseName: name,
    series: int.tryParse(seriesCtrl.text.trim()),
    reps: int.tryParse(repsCtrl.text.trim()),
    weight: double.tryParse(weightCtrl.text.trim()),
    restSeconds: int.tryParse(restCtrl.text.trim()),
  );
}

Future<void> dialogNewRoutine(BuildContext context, WorkoutProvider pv, {int? dayOfWeek}) async {
  final nameCtrl = TextEditingController();
  final items = <RoutineItem>[];
  final result = await showDialog<({String name, List<RoutineItem> items})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        RoutineItem fromLibrary(String n) {
          WorkoutLog? last;
          for (final l in pv.logs) {
            if (l.exerciseName != n) continue;
            if (last == null || l.loggedOn.isAfter(last.loggedOn)) last = l;
          }
          return RoutineItem(
            exerciseName: n,
            series: last?.series,
            reps: last?.reps,
            weight: last?.weight,
            restSeconds: last?.restSeconds,
          );
        }

        final names = WorkoutStats.distinctExerciseNames(pv.logs);
        return AlertDialog(
          backgroundColor: EjerciciosStyle.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Icon(Icons.fitness_center, color: EjerciciosStyle.cyan, size: 30),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ejercicioField(
                  nameCtrl,
                  dayOfWeek != null
                      ? 'Rutina del ${EjerciciosStyle.dayNames[dayOfWeek - 1]} *'
                      : 'Nombre de la rutina *',
                  autofocus: true,
                ),
                if (names.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Biblioteca (toca para agregar)',
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: names.take(12).map((n) => TapTile(
                          onTap: () => setLocal(() => items.add(fromLibrary(n))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: EjerciciosStyle.panelLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(n, style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 11)),
                          ),
                        )).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                for (final it in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: EjerciciosStyle.panelLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            it.exerciseName,
                            style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(itemSummary(it), style: GoogleFonts.bangers(color: EjerciciosStyle.cyan, fontSize: 11)),
                        TapTile(
                          onTap: () => setLocal(() => items.remove(it)),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.close, color: EjerciciosStyle.red, size: 16),
                          ),
                        ),
                      ]),
                    ),
                  ),
                const SizedBox(height: 4),
                TapTile(
                  onTap: () async {
                    final item = await promptRoutineItem(context, pv);
                    if (item != null) {
                      setLocal(() => items.add(item));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: EjerciciosStyle.panelLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: Icon(Icons.add, color: EjerciciosStyle.cyan, size: 20)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TapTile(
              onTap: () => Navigator.pop(ctx),
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
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(
                  ctx,
                  (name: nameCtrl.text.trim(), items: List<RoutineItem>.of(items)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EjerciciosStyle.cyan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check, color: EjerciciosStyle.darkText, size: 20),
              ),
            ),
          ],
        );
      },
    ),
  );
  if (result == null) return;
  await pv.addRoutine(WorkoutRoutine(
    name: result.name,
    dayOfWeek: dayOfWeek,
    items: result.items,
  ));
}
