import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/class_schedule.dart';
import '../../models/schedule.dart';
import '../../providers/class_schedule_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/tap_tile.dart';
import 'day_agenda.dart';
import 'event_sheet.dart';
import 'widgets/calendar_agenda_view.dart';

/// Calendario unificado: UNA pantalla, UN botón de agregar.
/// - Arriba: mes (◀ nombre ▶; tocar el nombre = volver a hoy).
/// - Abajo: agenda del día elegido (únicos + repetidos juntos por hora).
/// - `+`: formulario único (repetición elegida con una fila de iconos).
/// Todo se comparte entre Facu y Rocio vía `schedules` (sync + realtime).
class CalendarScreen extends StatefulWidget {
  /// Abre el formulario de alta apenas carga (atajos del Home).
  final bool openCreate;
  const CalendarScreen({super.key, this.openCreate = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
    'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _dayNames = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

  late DateTime _month;
  late DateTime _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _load();
      if (widget.openCreate && mounted) _add();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        context.read<ScheduleProvider>().loadSchedules(),
        context.read<ClassScheduleProvider>().loadSchedules(),
      ]);
    } catch (e) {
      developer.log('Calendario: fallo al cargar: $e');
      _error = 'No se pudo cargar';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _goToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  void _add() => showEventSheet(context, day: _selected);

  @override
  Widget build(BuildContext context) {
    final schedules = context.watch<ScheduleProvider>().schedules;
    final classes = context.watch<ClassScheduleProvider>().schedules;
    return Scaffold(
      backgroundColor: calBg,
      body: ResponsiveWrapper(builder: (context, w, h) {
        if (_loading && schedules.isEmpty && classes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: calCyan, strokeWidth: 4),
          );
        }
        final gap = (w * 0.025).clamp(6.0, 14.0);
        return Padding(
          padding: EdgeInsets.all(gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(h * 0.075),
              SizedBox(height: gap),
              SizedBox(
                height: h * 0.46,
                child: _monthGrid(schedules, classes),
              ),
              SizedBox(height: gap),
              Expanded(
                child: CalendarAgendaView(
                  selectedDay: _selected,
                  schedules: schedules,
                  classes: classes,
                  error: _error,
                  onRetry: _load,
                  onAdd: _add,
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: TapTile(
        onTap: () {
          HapticFeedback.mediumImpact();
          _add();
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: calBox(calCyan, r: 20, bw: 4),
          child: const Icon(Icons.add, color: calInk, size: 36),
        ),
      ),
    );
  }

  Widget _header(double height) {
    return Container(
      height: height,
      decoration: calBox(calCyan, r: 18, bw: 4),
      child: Row(children: [
        _headerBtn(Icons.arrow_back, () => Navigator.of(context).maybePop()),
        _headerBtn(Icons.chevron_left, () => _shiftMonth(-1)),
        Expanded(
          child: TapTile(
            onTap: _goToday,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  style: GoogleFonts.bangers(
                      color: calInk, fontSize: 28, letterSpacing: 1.5),
                ),
              ),
            ),
          ),
        ),
        _headerBtn(Icons.chevron_right, () => _shiftMonth(1)),
        const SizedBox(width: 8),
      ]),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) => TapTile(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(icon, color: calInk, size: 32),
        ),
      );

  Widget _monthGrid(List<Schedule> schedules, List<ClassSchedule> classes) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final weeks = ((lead + daysInMonth) / 7).ceil();
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: calBox(calPanel, r: 20),
      child: Column(children: [
        SizedBox(
          height: 22,
          child: Row(children: [
            for (final d in _dayNames)
              Expanded(
                child: Center(
                  child: Text(d,
                      style: GoogleFonts.bangers(color: calMuted, fontSize: 14)),
                ),
              ),
          ]),
        ),
        Expanded(
          child: Column(children: [
            for (var wi = 0; wi < weeks; wi++)
              Expanded(
                child: Row(children: [
                  for (var ci = 0; ci < 7; ci++)
                    Expanded(
                      child: _dayCell(
                        wi * 7 + ci - lead + 1,
                        daysInMonth,
                        today,
                        schedules,
                        classes,
                      ),
                    ),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _dayCell(int n, int daysInMonth, DateTime today,
      List<Schedule> schedules, List<ClassSchedule> classes) {
    if (n < 1 || n > daysInMonth) return const SizedBox.shrink();
    final day = DateTime(_month.year, _month.month, n);
    final isSel = day == _selected;
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final items =
        DayAgenda.forDay(schedules: schedules, classes: classes, day: day);

    final bg = isSel ? calCyan : (isToday ? calField : calPanel);
    final fg = isSel ? calInk : (isToday ? calCyan : calWhite);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = day);
      },
      onDoubleTap: () {
        setState(() => _selected = day);
        _add();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.all(2),
        decoration: calBox(bg, r: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$n', style: GoogleFonts.bangers(color: fg, fontSize: 17)),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final it in items.take(3))
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: calBox(
                            isSel ? calInk : Color(it.color), r: 3, bw: 0),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
