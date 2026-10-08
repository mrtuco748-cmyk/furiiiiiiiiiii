import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app_state.dart';
import '../../../models/workout_routine.dart';
import '../../../providers/workout_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';
import 'common.dart';

DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day)
    .subtract(Duration(days: d.weekday - 1));

List<DateTime> _weekDays() => List.generate(
    7, (i) => _mondayOf(DateTime.now()).add(Duration(days: i)));

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

String? _facuId(WorkoutProvider pv) =>
    AppState.identity == 'Facu' ? pv.myId : pv.partnerId;
String? _rocioId(WorkoutProvider pv) =>
    AppState.identity == 'Rocio' ? pv.myId : pv.partnerId;

class HoyTab extends StatelessWidget {
  final double w;
  final double h;
  final WorkoutProvider pv;
  final int myStreak;
  final int partnerStreak;
  final String partnerName;
  final void Function(int dayOfWeek) onAssignRoutine;
  final void Function(WorkoutRoutine routine) onEditRoutine;
  final void Function(DateTime day) onToggleDay;
  final void Function(RoutineItem item, DateTime day) onLogPrefill;

  const HoyTab({
    super.key,
    required this.w,
    required this.h,
    required this.pv,
    required this.myStreak,
    required this.partnerStreak,
    required this.partnerName,
    required this.onAssignRoutine,
    required this.onEditRoutine,
    required this.onToggleDay,
    required this.onLogPrefill,
  });

  @override
  Widget build(BuildContext context) {
    final days = _weekDays();
    return ListView(
      padding: EdgeInsets.only(bottom: h * 0.14),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: StreakCard(w, myStreak, partnerStreak, partnerName),
        ),
        for (final d in days)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: DayCard(
              d,
              pv,
              () => onAssignRoutine(d.weekday),
              onEditRoutine,
              () => onToggleDay(d),
              onLogPrefill,
            ),
          ),
      ],
    );
  }
}

class DayCard extends StatelessWidget {
  final DateTime day;
  final WorkoutProvider pv;
  final VoidCallback onAssignRoutine;
  final void Function(WorkoutRoutine routine) onEditRoutine;
  final VoidCallback onToggleDay;
  final void Function(RoutineItem item, DateTime day) onLogPrefill;

  const DayCard(
    this.day,
    this.pv,
    this.onAssignRoutine,
    this.onEditRoutine,
    this.onToggleDay,
    this.onLogPrefill, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final routine = pv.routineForDay(day.weekday);
    final completions = pv.completionsFor(day);
    final facuDone = completions.any((c) => c.userId == _facuId(pv));
    final rocioDone = completions.any((c) => c.userId == _rocioId(pv));
    final isToday = DateTime(day.year, day.month, day.day) == _today();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: EjerciciosStyle.panelDeco(color: EjerciciosStyle.panelLight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? EjerciciosStyle.cyan : EjerciciosStyle.panel,
                  border: Border.all(
                      color: isToday ? EjerciciosStyle.cyan : EjerciciosStyle.panel,
                      width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${EjerciciosStyle.dayNames[day.weekday - 1]} ${day.day}',
                  style: GoogleFonts.bangers(
                    color: isToday ? EjerciciosStyle.darkText : EjerciciosStyle.white,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              DoneBadge('F', facuDone, EjerciciosStyle.facuColor),
              const SizedBox(width: 6),
              DoneBadge('R', rocioDone, EjerciciosStyle.rocioColor),
              const SizedBox(width: 6),
              MarkButton(pv.completedByUser(day, pv.myId), onToggleDay),
            ],
          ),
          const SizedBox(height: 8),
          if (routine == null)
            TapTile(
              onTap: onAssignRoutine,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: EjerciciosStyle.panelDeco(),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: EjerciciosStyle.cyan, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Asignar rutina',
                      style: GoogleFonts.bangers(
                        color: EjerciciosStyle.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.list_alt, color: EjerciciosStyle.cyan, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    routine.name,
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TapTile(
                  onTap: () => onEditRoutine(routine),
                  child: const Icon(Icons.edit, color: EjerciciosStyle.white, size: 18),
                ),
              ],
            ),
            if (routine.items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Sin ejercicios en la rutina',
                  style: GoogleFonts.bangers(
                    color: EjerciciosStyle.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              )
            else
              for (var i = 0; i < routine.items.length; i++)
                RoutineItemRow(
                  routine.items[i], () => onLogPrefill(routine.items[i], day),
                ),
          ],
        ],
      ),
    );
  }
}

class MarkButton extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;

  const MarkButton(this.done, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: done ? EjerciciosStyle.cyan : EjerciciosStyle.panel,
          border: Border.all(
              color: done ? EjerciciosStyle.cyan : EjerciciosStyle.panel, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.check,
            color: done ? EjerciciosStyle.darkText : EjerciciosStyle.white, size: 18),
      ),
    );
  }
}

class RoutineItemRow extends StatelessWidget {
  final RoutineItem item;
  final VoidCallback onTap;

  const RoutineItemRow(this.item, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    final w = item.weight;
    final weightTxt =
        w == null ? '' : (w == w.roundToDouble() ? '${w.round()}kg' : '${w}kg');
    final seriesTxt = item.series != null && item.reps != null
        ? '${item.series}x${item.reps}'
        : '';
    return TapTile(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: EjerciciosStyle.panelDeco(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.exerciseName,
                style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 12),
              ),
            ),
            if (seriesTxt.isNotEmpty)
              Text(
                seriesTxt,
                style: GoogleFonts.bangers(color: EjerciciosStyle.cyan, fontSize: 12),
              ),
            if (weightTxt.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                weightTxt,
                style: GoogleFonts.bangers(color: EjerciciosStyle.cyan, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
