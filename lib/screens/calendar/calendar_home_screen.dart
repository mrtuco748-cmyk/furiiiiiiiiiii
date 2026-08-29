import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/event_type_provider.dart';
import '../../providers/class_schedule_provider.dart';
import '../../models/schedule.dart';
import '../../router.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../database/database_helper.dart';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _c = Color(0xFF00D4FF);
const _dark = Color(0xFF1A1A1A);
const _cDeep = Color(0xFF003344);
const _white = Color(0xFFFFFFFF);

class CalendarHomeScreen extends StatefulWidget {
  const CalendarHomeScreen({super.key});
  @override
  State<CalendarHomeScreen> createState() => _CalendarHomeScreenState();
}

class _CalendarHomeScreenState extends State<CalendarHomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkClassSetup();
      await _loadData();
    });
  }

  Future<void> _checkClassSetup() async {
    try {
      final res = await DatabaseHelper().getAll('class_schedules');
      if (res.isEmpty && mounted) {
        final result = await context.push<bool>(RouterRoutes.classSetup);
        if (result == true) {
          final pv = context.read<ClassScheduleProvider>();
          if (mounted) pv.loadSchedules();
        }
      }
    } catch (e) {
      developer.log('checkClassSetup fallo: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      await context.read<ScheduleProvider>().loadSchedules();
      await context.read<EventTypeProvider>().loadTypes();
      await context.read<ClassScheduleProvider>().loadSchedules();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      developer.log('cargar calendario fallo: $e');
      if (mounted) setState(() => _initialized = true);
    }
  }

  List<Schedule> _getEventsForDay(DateTime day) {
    final dateSchedules = context.read<ScheduleProvider>().schedules.where((s) =>
      s.date.year == day.year && s.date.month == day.month && s.date.day == day.day,
    ).toList();
    final recurring = context.read<ClassScheduleProvider>().getByDay(day.weekday);
    for (final cs in recurring) {
      dateSchedules.add(Schedule(
        title: cs.title,
        description: cs.professor.isNotEmpty ? 'Prof: ${cs.professor}' : '',
        date: day,
        startTime: cs.startTime,
        endTime: cs.endTime,
        type: 'Clase',
        color: cs.color,
        userId: cs.userId,
      ));
    }
    return dateSchedules;
  }

  void _openForm() {
    HapticFeedback.mediumImpact();
    context.push(RouterRoutes.scheduleForm, extra: _selectedDay)
        .then((_) => _loadData());
  }

  void _openDayEvents() {
    HapticFeedback.mediumImpact();
    context.push(RouterRoutes.dailyEvents, extra: _selectedDay)
        .then((_) => _loadData());
  }

  void _openClasses() {
    HapticFeedback.mediumImpact();
    context.push(RouterRoutes.classBoard).then((_) => _loadData());
  }

  void _editSchedule(Schedule s) {
    HapticFeedback.mediumImpact();
    context.push(RouterRoutes.scheduleForm, extra: s).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
        ResponsiveWrapper(builder: (context, w, h) {
            if (!_initialized) return Center(child: CircularProgressIndicator(color: _c, strokeWidth: 3));
            return SizedBox(width: w, height: h, child: Stack(children: [
              _monthNav(w, h),
              _calendarBlock(w, h),
              _upcomingBlock(w, h),
              _addBtn(w, h),
            ]));
           },
         ),
      ]),
    );
  }

  Widget _monthNav(double w, double h) {
    final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return Positioned(left: w * 0.03, top: h * 0.005, width: w * 0.94, height: h * 0.05,
      child: Row(children: [
        TapTile(onTap: () { HapticFeedback.lightImpact(); setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1)); }, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.chevron_left, color: _c, size: 26))),
        Expanded(child: Center(child: Text('${months[_focusedDay.month - 1]} ${_focusedDay.year}', style: GoogleFonts.bangers(color: _c, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)))),
        TapTile(onTap: () { HapticFeedback.lightImpact(); setState(() => _focusedDay = DateTime.now()); }, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.center_focus_strong, color: _c, size: 22))),
        TapTile(onTap: _openDayEvents, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.view_day, color: _c, size: 22))),
        TapTile(onTap: _openClasses, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.school, color: _c, size: 22))),
        TapTile(onTap: () { HapticFeedback.lightImpact(); setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1)); }, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.chevron_right, color: _c, size: 26))),
      ]),
    );
  }

  Widget _calendarBlock(double w, double h) {
    final calTop = h * 0.05;
    final calH = h * 0.46;
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;
    final totalCells = ((daysInMonth + firstWeekday - 1) / 7).ceil() * 7;

    return Positioned(
      left: w * 0.01, top: calTop, width: w * 0.98, height: calH,
      child: Column(children: [
        _dayNameRow(w, calH * 0.05),
        Expanded(child: _daysGrid(firstWeekday, totalCells, w)),
      ]),
    );
  }

  Widget _dayNameRow(double w, double dh) {
    final days = ['L','Ma','Mi','J','V','S','D'];
    return SizedBox(width: w, height: dh,
      child: Row(children: days.map((d) => SizedBox(width: w / 7, child: Center(child: Text(d, style: GoogleFonts.bangers(color: _white.withValues(alpha: 0.35), fontSize: 9, letterSpacing: 1))))).toList()),
    );
  }

  Widget _daysGrid(int firstWeekday, int totalCells, double w) {
    final weeks = totalCells ~/ 7;
    // Grilla fija: cada semana ocupa 1/N de la altura disponible. Así el mes
    // completo (incluso con 6 semanas) se ve SIEMPRE entero, sin recortar abajo.
    return Column(
      children: List.generate(weeks, (wi) {
        return Expanded(
          child: Row(
            children: List.generate(7, (ci) {
              final index = wi * 7 + ci;
              final dayNum = index - firstWeekday + 2;
              return Expanded(child: _cellFor(dayNum));
            }),
          ),
        );
      }),
    );
  }

  Widget _cellFor(int dayNum) {
    if (dayNum < 1 || dayNum > _daysInSelectedMonth) {
      if (dayNum < 1) {
        final prevMonthDay =
            DateTime(_focusedDay.year, _focusedDay.month, 0).day + dayNum;
        return _dayCell(prevMonthDay, _cDeep, isOutside: true, num: prevMonthDay);
      }
      return _dayCell(0, Colors.transparent, isOutside: true, num: 0);
    }
    final color = const Color(0xFF122433);
    final events =
        _getEventsForDay(DateTime(_focusedDay.year, _focusedDay.month, dayNum));
    final isToday = dayNum == DateTime.now().day &&
        _focusedDay.month == DateTime.now().month &&
        _focusedDay.year == DateTime.now().year;
    final isSelected = _selectedDay != null &&
        dayNum == _selectedDay!.day &&
        _focusedDay.month == _selectedDay!.month &&
        _focusedDay.year == _selectedDay!.year;
    return _dayCell(dayNum, color,
        events: events, isToday: isToday, isSelected: isSelected);
  }

  int get _daysInSelectedMonth =>
      DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;

  Widget _dayCell(int day, Color bg, {List<Schedule>? events, bool isToday = false, bool isSelected = false, bool isOutside = false, int num = 0}) {
    if (day == 0) return const SizedBox.shrink();
    final hasEvents = events != null && events.isNotEmpty;

    // Minimalista: celda neutra; hoy = borde acento; seleccionado = acento lleno.
    final Color cellBg;
    if (isOutside) {
      cellBg = const Color(0xFF0B1620);
    } else if (isSelected) {
      cellBg = _c;
    } else if (isToday) {
      cellBg = const Color(0xFF0E2A38);
    } else {
      cellBg = const Color(0xFF122433);
    }

    final Color textColor;
    if (isSelected) {
      textColor = _dark;
    } else if (isToday) {
      textColor = _c;
    } else if (isOutside) {
      textColor = _white.withValues(alpha: 0.25);
    } else {
      textColor = _white.withValues(alpha: 0.75);
    }

    return GestureDetector(
      onTap: () {
        if (!isOutside) {
          HapticFeedback.selectionClick();
          setState(() => _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, day));
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: _c, width: 2)
              : (isToday ? Border.all(color: _c, width: 1.6) : null),
        ),
        child: Stack(children: [
          Center(child: Text('$day', style: GoogleFonts.bangers(color: textColor, fontSize: 13))),
          if (hasEvents)
            Positioned(
              bottom: 3,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Class events: use each class's color
                  ...events!
                      .where((e) => e.type == 'Clase')
                      .take(3)
                      .map((e) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(color: Color(e.color), shape: BoxShape.circle),
                          ))
                      .toList(),
                  // Non‑class events: keep existing behavior
                  ...events!
                      .where((e) => e.type != 'Clase')
                      .take(3)
                      .map((e) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(color: Color(e.color), shape: BoxShape.circle),
                          ))
                      .toList(),
                ],
              ),
            ),
        ]),
      ),
    );
  }

  Widget _upcomingBlock(double w, double h) {
    final upcoming = context.watch<ScheduleProvider>().schedules
        .where((s) => s.type != 'Clase' && s.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .toList()..sort((a, b) => a.date.compareTo(b.date));

    return Positioned(
      left: w * 0.03, top: h * 0.54, width: w * 0.94, height: h * 0.40,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(' Proximos', style: GoogleFonts.bangers(color: _c, fontSize: 14)),
        const SizedBox(height: 4),
        Expanded(
          child: upcoming.isEmpty
              ? Center(child: Text('Sin eventos', style: GoogleFonts.bangers(color: _white.withValues(alpha: 0.3), fontSize: 12)))
              : ListView.builder(
                  itemCount: upcoming.length,
                  itemBuilder: (context, i) {
                    final e = upcoming[i];
                    final dateStr = '${e.date.day}/${e.date.month}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: GestureDetector(
                        onTap: () => _editSchedule(e),
                        onLongPress: () => _deleteSchedule(e),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _cDeep,
                            border: Border.all(color: _cDeep, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Color(e.color), borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(e.color), width: 2)),
                              child: Text(dateStr, style: GoogleFonts.bangers(color: _dark, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.title, style: GoogleFonts.bangers(color: _white, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('${e.startTime}-${e.endTime} ${e.location}', style: GoogleFonts.bangers(color: _white.withValues(alpha: 0.4), fontSize: 8)),
                            ])),
                            Icon(Icons.chevron_right, color: _white.withValues(alpha: 0.3), size: 16),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  void _deleteSchedule(Schedule s) async {
    if (s.id == null) return;
    HapticFeedback.heavyImpact();
    await context.read<ScheduleProvider>().deleteSchedule(s.id!);
    _loadData();
  }

  Widget _addBtn(double w, double h) {
    return Positioned(
      right: w * 0.05, bottom: h * 0.03, width: w * 0.13, height: w * 0.13,
      child: TapTile(
        onTap: _openForm,
        child: Container(
          decoration: BoxDecoration(color: _c, border: Border.all(color: _c, width: 4), borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Icon(Icons.add, color: _dark, size: 28)),
        ),
      ),
    );
  }
}