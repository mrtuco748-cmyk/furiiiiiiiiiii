import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/workout_log.dart';
import '../../../providers/workout_provider.dart';
import '../ejercicios_style.dart';
import 'common.dart';

class ImprovementBlock extends StatelessWidget {
  final WorkoutLog live;
  final WorkoutProvider pv;

  const ImprovementBlock({super.key, required this.live, required this.pv});

  @override
  Widget build(BuildContext context) {
    final all = pv.logs.where((l) => l.exerciseName == live.exerciseName).toList()
      ..sort((a, b) => a.loggedOn.compareTo(b.loggedOn));
    if (all.isEmpty) {
      return Text('Sin historial todavía',
          style: GoogleFonts.bangers(
              color: EjerciciosStyle.white.withValues(alpha: 0.5), fontSize: 12));
    }
    final first = all.first;
    final last = all.last;
    final fw = first.weight;
    final lw = last.weight;
    final delta = (fw != null && lw != null) ? lw - fw : 0.0;
    String fmt(double? v) => v == null
        ? '—'
        : (v == v.roundToDouble() ? '${v.round()}kg' : '${v}kg');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: EjerciciosStyle.panelLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Stat('PRIMERO', fmt(fw)),
          Stat('ÚLTIMO', fmt(lw)),
          Stat('AVANCE', '${delta >= 0 ? '+' : ''}${fmt(delta)}',
              color: delta >= 0 ? EjerciciosStyle.cyan : EjerciciosStyle.red),
        ]),
      ),
      const SizedBox(height: 8),
      Text('Historial de mejora',
          style: GoogleFonts.bangers(
              color: EjerciciosStyle.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      for (final l in all.reversed) ImproveRow(l),
    ]);
  }
}