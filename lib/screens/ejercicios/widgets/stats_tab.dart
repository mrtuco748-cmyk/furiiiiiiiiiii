import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app_state.dart';
import '../../../providers/workout_provider.dart';
import '../ejercicios_style.dart';
import 'common.dart';

class StatsTab extends StatelessWidget {
  final double w;
  final double h;
  final WorkoutProvider pv;

  const StatsTab({super.key, required this.w, required this.h, required this.pv});

  @override
  Widget build(BuildContext context) {
    final partnerName = AppState.identity == 'Facu' ? 'Rocio' : 'Facu';
    final muscles = pv.muscleGroupCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: StatCard('Racha propia', '${pv.myStreak} días',
              Icons.local_fire_department),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: StatCard('Racha de $partnerName', '${pv.partnerStreak} días',
              Icons.favorite),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: StatCard('Sesiones esta semana', '${pv.sessionsThisWeek}',
              Icons.today),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: StatCard('Sesiones semana pasada', '${pv.sessionsLastWeek}',
              Icons.history),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: StatCard('Ejercicios distintos',
              '${pv.distinctExerciseNames.length}', Icons.fitness_center),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child:
              StatCard('Registros totales', '${pv.logs.length}', Icons.checklist),
        ),
        if (muscles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: EjerciciosStyle.panelDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Por grupo muscular',
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final m in muscles)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.key,
                              style: GoogleFonts.bangers(
                                color: EjerciciosStyle.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${m.value}',
                            style: GoogleFonts.bangers(
                              color: EjerciciosStyle.cyan,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}