import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/workout_challenge.dart';
import '../../models/workout_log.dart';
import '../../models/workout_routine.dart';
import '../../models/workout_stats.dart';
import '../../providers/workout_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/brutal_style.dart';
import '../../theme/app_theme.dart';
import 'ejercicios_style.dart';
import 'widgets/common.dart';
import 'widgets/hoy_tab.dart';
import 'widgets/ejercicios_tab.dart';
import 'widgets/retos_tab.dart';
import 'widgets/stats_tab.dart';
import 'widgets/improvement_block.dart';
import 'widgets/comments_block.dart';

class EjerciciosScreen extends StatefulWidget {
  final AppMode mode;
  final int initialTab;
  const EjerciciosScreen({super.key, required this.mode, this.initialTab = 0});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkoutProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EjerciciosStyle.bg,
      body: ResponsiveWrapper(
        builder: (context, w, h) {
          return SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                BrutalStyle.bg(EjerciciosStyle.bg),
                Positioned.fill(
                  child: Column(
                    children: [
                      _header(w, h),
                      _tabs(w, h),
                      Expanded(child: _body(w, h)),
                    ],
                  ),
                ),
                if (_tab != 3) _fab(w, h),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── HEADER Y TABS ───────────────────────────────────────────

  Widget _header(double w, double h) {
    return Container(
      height: h * 0.07,
      margin: EdgeInsets.all(w * 0.02),
      decoration: BoxDecoration(
        color: EjerciciosStyle.cyan,
        border: Border.all(color: EjerciciosStyle.cyan, width: 4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, color: EjerciciosStyle.darkText, size: 26),
          const SizedBox(width: 10),
          Text(
            'EJERCICIOS',
            style: GoogleFonts.bangers(
              color: EjerciciosStyle.darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(double w, double h) {
    final tabs = [
      (Icons.today, 'HOY'),
      (Icons.fitness_center, 'EJERCICIOS'),
      (Icons.flag, 'RETOS'),
      (Icons.bar_chart, 'STATS'),
    ];
    return Container(
      height: h * 0.055,
      margin: EdgeInsets.symmetric(horizontal: w * 0.02),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(child: _tabBtn(tabs[i].$1, tabs[i].$2, i)),
            if (i < tabs.length - 1) SizedBox(width: w * 0.012),
          ],
        ],
      ),
    );
  }

  Widget _tabBtn(IconData icon, String label, int index) {
    final selected = _tab == index;
    return TapTile(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _tab = index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected ? EjerciciosStyle.cyan : EjerciciosStyle.panel,
          border: Border.all(
              color: selected ? EjerciciosStyle.cyan : EjerciciosStyle.panel,
              width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? EjerciciosStyle.darkText : EjerciciosStyle.white,
                size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bangers(
                  color: selected ? EjerciciosStyle.darkText : EjerciciosStyle.white,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BODY ────────────────────────────────────────────────────

  Widget _body(double w, double h) {
    final pv = context.watch<WorkoutProvider>();
    if (pv.loading) {
      return Center(child: CircularProgressIndicator(color: EjerciciosStyle.cyan));
    }
    if (pv.hasError) {
      return _errorView(pv.error ?? 'Error', pv);
    }
    switch (_tab) {
      case 0:
        return _hoyTab(w, h, pv);
      case 1:
        return _ejerciciosTab(w, h, pv);
      case 2:
        return _retosTab(w, h, pv);
      default:
        return _statsTab(w, h, pv);
    }
  }

  Widget _errorView(String msg, WorkoutProvider pv) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: EjerciciosStyle.panel,
          border: Border.all(color: EjerciciosStyle.red, width: 3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: EjerciciosStyle.red, size: 48),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TapTile(
              onTap: () => pv.load(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: EjerciciosStyle.red,
                  border: Border.all(color: EjerciciosStyle.red, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh, color: EjerciciosStyle.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TABS ────────────────────────────────────────────────────

  Widget _hoyTab(double w, double h, WorkoutProvider pv) {
    return HoyTab(
      w: w,
      h: h,
      pv: pv,
      myStreak: pv.myStreak,
      partnerStreak: pv.partnerStreak,
      partnerName: AppState.identity == 'Facu' ? 'Rocio' : 'Facu',
      onAssignRoutine: (dow) => _dialogNewRoutine(dayOfWeek: dow),
      onEditRoutine: _sheetEditRoutine,
      onToggleDay: _toggleDay,
      onLogPrefill: (item, day) => _dialogNewLog(prefill: item, day: day),
    );
  }

  Future<void> _toggleDay(DateTime day) async {
    HapticFeedback.lightImpact();
    final pv = context.read<WorkoutProvider>();
    final rewards = context.read<RewardsProvider>();
    final wasDone = pv.completedByUser(day, pv.myId);
    await pv.toggleCompletion(userId: pv.myId, date: day);
    if (!wasDone) {
      final ds =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      rewards.awardOnce(pv.myId, 'workout-$ds', 2);
    }
  }

  Widget _ejerciciosTab(double w, double h, WorkoutProvider pv) {
    return EjerciciosTab(
      w: w,
      h: h,
      pv: pv,
      onLogTap: (log) => _sheetLogDetail(log, pv),
      onLogLongPress: (log) =>
          _sheetReactions((key) => pv.toggleLogReaction(log.id!, key)),
    );
  }

  Widget _retosTab(double w, double h, WorkoutProvider pv) {
    return RetosTab(
      w: w,
      h: h,
      pv: pv,
      onChallengeTap: (c) => _sheetChallengeDetail(c, pv),
      onChallengeLongPress: (c) =>
          _sheetReactions((key) => pv.toggleChallengeReaction(c.id!, key)),
    );
  }

  Widget _statsTab(double w, double h, WorkoutProvider pv) {
    return StatsTab(w: w, h: h, pv: pv);
  }

  // ─── FAB ─────────────────────────────────────────────────────

  Widget _fab(double w, double h) {
    return Positioned(
      right: w * 0.05,
      bottom: h * 0.04,
      child: TapTile(
        onTap: () {
          HapticFeedback.lightImpact();
          if (_tab == 0) {
            _dialogNewRoutine();
          } else if (_tab == 1) {
            _dialogNewLog();
          } else {
            _dialogNewChallenge();
          }
        },
        child: Container(
          width: w * 0.13,
          height: w * 0.13,
          decoration: BoxDecoration(
            color: EjerciciosStyle.cyan,
            border: Border.all(color: EjerciciosStyle.cyan, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: EjerciciosStyle.darkText, size: 30),
        ),
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────────────────────────────

  Future<void> _dialogNewLog({RoutineItem? prefill, WorkoutLog? existing, DateTime? day}) async {
    final pv = context.read<WorkoutProvider>();
    final nameCtrl = TextEditingController(
        text: existing?.exerciseName ?? prefill?.exerciseName ?? '');
    final groupCtrl = TextEditingController(
        text: existing?.muscleGroup ?? '');
    final seriesCtrl = TextEditingController(
        text: (existing?.series ?? prefill?.series)?.toString() ?? '');
    final repsCtrl = TextEditingController(
        text: (existing?.reps ?? prefill?.reps)?.toString() ?? '');
    final baseW = existing?.weight ?? prefill?.weight;
    final weightCtrl = TextEditingController(
      text: baseW == null
          ? ''
          : (baseW == baseW.roundToDouble()
              ? baseW.round().toString()
              : '$baseW'),
    );
    final restCtrl = TextEditingController(
        text: (existing?.restSeconds ?? prefill?.restSeconds)?.toString() ?? '');
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? prefill?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _formDialog(
        title: existing != null ? 'Editar ejercicio' : 'Nuevo ejercicio',
        fields: [
          _libraryChips(pv, nameCtrl),
          const SizedBox(height: 6),
          _field(nameCtrl, 'Nombre *', autofocus: true),
          _field(groupCtrl, 'Grupo muscular'),
          _numField(seriesCtrl, 'Series'),
          _numField(repsCtrl, 'Reps'),
          _decimalField(weightCtrl, 'Peso (kg)'),
          _numField(restCtrl, 'Descanso (seg)'),
          _field(notesCtrl, 'Notas'),
        ],
        onOk: () => nameCtrl.text.trim().isNotEmpty,
      ),
    );
    if (saved != true) return;
    if (!mounted) return;
    if (existing != null && existing.id != null) {
      await pv.updateLog(existing.copyWith(
        exerciseName: nameCtrl.text.trim(),
        muscleGroup: _orNull(groupCtrl.text.trim()),
        series: _parseInt(seriesCtrl.text),
        reps: _parseInt(repsCtrl.text),
        weight: _parseDouble(weightCtrl.text),
        restSeconds: _parseInt(restCtrl.text),
        notes: _orNull(notesCtrl.text.trim()),
      ));
      return;
    }
    await pv.addLog(WorkoutLog(
      exerciseName: nameCtrl.text.trim(),
      muscleGroup: _orNull(groupCtrl.text.trim()),
      series: _parseInt(seriesCtrl.text),
      reps: _parseInt(repsCtrl.text),
      weight: _parseDouble(weightCtrl.text),
      restSeconds: _parseInt(restCtrl.text),
      notes: _orNull(notesCtrl.text.trim()),
      routineId: null,
      loggedOn: day ?? DateTime.now(),
    ));
  }

  /// Chips de la biblioteca de ejercicios (nombres ya registrados): un toque
  /// completa el campo de nombre.
  Widget _libraryChips(WorkoutProvider pv, TextEditingController ctrl) {
    final names = WorkoutStats.distinctExerciseNames(pv.logs);
    if (names.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: names.take(12).map((n) {
        final active = ctrl.text.trim() == n;
        return TapTile(
          onTap: () { HapticFeedback.selectionClick(); ctrl.text = n; },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: active ? EjerciciosStyle.cyan : EjerciciosStyle.panelLight,
              border: Border.all(color: EjerciciosStyle.cyan, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(n, style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 11)),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _dialogNewRoutine({int? dayOfWeek}) async {
    final pv = context.read<WorkoutProvider>();
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
              side: const BorderSide(color: EjerciciosStyle.cyan, width: 4),
            ),
            title: const Icon(Icons.fitness_center, color: EjerciciosStyle.cyan, size: 30),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(nameCtrl,
                      dayOfWeek != null
                          ? 'Rutina del ${EjerciciosStyle.dayNames[dayOfWeek - 1]} *'
                          : 'Nombre de la rutina *',
                      autofocus: true),
                  if (names.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Biblioteca (toca para agregar)',
                        style: GoogleFonts.bangers(
                            color: EjerciciosStyle.white.withValues(alpha: 0.6), fontSize: 11)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: names.take(12).map((n) => TapTile(
                            onTap: () => setLocal(() => items.add(fromLibrary(n))),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: EjerciciosStyle.panelLight,
                                border: Border.all(color: EjerciciosStyle.cyan, width: 1.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(n,
                                  style: GoogleFonts.bangers(
                                      color: EjerciciosStyle.white, fontSize: 11)),
                            ),
                          )).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  for (final it in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: EjerciciosStyle.panelLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(it.exerciseName,
                                style: GoogleFonts.bangers(
                                    color: EjerciciosStyle.white, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(_itemSummary(it),
                              style: GoogleFonts.bangers(
                                  color: EjerciciosStyle.cyan, fontSize: 11)),
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
                      final item = await _promptItem();
                      if (item != null && mounted) {
                        setLocal(() => items.add(item));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: EjerciciosStyle.panelLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: EjerciciosStyle.cyan, width: 1.5),
                      ),
                      child: const Center(
                          child: Icon(Icons.add, color: EjerciciosStyle.cyan, size: 20)),
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
                    border: Border.all(color: EjerciciosStyle.panelLight, width: 2),
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
                      (name: nameCtrl.text.trim(),
                          items: List<RoutineItem>.of(items)));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EjerciciosStyle.cyan,
                    border: Border.all(color: EjerciciosStyle.cyan, width: 2),
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
    if (!mounted) return;
    await pv.addRoutine(WorkoutRoutine(
      name: result.name,
      dayOfWeek: dayOfWeek,
      items: result.items,
    ));
  }

  String _itemSummary(RoutineItem it) {
    final seriesTxt =
        it.series != null && it.reps != null ? '${it.series}x${it.reps}' : '';
    final w = it.weight;
    final weightTxt = w == null
        ? ''
        : (w == w.roundToDouble() ? '${w.round()}kg' : '${w}kg');
    return [seriesTxt, weightTxt].where((s) => s.isNotEmpty).join(' @ ');
  }

  Future<void> _dialogNewChallenge() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _formDialog(
        title: 'Nuevo reto',
        fields: [
          _field(titleCtrl, 'Título *', autofocus: true),
          _field(descCtrl, 'Descripción'),
        ],
        onOk: () => titleCtrl.text.trim().isNotEmpty,
      ),
    );
    if (saved != true) return;
    if (!mounted) return;
    final pv = context.read<WorkoutProvider>();
    await pv.addChallenge(WorkoutChallenge(
      title: titleCtrl.text.trim(),
      description: _orNull(descCtrl.text.trim()),
    ));
  }

  Widget _formDialog({
    required String title,
    required List<Widget> fields,
    required bool Function() onOk,
  }) {
    return AlertDialog(
      backgroundColor: EjerciciosStyle.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: EjerciciosStyle.panel, width: 4),
      ),
      title: Row(
        children: [
          const Icon(Icons.fitness_center, color: EjerciciosStyle.cyan, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.bangers(
              color: EjerciciosStyle.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fields,
        ),
      ),
      actions: [
        TapTile(
          onTap: () => Navigator.pop(context, false),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EjerciciosStyle.panelLight,
              border: Border.all(color: EjerciciosStyle.panelLight, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 20),
          ),
        ),
        TapTile(
          onTap: () {
            if (onOk()) {
              Navigator.pop(context, true);
            } else {
              HapticFeedback.heavyImpact();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EjerciciosStyle.cyan,
              border: Border.all(color: EjerciciosStyle.cyan, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: EjerciciosStyle.darkText, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool autofocus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        autofocus: autofocus,
        style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
        decoration: EjerciciosStyle.inputDeco(hint),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
        decoration: EjerciciosStyle.inputDeco(hint),
      ),
    );
  }

  Widget _decimalField(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
        decoration: EjerciciosStyle.inputDeco(hint),
      ),
    );
  }

  // ─── SHEET: EDITAR RUTINA ────────────────────────────────────

  void _sheetEditRoutine(WorkoutRoutine routine) {
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
            final pv = ctx.read<WorkoutProvider>();
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
                                  child: const Icon(Icons.close,
                                      color: EjerciciosStyle.red, size: 18),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TapTile(
                    onTap: () =>
                        _dialogRoutineItem(routine, () => setSheetState(() {})),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: EjerciciosStyle.cyan,
                        border: Border.all(color: EjerciciosStyle.cyan, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: EjerciciosStyle.darkText, size: 22),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TapTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeleteRoutine(routine);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: EjerciciosStyle.red,
                        border: Border.all(color: EjerciciosStyle.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: EjerciciosStyle.white, size: 22),
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

  Future<RoutineItem?> _promptItem() async {
    final pv = context.read<WorkoutProvider>();
    final nameCtrl = TextEditingController();
    final seriesCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final restCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _formDialog(
        title: 'Agregar ejercicio',
        fields: [
          _libraryChips(pv, nameCtrl),
          const SizedBox(height: 6),
          _field(nameCtrl, 'Nombre *', autofocus: true),
          _numField(seriesCtrl, 'Series'),
          _numField(repsCtrl, 'Reps'),
          _decimalField(weightCtrl, 'Peso (kg)'),
          _numField(restCtrl, 'Descanso (seg)'),
        ],
        onOk: () => nameCtrl.text.trim().isNotEmpty,
      ),
    );
    if (saved != true) return null;
    if (!mounted) return null;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return null;
    return RoutineItem(
      exerciseName: name,
      series: _parseInt(seriesCtrl.text),
      reps: _parseInt(repsCtrl.text),
      weight: _parseDouble(weightCtrl.text),
      restSeconds: _parseInt(restCtrl.text),
    );
  }

  Future<void> _dialogRoutineItem(
      WorkoutRoutine routine, void Function() refresh) async {
    final item = await _promptItem();
    if (item == null) return;
    if (!mounted) return;
    final pv = context.read<WorkoutProvider>();
    final live = pv.routines.firstWhere(
      (r) => r.id == routine.id,
      orElse: () => routine,
    );
    await pv.updateRoutine(live.addItem(item));
    refresh();
  }

  Future<void> _confirmDeleteRoutine(WorkoutRoutine routine) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EjerciciosStyle.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: EjerciciosStyle.panel, width: 4),
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
                border: Border.all(color: EjerciciosStyle.panelLight, width: 2),
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
                border: Border.all(color: EjerciciosStyle.red, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: EjerciciosStyle.white, size: 20),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final pv = context.read<WorkoutProvider>();
    if (routine.id != null) await pv.deleteRoutine(routine.id!);
  }

  // ─── SHEET: DETALLE DE LOG ───────────────────────────────────

  void _sheetLogDetail(WorkoutLog log, WorkoutProvider pv) {
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
            final live = pv.logs.firstWhere(
              (l) => l.id == log.id,
              orElse: () => log,
            );
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          live.exerciseName,
                          style: GoogleFonts.bangers(
                            color: EjerciciosStyle.cyan,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TapTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          _dialogNewLog(
                            prefill: RoutineItem(
                              exerciseName: live.exerciseName,
                              series: live.series,
                              reps: live.reps,
                              weight: live.weight,
                              restSeconds: live.restSeconds,
                              notes: live.notes,
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.trending_up, color: EjerciciosStyle.cyan, size: 20),
                        ),
                      ),
                      if (live.id != null) ...[
                        const SizedBox(width: 8),
                        TapTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            _dialogNewLog(existing: live);
                          },
                          child: const Icon(Icons.edit,
                              color: Color(0xFF00D4FF), size: 20),
                        ),
                        const SizedBox(width: 8),
                        TapTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            _confirmDeleteLog(live);
                          },
                          child: const Icon(Icons.delete_outline,
                              color: EjerciciosStyle.red, size: 20),
                        ),
                      ],
                      const SizedBox(width: 8),
                      TapTile(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 22),
                      ),
                    ],
                  ),
                  if (live.summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        live.summary,
                        style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ReactionBar(
                    live.social.reactions,
                    (key) async {
                      if (live.id == null) return;
                      final ok = await pv.toggleLogReaction(live.id!, key);
                      setSheetState(() {});
                      if (!ok) {
                        HapticFeedback.heavyImpact();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ImprovementBlock(live: live, pv: pv),
                          const SizedBox(height: 12),
                          CommentsBlock(
                            live.social.comments,
                            (text) {
                              if (live.id != null) {
                                pv.addLogComment(live.id!, text);
                              }
                            },
                            (commentId) {
                              if (live.id != null) {
                                pv.deleteLogComment(live.id!, commentId);
                              }
                            },
                            () => setSheetState(() {}),
                          ),
                        ],
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

  Future<void> _confirmDeleteLog(WorkoutLog log) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EjerciciosStyle.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: EjerciciosStyle.panel, width: 4),
        ),
        title: const Icon(Icons.delete_forever, color: EjerciciosStyle.red, size: 36),
        content: Text(
          '¿Eliminar "${log.exerciseName}"?',
          style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
        ),
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx, false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EjerciciosStyle.panelLight,
                border: Border.all(color: EjerciciosStyle.panelLight, width: 2),
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
                border: Border.all(color: EjerciciosStyle.red, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: EjerciciosStyle.white, size: 20),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final pv = context.read<WorkoutProvider>();
    if (log.id != null) await pv.deleteLog(log.id!);
  }

  // ─── SHEET: REACCIONES ───────────────────────────────────────

  void _sheetReactions(Future<void> Function(String key) onReact) {
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
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final emoji in EjerciciosStyle.defaultReactions)
                        TapTile(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await onReact(emoji);
                            setSheetState(() {});
                          },
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      TapTile(
                        onTap: () =>
                            _customReactionDialog((key) async => onReact(key)),
                        child: const Icon(Icons.add_reaction,
                            color: EjerciciosStyle.cyan, size: 26),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _customReactionDialog(
      Future<void> Function(String key) onReact) async {
    final ctrl = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EjerciciosStyle.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: EjerciciosStyle.panel, width: 4),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 10,
          style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
          decoration: EjerciciosStyle.inputDeco('Reacción custom (max 10)'),
        ),
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx),
            child: const Icon(Icons.close, color: EjerciciosStyle.white, size: 20),
          ),
          TapTile(
            onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Icon(Icons.check, color: EjerciciosStyle.cyan, size: 20),
          ),
        ],
      ),
    );
    if (key != null && key.isNotEmpty) await onReact(key);
  }

  // ─── SHEET: DETALLE DE RETO ──────────────────────────────────

  void _sheetChallengeDetail(WorkoutChallenge c, WorkoutProvider pv) {
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
              (ch) => ch.id == c.id,
              orElse: () => c,
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
                            _confirmDeleteChallenge(live);
                          },
                          child: const Icon(Icons.delete_outline,
                              color: EjerciciosStyle.red, size: 20),
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
                          live.approvedByUser(pv.myId)
                              ? Icons.undo
                              : Icons.how_to_reg,
                          live.approvedByUser(pv.myId)
                              ? EjerciciosStyle.cyan
                              : EjerciciosStyle.panelLight,
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
                          live.completedByUser(pv.myId)
                              ? Icons.undo
                              : Icons.emoji_events,
                          live.completedByUser(pv.myId)
                              ? EjerciciosStyle.cyan
                              : EjerciciosStyle.panelLight,
                          live.completedByUser(pv.myId)
                              ? EjerciciosStyle.darkText
                              : EjerciciosStyle.white,
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

  Future<void> _confirmDeleteChallenge(WorkoutChallenge c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EjerciciosStyle.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: EjerciciosStyle.panel, width: 4),
        ),
        title: const Icon(Icons.delete_forever, color: EjerciciosStyle.red, size: 36),
        content: Text(
          '¿Eliminar el reto "${c.title}"?',
          style: GoogleFonts.bangers(color: EjerciciosStyle.white, fontSize: 14),
        ),
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx, false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EjerciciosStyle.panelLight,
                border: Border.all(color: EjerciciosStyle.panelLight, width: 2),
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
                border: Border.all(color: EjerciciosStyle.red, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: EjerciciosStyle.white, size: 20),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final pv = context.read<WorkoutProvider>();
    if (c.id != null) await pv.deleteChallenge(c.id!);
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  static String? _orNull(String s) => s.isEmpty ? null : s;

  static int? _parseInt(String s) => int.tryParse(s.trim());

  static double? _parseDouble(String s) => double.tryParse(s.trim());
}