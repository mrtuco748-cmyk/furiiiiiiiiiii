import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/workout_challenge.dart';
import '../../models/workout_log.dart';
import '../../models/workout_routine.dart';
import '../../models/workout_social.dart';
import '../../models/workout_stats.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/tap_tile.dart';
import '../../theme/app_theme.dart';

class EjerciciosScreen extends StatefulWidget {
  final AppMode mode;
  const EjerciciosScreen({super.key, required this.mode});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  static const _bg = Color(0xFF0A0A0A);
  static const _lima = Color(0xFF39FF14);
  static const _panel = Color(0xFF0E3A0E);
  static const _panelLight = Color(0xFF175217);
  static const _darkText = Color(0xFF062B06);
  static const _white = Color(0xFFFFFFFF);
  static const _red = Color(0xFFFF4444);
  static const _facuColor = Color(0xFF00E5FF);
  static const _rocioColor = Color(0xFFFF66C4);

  static const _dayNames = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  static const _defaultReactions = ['🔥', '💪', '🏆', '👏', '😤', '🥳'];

  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkoutProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: ResponsiveWrapper(
        builder: (context, w, h) {
          return SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
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
        color: _lima,
        border: Border.all(color: _lima, width: 4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, color: _darkText, size: 26),
          const SizedBox(width: 10),
          Text(
            'EJERCICIOS',
            style: GoogleFonts.bangers(
              color: _darkText,
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
          color: selected ? _lima : _panel,
          border: Border.all(color: selected ? _lima : _panel, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? _darkText : _white, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bangers(
                  color: selected ? _darkText : _white,
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
      return Center(child: CircularProgressIndicator(color: _lima));
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
          color: _panel,
          border: Border.all(color: _red, width: 3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: _red, size: 48),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.bangers(color: _white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TapTile(
              onTap: () => pv.load(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _red,
                  border: Border.all(color: _red, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh, color: _white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _white.withValues(alpha: 0.35), size: 48),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.bangers(
              color: _white.withValues(alpha: 0.45),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listPad(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: child,
    );
  }

  // ─── TAB HOY ─────────────────────────────────────────────────

  DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day)
      .subtract(Duration(days: d.weekday - 1));

  List<DateTime> _weekDays() => List.generate(
      7, (i) => _mondayOf(DateTime.now()).add(Duration(days: i)));

  Widget _hoyTab(double w, double h, WorkoutProvider pv) {
    final days = _weekDays();
    final myStreak = pv.myStreak;
    final partnerStreak = pv.partnerStreak;
    final partnerName = AppState.identity == 'Facu' ? 'Rocio' : 'Facu';
    return ListView(
      padding: EdgeInsets.only(bottom: h * 0.14),
      children: [
        _listPad(_streakCard(w, myStreak, partnerStreak, partnerName)),
        for (final d in days)
          _listPad(_dayCard(w, d, pv)),
      ],
    );
  }

  Widget _streakCard(
      double w, int myStreak, int partnerStreak, String partnerName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDeco(),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: _lima, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Racha: $myStreak día${myStreak == 1 ? '' : 's'} · '
              '$partnerName: $partnerStreak',
              style: GoogleFonts.bangers(color: _white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDeco({Color? color, Color? borderColor}) =>
      BoxDecoration(
        color: color ?? _panel,
        border: Border.all(color: borderColor ?? color ?? _panel, width: 3),
        borderRadius: BorderRadius.circular(16),
      );

  Widget _dayCard(double w, DateTime day, WorkoutProvider pv) {
    final routine = pv.routineForDay(day.weekday);
    final completions = pv.completionsFor(day);
    final facuDone = completions.any((c) => c.userId == _facuId(pv));
    final rocioDone = completions.any((c) => c.userId == _rocioId(pv));
    final isToday = DateTime(day.year, day.month, day.day) == _today();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDeco(color: _panelLight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? _lima : _panel,
                  border: Border.all(color: isToday ? _lima : _panel, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_dayNames[day.weekday - 1]} ${day.day}',
                  style: GoogleFonts.bangers(
                    color: isToday ? _darkText : _white,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              _doneBadge('F', facuDone, _facuColor),
              const SizedBox(width: 6),
              _doneBadge('R', rocioDone, _rocioColor),
              const SizedBox(width: 6),
              _markBtn(pv, day),
            ],
          ),
          const SizedBox(height: 8),
          if (routine == null)
            TapTile(
              onTap: () => _dialogNewRoutine(dayOfWeek: day.weekday),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: _panelDeco(),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: _lima, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Asignar rutina',
                      style: GoogleFonts.bangers(
                        color: _white.withValues(alpha: 0.7),
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
                const Icon(Icons.list_alt, color: _lima, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    routine.name,
                    style: GoogleFonts.bangers(
                      color: _white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TapTile(
                  onTap: () => _sheetEditRoutine(routine),
                  child: const Icon(Icons.edit,
                      color: _white, size: 18),
                ),
              ],
            ),
            if (routine.items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Sin ejercicios en la rutina',
                  style: GoogleFonts.bangers(
                    color: _white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              )
            else
              for (var i = 0; i < routine.items.length; i++)
                _routineItemRow(routine.items[i], routine, day),
          ],
        ],
      ),
    );
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String? _facuId(WorkoutProvider pv) =>
      AppState.identity == 'Facu' ? pv.myId : pv.partnerId;
  String? _rocioId(WorkoutProvider pv) =>
      AppState.identity == 'Rocio' ? pv.myId : pv.partnerId;

  Widget _doneBadge(String label, bool done, Color color) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? color : _panel,
        border: Border.all(color: done ? color : _panel, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.bangers(
          color: done ? _bg : _white.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _markBtn(WorkoutProvider pv, DateTime day) {
    final done = pv.completedByUser(day, pv.myId);
    return TapTile(
      onTap: () async {
        HapticFeedback.lightImpact();
        await pv.toggleCompletion(userId: pv.myId, date: day);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: done ? _lima : _panel,
          border: Border.all(color: done ? _lima : _panel, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.check, color: done ? _darkText : _white, size: 18),
      ),
    );
  }

  Widget _routineItemRow(
      RoutineItem item, WorkoutRoutine routine, DateTime day) {
    final w = item.weight;
    final weightTxt =
        w == null ? '' : (w == w.roundToDouble() ? '${w.round()}kg' : '${w}kg');
    final seriesTxt =
        item.series != null && item.reps != null ? '${item.series}x${item.reps}' : '';
    return TapTile(
      onTap: () => _dialogNewLog(prefill: item, day: day),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: _panelDeco(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.exerciseName,
                style: GoogleFonts.bangers(color: _white, fontSize: 12),
              ),
            ),
            if (seriesTxt.isNotEmpty)
              Text(
                seriesTxt,
                style: GoogleFonts.bangers(
                  color: _lima,
                  fontSize: 12,
                ),
              ),
            if (weightTxt.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                weightTxt,
                style: GoogleFonts.bangers(color: _lima, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── TAB EJERCICIOS ──────────────────────────────────────────

  Widget _ejerciciosTab(double w, double h, WorkoutProvider pv) {
    if (pv.logs.isEmpty) {
      return _emptyView(Icons.fitness_center, 'Sin ejercicios registrados');
    }
    return ListView(
      padding: EdgeInsets.only(bottom: h * 0.14),
      children: [
        for (final log in pv.logs)
          _listPad(_logCard(w, log, pv)),
      ],
    );
  }

  Widget _logCard(double w, WorkoutLog log, WorkoutProvider pv) {
    final mine = log.userId == pv.myId;
    final initial = mine
        ? (AppState.identity?.substring(0, 1).toUpperCase() ?? '?')
        : (AppState.identity == 'Facu' ? 'R' : 'F');
    final userColor = mine
        ? (AppState.identity == 'Facu' ? _facuColor : _rocioColor)
        : (AppState.identity == 'Facu' ? _rocioColor : _facuColor);
    final reactions = log.social.reactions;
    return GestureDetector(
      onTap: () => _sheetLogDetail(log, pv),
      onLongPress: () => _sheetReactions(
        (key) => pv.toggleLogReaction(log.id!, key),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _panelDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: userColor,
                    border: Border.all(color: userColor, width: 2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    initial,
                    style: GoogleFonts.bangers(
                      color: _bg,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.exerciseName,
                    style: GoogleFonts.bangers(
                      color: _white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (log.summary.isNotEmpty)
                  Text(
                    log.summary,
                    style: GoogleFonts.bangers(color: _lima, fontSize: 12),
                  ),
              ],
            ),
            if (log.muscleGroup != null) ...[
              const SizedBox(height: 4),
              Text(
                log.muscleGroup!,
                style: GoogleFonts.bangers(
                  color: _white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
            if (reactions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  for (final e in reactions.entries)
                    _reactionChip(e.key, e.value.length),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reactionChip(String key, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _panelLight,
        border: Border.all(color: _panelLight, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 1 ? '$key $count' : key,
        style: GoogleFonts.bangers(color: _white, fontSize: 11),
      ),
    );
  }

  // ─── TAB RETOS ───────────────────────────────────────────────

  Widget _retosTab(double w, double h, WorkoutProvider pv) {
    if (pv.challenges.isEmpty) {
      return _emptyView(Icons.flag, 'Sin retos todavía');
    }
    return ListView(
      padding: EdgeInsets.only(bottom: h * 0.14),
      children: [
        for (final c in pv.challenges)
          _listPad(_challengeCard(w, c, pv)),
      ],
    );
  }

  Widget _challengeCard(double w, WorkoutChallenge c, WorkoutProvider pv) {
    final mine = c.createdBy == pv.myId;
    return GestureDetector(
      onTap: () => _sheetChallengeDetail(c, pv),
      onLongPress: () => _sheetReactions(
        (key) => pv.toggleChallengeReaction(c.id!, key),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _panelDeco(
          color: c.isCompleted ? _panelLight : _panel,
          borderColor: c.isApproved ? _lima : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  c.isCompleted
                      ? Icons.emoji_events
                      : (c.isApproved ? Icons.flag : Icons.outlined_flag),
                  color: c.isCompleted ? _lima : _white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.title,
                    style: GoogleFonts.bangers(
                      color: _white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: c.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (mine)
                  const Icon(Icons.person, color: _facuColor, size: 16),
              ],
            ),
            if (c.description != null) ...[
              const SizedBox(height: 4),
              Text(
                c.description!,
                style: GoogleFonts.bangers(
                  color: _white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                _doneBadge('F', c.approvedByUser(_facuId(pv) ?? ''), _facuColor),
                const SizedBox(width: 4),
                _doneBadge(
                    'R', c.approvedByUser(_rocioId(pv) ?? ''), _rocioColor),
                const SizedBox(width: 8),
                Text(
                  'aprobado',
                  style: GoogleFonts.bangers(
                    color: _white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 10),
                _doneBadge(
                    'F', c.completedByUser(_facuId(pv) ?? ''), _facuColor),
                const SizedBox(width: 4),
                _doneBadge(
                    'R', c.completedByUser(_rocioId(pv) ?? ''), _rocioColor),
                const SizedBox(width: 8),
                Text(
                  'hecho',
                  style: GoogleFonts.bangers(
                    color: _white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (c.social.reactions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  for (final e in c.social.reactions.entries)
                    _reactionChip(e.key, e.value.length),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── TAB STATS ───────────────────────────────────────────────

  Widget _statsTab(double w, double h, WorkoutProvider pv) {
    final partnerName = AppState.identity == 'Facu' ? 'Rocio' : 'Facu';
    final muscles = pv.muscleGroupCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _listPad(_statCard('Racha propia', '${pv.myStreak} días',
            Icons.local_fire_department)),
        _listPad(_statCard('Racha de $partnerName', '${pv.partnerStreak} días',
            Icons.favorite)),
        _listPad(_statCard('Sesiones esta semana', '${pv.sessionsThisWeek}',
            Icons.today)),
        _listPad(_statCard('Sesiones semana pasada', '${pv.sessionsLastWeek}',
            Icons.history)),
        _listPad(_statCard('Ejercicios distintos',
            '${pv.distinctExerciseNames.length}', Icons.fitness_center)),
        _listPad(_statCard(
            'Registros totales', '${pv.logs.length}', Icons.checklist)),
        if (muscles.isNotEmpty)
          _listPad(
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _panelDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Por grupo muscular',
                    style: GoogleFonts.bangers(
                      color: _lima,
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
                                color: _white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${m.value}',
                            style: GoogleFonts.bangers(
                              color: _lima,
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

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDeco(),
      child: Row(
        children: [
          Icon(icon, color: _lima, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.bangers(color: _white, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.bangers(
              color: _lima,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
            color: _lima,
            border: Border.all(color: _lima, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: _darkText, size: 30),
        ),
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────────────────────────────

  Future<void> _dialogNewLog({RoutineItem? prefill, DateTime? day}) async {
    final nameCtrl = TextEditingController(text: prefill?.exerciseName ?? '');
    final groupCtrl = TextEditingController();
    final seriesCtrl =
        TextEditingController(text: prefill?.series?.toString() ?? '');
    final repsCtrl =
        TextEditingController(text: prefill?.reps?.toString() ?? '');
    final weightCtrl = TextEditingController(
      text: prefill?.weight == null
          ? ''
          : (prefill!.weight == prefill.weight!.roundToDouble()
              ? prefill.weight!.round().toString()
              : '${prefill.weight}'),
    );
    final restCtrl =
        TextEditingController(text: prefill?.restSeconds?.toString() ?? '');
    final notesCtrl = TextEditingController(text: prefill?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _formDialog(
        title: 'Nuevo ejercicio',
        fields: [
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
    final pv = context.read<WorkoutProvider>();
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

  Future<void> _dialogNewRoutine({int? dayOfWeek}) async {
    final nameCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _formDialog(
        title: dayOfWeek != null ? 'Rutina del ${_dayNames[dayOfWeek - 1]}' : 'Nueva rutina',
        fields: [_field(nameCtrl, 'Nombre *', autofocus: true)],
        onOk: () => nameCtrl.text.trim().isNotEmpty,
      ),
    );
    if (saved != true) return;
    if (!mounted) return;
    final pv = context.read<WorkoutProvider>();
    await pv.addRoutine(WorkoutRoutine(
      name: nameCtrl.text.trim(),
      dayOfWeek: dayOfWeek,
    ));
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
      backgroundColor: _panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _panel, width: 4),
      ),
      title: Row(
        children: [
          const Icon(Icons.fitness_center, color: _lima, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.bangers(
              color: _white,
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
              color: _panelLight,
              border: Border.all(color: _panelLight, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close, color: _white, size: 20),
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
              color: _lima,
              border: Border.all(color: _lima, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: _darkText, size: 20),
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
        style: GoogleFonts.bangers(color: _white, fontSize: 14),
        decoration: _inputDeco(hint),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: GoogleFonts.bangers(color: _white, fontSize: 14),
        decoration: _inputDeco(hint),
      ),
    );
  }

  Widget _decimalField(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.bangers(color: _white, fontSize: 14),
        decoration: _inputDeco(hint),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.bangers(color: _white.withValues(alpha: 0.4), fontSize: 13),
      filled: true,
      fillColor: _panelLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _panelLight, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _panelLight, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _lima, width: 3),
      ),
    );
  }

  // ─── SHEET: EDITAR RUTINA ────────────────────────────────────

  void _sheetEditRoutine(WorkoutRoutine routine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
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
                          color: _lima,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TapTile(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: _white, size: 22),
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
                                      color: _white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TapTile(
                                  onTap: () async {
                                    final removed =
                                        live.removeItem(i);
                                    await pv.updateRoutine(removed);
                                    setSheetState(() {});
                                  },
                                  child: const Icon(Icons.close,
                                      color: _red, size: 18),
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
                        color: _lima,
                        border: Border.all(color: _lima, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: _darkText, size: 22),
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
                        color: _red,
                        border: Border.all(color: _red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: _white, size: 22),
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

  Future<void> _dialogRoutineItem(
      WorkoutRoutine routine, void Function() refresh) async {
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
          _field(nameCtrl, 'Nombre *', autofocus: true),
          _numField(seriesCtrl, 'Series'),
          _numField(repsCtrl, 'Reps'),
          _decimalField(weightCtrl, 'Peso (kg)'),
          _numField(restCtrl, 'Descanso (seg)'),
        ],
        onOk: () => nameCtrl.text.trim().isNotEmpty,
      ),
    );
    if (saved != true) return;
    if (!mounted) return;
    final pv = context.read<WorkoutProvider>();
    final live = pv.routines.firstWhere(
      (r) => r.id == routine.id,
      orElse: () => routine,
    );
    await pv.updateRoutine(live.addItem(RoutineItem(
      exerciseName: nameCtrl.text.trim(),
      series: _parseInt(seriesCtrl.text),
      reps: _parseInt(repsCtrl.text),
      weight: _parseDouble(weightCtrl.text),
      restSeconds: _parseInt(restCtrl.text),
    )));
    refresh();
  }

  Future<void> _confirmDeleteRoutine(WorkoutRoutine routine) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _panel, width: 4),
        ),
        title: const Icon(Icons.delete_forever, color: _red, size: 36),
        content: Text(
          '¿Eliminar la rutina "${routine.name}"?',
          style: GoogleFonts.bangers(color: _white, fontSize: 14),
        ),
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx, false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _panelLight,
                border: Border.all(color: _panelLight, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: _white, size: 20),
            ),
          ),
          TapTile(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _red,
                border: Border.all(color: _red, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: _white, size: 20),
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
      backgroundColor: _panel,
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
            final history =
                WorkoutStats.weightHistoryFor(pv.logs, live.exerciseName);
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
                            color: _lima,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (live.id != null)
                        TapTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            _confirmDeleteLog(live);
                          },
                          child: const Icon(Icons.delete_outline,
                              color: _red, size: 20),
                        ),
                      const SizedBox(width: 8),
                      TapTile(
                        onTap: () => Navigator.pop(ctx),
                        child:
                            const Icon(Icons.close, color: _white, size: 22),
                      ),
                    ],
                  ),
                  if (live.summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        live.summary,
                        style:
                            GoogleFonts.bangers(color: _white, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _reactionBar(
                    live.social.reactions,
                    (key) async {
                      if (live.id == null) return;
                      final ok =
                          await pv.toggleLogReaction(live.id!, key);
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
                          if (history.isNotEmpty) ...[
                            Text(
                              'Evolución de peso',
                              style: GoogleFonts.bangers(
                                color: _lima,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            for (final e in history.reversed)
                              _weightRow(e),
                          ] else
                            Text(
                              'Sin historial de pesos todavía',
                              style: GoogleFonts.bangers(
                                color: _white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 12),
                          _commentsBlock(
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

  Widget _weightRow(WeightEntry e) {
    final w = e.weight;
    final txt = w == w.roundToDouble() ? '${w.round()} kg' : '$w kg';
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text(
            '${e.date.day}/${e.date.month}/${e.date.year}',
            style: GoogleFonts.bangers(
              color: _white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            txt,
            style: GoogleFonts.bangers(color: _lima, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteLog(WorkoutLog log) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _panel, width: 4),
        ),
        title: const Icon(Icons.delete_forever, color: _red, size: 36),
        content: Text(
          '¿Eliminar "${log.exerciseName}"?',
          style: GoogleFonts.bangers(color: _white, fontSize: 14),
        ),
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx, false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _panelLight,
                border: Border.all(color: _panelLight, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: _white, size: 20),
            ),
          ),
          TapTile(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _red,
                border: Border.all(color: _red, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: _white, size: 20),
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
      backgroundColor: _panel,
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
                      for (final emoji in _defaultReactions)
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
                        onTap: () => _customReactionDialog(
                            (key) async => onReact(key)),
                        child: const Icon(Icons.add_reaction,
                            color: _lima, size: 26),
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
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _panel, width: 4),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 10,
          style: GoogleFonts.bangers(color: _white, fontSize: 14),
          decoration: _inputDeco('Reacción custom (max 10)'),
        ),
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx),
            child: const Icon(Icons.close, color: _white, size: 20),
          ),
          TapTile(
            onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Icon(Icons.check, color: _lima, size: 20),
          ),
        ],
      ),
    );
    if (key != null && key.isNotEmpty) await onReact(key);
  }

  Widget _reactionBar(
    Map<String, List<String>> reactions,
    Future<void> Function(String key) onTap,
  ) {
    return Wrap(
      spacing: 6,
      children: [
        for (final e in reactions.entries)
          TapTile(
            onTap: () => onTap(e.key),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _panelLight,
                border: Border.all(color: _lima, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                e.value.length > 1 ? '${e.key} ${e.value.length}' : e.key,
                style: GoogleFonts.bangers(color: _white, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  // ─── SHEET: DETALLE DE RETO ──────────────────────────────────

  void _sheetChallengeDetail(WorkoutChallenge c, WorkoutProvider pv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
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
                            color: _lima,
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
                              color: _red, size: 20),
                        ),
                      const SizedBox(width: 8),
                      TapTile(
                        onTap: () => Navigator.pop(ctx),
                        child:
                            const Icon(Icons.close, color: _white, size: 22),
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
                          color: _white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          live.approvedByUser(pv.myId)
                              ? Icons.undo
                              : Icons.how_to_reg,
                          live.approvedByUser(pv.myId) ? _lima : _panelLight,
                          _white,
                          () async {
                            if (live.id == null) return;
                            await pv.toggleChallengeApproval(live.id!);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionBtn(
                          live.completedByUser(pv.myId)
                              ? Icons.undo
                              : Icons.emoji_events,
                          live.completedByUser(pv.myId) ? _lima : _panelLight,
                          live.completedByUser(pv.myId) ? _darkText : _white,
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
                  _reactionBar(
                    live.social.reactions,
                    (key) async {
                      if (live.id == null) return;
                      final ok = await pv.toggleChallengeReaction(
                        live.id!,
                        key,
                      );
                      setSheetState(() {});
                      if (!ok) HapticFeedback.heavyImpact();
                    },
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: _commentsBlock(
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

  Widget _actionBtn(IconData icon, Color color, Color iconColor,
      VoidCallback onTap) {
    return TapTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Future<void> _confirmDeleteChallenge(WorkoutChallenge c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _panel, width: 4),
        ),
        title: const Icon(Icons.delete_forever, color: _red, size: 36),
        content: Text(
          '¿Eliminar el reto "${c.title}"?',
          style: GoogleFonts.bangers(color: _white, fontSize: 14),
        ),
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx, false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _panelLight,
                border: Border.all(color: _panelLight, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: _white, size: 20),
            ),
          ),
          TapTile(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _red,
                border: Border.all(color: _red, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: _white, size: 20),
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

  // ─── COMENTARIOS ─────────────────────────────────────────────

  Widget _commentsBlock(
    List<WorkoutComment> comments,
    void Function(String text) onAdd,
    void Function(String commentId) onDelete,
    void Function() refresh,
  ) {
    final ctrl = TextEditingController();
    final myId = context.read<WorkoutProvider>().myId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: _lima, size: 18),
            const SizedBox(width: 6),
            Text(
              'Comentarios',
              style: GoogleFonts.bangers(
                color: _white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (comments.isEmpty)
          Text(
            'Sin comentarios',
            style: GoogleFonts.bangers(
              color: _white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          )
        else
          for (final c in comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.replyToId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.subdirectory_arrow_right,
                          color: _white.withValues(alpha: 0.4), size: 14),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      c.text,
                      style: GoogleFonts.bangers(
                        color: _white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (c.userId == myId)
                    TapTile(
                      onTap: () async {
                        onDelete(c.id);
                        refresh();
                      },
                      child: const Icon(Icons.close,
                          color: _red, size: 16),
                    ),
                ],
              ),
            ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLength: 1000,
                style: GoogleFonts.bangers(color: _white, fontSize: 13),
                decoration: _inputDeco('Comentar...').copyWith(
                  counterText: '',
                ),
                onSubmitted: (text) async {
                  if (text.trim().isEmpty) return;
                  onAdd(text);
                  ctrl.clear();
                  refresh();
                },
              ),
            ),
            const SizedBox(width: 6),
            TapTile(
              onTap: () async {
                if (ctrl.text.trim().isEmpty) return;
                onAdd(ctrl.text);
                ctrl.clear();
                refresh();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _lima,
                  border: Border.all(color: _lima, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send, color: _darkText, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  static String? _orNull(String s) => s.isEmpty ? null : s;

  static int? _parseInt(String s) => int.tryParse(s.trim());

  static double? _parseDouble(String s) => double.tryParse(s.trim());
}
