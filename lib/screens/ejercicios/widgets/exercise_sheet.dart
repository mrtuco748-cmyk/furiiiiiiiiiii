import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/exercise_catalog.dart';
import '../../../models/workout_log.dart';
import '../../../widgets/tap_tile.dart';
import '../ejercicios_style.dart';

/// Modal bottom sheet para registrar o editar un ejercicio.
/// Incluye biblioteca rápida por grupo muscular (1 toque para rellenar)
/// y controles numéricos ágiles (+ / -) para series, repeticiones y peso.
class ExerciseSheet extends StatefulWidget {
  final WorkoutLog? existing;
  final String? prefillName;
  final String? prefillGroup;
  final int? prefillSeries;
  final int? prefillReps;
  final double? prefillWeight;
  final int? prefillRest;
  final DateTime? day;
  final void Function(WorkoutLog log) onSave;
  final VoidCallback? onDelete;

  const ExerciseSheet({
    super.key,
    this.existing,
    this.prefillName,
    this.prefillGroup,
    this.prefillSeries,
    this.prefillReps,
    this.prefillWeight,
    this.prefillRest,
    this.day,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    WorkoutLog? existing,
    String? prefillName,
    String? prefillGroup,
    int? prefillSeries,
    int? prefillReps,
    double? prefillWeight,
    int? prefillRest,
    DateTime? day,
    required void Function(WorkoutLog log) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EjerciciosStyle.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExerciseSheet(
        existing: existing,
        prefillName: prefillName,
        prefillGroup: prefillGroup,
        prefillSeries: prefillSeries,
        prefillReps: prefillReps,
        prefillWeight: prefillWeight,
        prefillRest: prefillRest,
        day: day,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<ExerciseSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _groupCtrl;
  late final TextEditingController _notesCtrl;

  String _selectedCatalogGroup = 'Pecho';
  int _series = 4;
  int _reps = 10;
  double _weight = 0.0;
  int _restSeconds = 60;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameCtrl = TextEditingController(
      text: ex?.exerciseName ?? widget.prefillName ?? '',
    );
    _groupCtrl = TextEditingController(
      text: ex?.muscleGroup ?? widget.prefillGroup ?? '',
    );
    _notesCtrl = TextEditingController(text: ex?.notes ?? '');

    _series = ex?.series ?? widget.prefillSeries ?? 4;
    _reps = ex?.reps ?? widget.prefillReps ?? 10;
    _weight = ex?.weight ?? widget.prefillWeight ?? 0.0;
    _restSeconds = ex?.restSeconds ?? widget.prefillRest ?? 60;

    // Detectar grupo de catálogo si ya hay grupo o nombre
    final currentGroup = _groupCtrl.text.trim();
    if (ExerciseCatalog.groups.contains(currentGroup)) {
      _selectedCatalogGroup = currentGroup;
    } else if (_nameCtrl.text.isNotEmpty) {
      final suggested = ExerciseCatalog.suggestGroupFor(_nameCtrl.text);
      if (suggested != null) _selectedCatalogGroup = suggested;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _groupCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _selectCatalogExercise(String exName, String group) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameCtrl.text = exName;
      _groupCtrl.text = group;
      _selectedCatalogGroup = group;
      _error = null;
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Ingresá el nombre del ejercicio');
      return;
    }

    HapticFeedback.mediumImpact();
    final group = _groupCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final log = (widget.existing ??
            WorkoutLog(
              exerciseName: name,
              loggedOn: widget.day ?? DateTime.now(),
            ))
        .copyWith(
      exerciseName: name,
      muscleGroup: group.isEmpty ? null : group,
      series: _series > 0 ? _series : null,
      reps: _reps > 0 ? _reps : null,
      weight: _weight > 0 ? _weight : null,
      restSeconds: _restSeconds > 0 ? _restSeconds : null,
      notes: notes.isEmpty ? null : notes,
      clearMuscleGroup: group.isEmpty,
    );

    widget.onSave(log);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asa superior
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: EjerciciosStyle.panelDeco(
                  color: EjerciciosStyle.field,
                  radius: 3,
                  bw: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Título
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: EjerciciosStyle.lime,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'EDITAR EJERCICIO' : 'NUEVO EJERCICIO',
                  style: GoogleFonts.bangers(
                    color: EjerciciosStyle.white,
                    fontSize: 22,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: EjerciciosStyle.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Biblioteca: Barra de grupos musculares
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
                  final selected = _selectedCatalogGroup == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TapTile(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCatalogGroup = g);
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

            // Chips de ejercicios del grupo seleccionado
            Container(
              padding: const EdgeInsets.all(8),
              decoration: EjerciciosStyle.panelDeco(
                color: EjerciciosStyle.panelLight,
                radius: 12,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ExerciseCatalog.exercisesFor(_selectedCatalogGroup)
                    .map((ex) {
                  final active = _nameCtrl.text.trim() == ex;
                  return TapTile(
                    onTap: () =>
                        _selectCatalogExercise(ex, _selectedCatalogGroup),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: EjerciciosStyle.panelDeco(
                        color: active
                            ? EjerciciosStyle.lime
                            : EjerciciosStyle.field,
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
            const SizedBox(height: 12),

            // Campos de texto para nombre y grupo (totalmente personalizables)
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.white,
                      fontSize: 17,
                    ),
                    cursorColor: EjerciciosStyle.lime,
                    decoration: EjerciciosStyle.inputDeco('Ejercicio *'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _groupCtrl,
                    style: GoogleFonts.bangers(
                      color: EjerciciosStyle.white,
                      fontSize: 17,
                    ),
                    cursorColor: EjerciciosStyle.lime,
                    decoration: EjerciciosStyle.inputDeco('Grupo muscular'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Steppers numéricos: Series y Repeticiones
            Row(
              children: [
                Expanded(
                  child: _stepperBlock(
                    label: 'SERIES',
                    value: '$_series',
                    onMinus: () =>
                        setState(() => _series = (_series - 1).clamp(1, 50)),
                    onPlus: () =>
                        setState(() => _series = (_series + 1).clamp(1, 50)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _stepperBlock(
                    label: 'REPS',
                    value: '$_reps',
                    onMinus: () =>
                        setState(() => _reps = (_reps - 1).clamp(1, 200)),
                    onPlus: () =>
                        setState(() => _reps = (_reps + 1).clamp(1, 200)),
                    extraAction: () =>
                        setState(() => _reps = (_reps + 5).clamp(1, 200)),
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
                        setState(() =>
                            _weight = (_weight - 5).clamp(0.0, 999.0));
                      }),
                      const SizedBox(width: 4),
                      _stepChip('-1', () {
                        setState(() =>
                            _weight = (_weight - 1).clamp(0.0, 999.0));
                      }),
                      const SizedBox(width: 8),
                      Text(
                        _weight == _weight.roundToDouble()
                            ? '${_weight.round()} kg'
                            : '${_weight.toStringAsFixed(1)} kg',
                        style: GoogleFonts.bangers(
                          color: EjerciciosStyle.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _stepChip('+1', () {
                        setState(() =>
                            _weight = (_weight + 1).clamp(0.0, 999.0));
                      }),
                      const SizedBox(width: 4),
                      _stepChip('+2.5', () {
                        setState(() =>
                            _weight = (_weight + 2.5).clamp(0.0, 999.0));
                      }),
                      const SizedBox(width: 4),
                      _stepChip('+5', () {
                        setState(() =>
                            _weight = (_weight + 5).clamp(0.0, 999.0));
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
                        setState(() => _restSeconds = sec);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: EjerciciosStyle.panelDeco(
                          color: _restSeconds == sec
                              ? EjerciciosStyle.lime
                              : EjerciciosStyle.field,
                          radius: 8,
                          bw: 1.5,
                        ),
                        child: Text(
                          '${sec}s',
                          style: GoogleFonts.bangers(
                            color: _restSeconds == sec
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
            const SizedBox(height: 10),

            // Notas
            TextField(
              controller: _notesCtrl,
              style: GoogleFonts.bangers(
                color: EjerciciosStyle.white,
                fontSize: 15,
              ),
              cursorColor: EjerciciosStyle.lime,
              decoration: EjerciciosStyle.inputDeco('Notas opcionales'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.bangers(
                  color: EjerciciosStyle.red,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Botones de acción
            Row(
              children: [
                if (isEditing && widget.onDelete != null) ...[
                  TapTile(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      widget.onDelete!();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: EjerciciosStyle.panelDeco(
                        color: EjerciciosStyle.red,
                        radius: 14,
                        bw: 2,
                      ),
                      child: const Icon(Icons.delete,
                          color: EjerciciosStyle.white, size: 26),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: TapTile(
                    onTap: _submit,
                    child: Container(
                      height: 52,
                      decoration: EjerciciosStyle.panelDeco(
                        color: EjerciciosStyle.lime,
                        radius: 14,
                        bw: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check,
                              color: EjerciciosStyle.darkText, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR EJERCICIO',
                            style: GoogleFonts.bangers(
                              color: EjerciciosStyle.darkText,
                              fontSize: 18,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
}
