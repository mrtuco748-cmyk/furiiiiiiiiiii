import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/exercise_catalog.dart';
import '../../../models/workout_log.dart';
import '../ejercicios_style.dart';
import 'exercise_action_buttons.dart';
import 'exercise_catalog_picker.dart';
import 'exercise_metrics_inputs.dart';

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
            ExerciseCatalogPicker(
              selectedGroup: _selectedCatalogGroup,
              activeExerciseName: _nameCtrl.text.trim(),
              onGroupChanged: (g) => setState(() => _selectedCatalogGroup = g),
              onSelectExercise: _selectCatalogExercise,
            ),
            const SizedBox(height: 12),
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
            ExerciseMetricsInputs(
              series: _series,
              reps: _reps,
              weight: _weight,
              restSeconds: _restSeconds,
              onSeriesChanged: (v) => setState(() => _series = v),
              onRepsChanged: (v) => setState(() => _reps = v),
              onWeightChanged: (v) => setState(() => _weight = v),
              onRestSecondsChanged: (v) => setState(() => _restSeconds = v),
            ),
            const SizedBox(height: 10),
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
            ExerciseActionButtons(
              isEditing: isEditing,
              onDelete: widget.onDelete,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
