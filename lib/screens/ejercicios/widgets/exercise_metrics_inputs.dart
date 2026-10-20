import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

class ExerciseMetricsInputs extends StatelessWidget {
  final int series;
  final int reps;
  final double weight;
  final int restSeconds;
  final ValueChanged<int> onSeriesChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRestSecondsChanged;

  const ExerciseMetricsInputs({
    super.key,
    required this.series,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.onSeriesChanged,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onRestSecondsChanged,
  });

  Widget _stepChip(String text, VoidCallback onTap) {
    return TapTile(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: EjerciciosStyle.panelDeco(
          color: EjerciciosStyle.field,
          radius: 8,
          bw: 1.5,
        ),
        child: Text(
          text,
          style: GoogleFonts.bangers(
            color: EjerciciosStyle.lime,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _stepperBlock({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    VoidCallback? extraAction,
    String? extraLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: EjerciciosStyle.panelDeco(
        color: EjerciciosStyle.panelLight,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.bangers(
              color: EjerciciosStyle.lime,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stepChip('-', onMinus),
              Text(
                value,
                style: GoogleFonts.bangers(
                  color: EjerciciosStyle.white,
                  fontSize: 22,
                ),
              ),
              _stepChip('+', onPlus),
              if (extraAction != null && extraLabel != null) ...[
                _stepChip(extraLabel, extraAction),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Steppers numéricos: Series y Repeticiones
        Row(
          children: [
            Expanded(
              child: _stepperBlock(
                label: 'SERIES',
                value: '$series',
                onMinus: () => onSeriesChanged((series - 1).clamp(1, 50)),
                onPlus: () => onSeriesChanged((series + 1).clamp(1, 50)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _stepperBlock(
                label: 'REPS',
                value: '$reps',
                onMinus: () => onRepsChanged((reps - 1).clamp(1, 200)),
                onPlus: () => onRepsChanged((reps + 1).clamp(1, 200)),
                extraAction: () => onRepsChanged((reps + 5).clamp(1, 200)),
                extraLabel: '+5',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Stepper de Peso (kg) con botones rápidos +2.5 y +5
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: EjerciciosStyle.panelDeco(
            color: EjerciciosStyle.panelLight,
            radius: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'PESO (KG)',
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.lime,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  _stepChip('-5', () {
                    onWeightChanged((weight - 5).clamp(0.0, 999.0));
                  }),
                  const SizedBox(width: 4),
                  _stepChip('-1', () {
                    onWeightChanged((weight - 1).clamp(0.0, 999.0));
                  }),
                  const SizedBox(width: 8),
                  Text(
                    weight == weight.roundToDouble()
                        ? '${weight.round()} kg'
                        : '${weight.toStringAsFixed(1)} kg',
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _stepChip('+1', () {
                    onWeightChanged((weight + 1).clamp(0.0, 999.0));
                  }),
                  const SizedBox(width: 4),
                  _stepChip('+2.5', () {
                    onWeightChanged((weight + 2.5).clamp(0.0, 999.0));
                  }),
                  const SizedBox(width: 4),
                  _stepChip('+5', () {
                    onWeightChanged((weight + 5).clamp(0.0, 999.0));
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Descanso entre series
        Row(
          children: [
            Text(
              'DESCANSO: ',
              style: GoogleFonts.bangers(
                color: EjerciciosStyle.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            for (final sec in [30, 45, 60, 90, 120]) ...[
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TapTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRestSecondsChanged(sec);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: EjerciciosStyle.panelDeco(
                      color: restSeconds == sec
                          ? EjerciciosStyle.lime
                          : EjerciciosStyle.field,
                      radius: 8,
                      bw: 1.5,
                    ),
                    child: Text(
                      '${sec}s',
                      style: GoogleFonts.bangers(
                        color: restSeconds == sec
                            ? EjerciciosStyle.darkText
                            : EjerciciosStyle.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
