import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/exercise_catalog.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

class ExerciseCatalogPicker extends StatelessWidget {
  final String selectedGroup;
  final String activeExerciseName;
  final ValueChanged<String> onGroupChanged;
  final void Function(String exerciseName, String group) onSelectExercise;

  const ExerciseCatalogPicker({
    super.key,
    required this.selectedGroup,
    required this.activeExerciseName,
    required this.onGroupChanged,
    required this.onSelectExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BIBLIOTECA POR GRUPO MUSCULAR',
          style: GoogleFonts.bangers(
            color: EjerciciosStyle.lime,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ExerciseCatalog.groups.map((g) {
              final selected = selectedGroup == g;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TapTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onGroupChanged(g);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: EjerciciosStyle.panelDeco(
                      color: selected
                          ? EjerciciosStyle.lime
                          : EjerciciosStyle.field,
                      radius: 10,
                      bw: 2,
                    ),
                    child: Text(
                      g,
                      style: GoogleFonts.bangers(
                        color: selected
                            ? EjerciciosStyle.darkText
                            : EjerciciosStyle.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: EjerciciosStyle.panelDeco(
            color: EjerciciosStyle.panelLight,
            radius: 12,
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ExerciseCatalog.exercisesFor(selectedGroup).map((ex) {
              final active = activeExerciseName == ex;
              return TapTile(
                onTap: () => onSelectExercise(ex, selectedGroup),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: EjerciciosStyle.panelDeco(
                    color:
                        active ? EjerciciosStyle.lime : EjerciciosStyle.field,
                    radius: 8,
                    bw: 1.5,
                  ),
                  child: Text(
                    ex,
                    style: GoogleFonts.bangers(
                      color: active
                          ? EjerciciosStyle.darkText
                          : EjerciciosStyle.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
