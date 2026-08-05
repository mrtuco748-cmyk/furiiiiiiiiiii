import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/event_type_provider.dart';
import '../../providers/class_schedule_provider.dart';
import '../../models/schedule.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';
import 'schedule_form_screen.dart';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _green = Color(0xFF00FF66);
const _darkGreen = Color(0xFF0D2A0D);
const _brightBlue = Color(0xFF00BFFF);
const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);

final _dayColors = [
  const Color(0xFF7B2D8E), const Color(0xFF2D7B8E), const Color(0xFF8E7B2D),
  const Color(0xFF2D8E7B), const Color(0xFF8E2D7B), const Color(0xFF4A90D9),
  const Color(0xFFD94A90), const Color(0xFF90D94A), const Color(0xFF00BFFF),
  const Color(0xFFFF6B35), const Color(0xFF9D00FF), const Color(0xFFFFDE59),
];

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      await context.read<ScheduleProvider>().loadSchedules();
      await context.read<EventTypeProvider>().loadTypes();
      await context.read<ClassScheduleProvider>().loadSchedules();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _initialized = true);
    }
  }

  void _onDaySelected(DateTime day, DateTime focused) {
    setState(() { _selectedDay = day; _focusedDay = focused; });
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScheduleFormScreen(initialDate: _selectedDay)),
    ).then((_) => _loadData());
  }

  void _editSchedule(Schedule s) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScheduleFormScreen(schedule: s)),
    ).then((_) => _loadData());
  }

  Color _cellBg(DateTime day) {
    if (day.month != _focusedDay.month) return _green.withValues(alpha: 0.1);
    final idx = (day.day + day.month * 7) % _dayColors.length;
    return _dayColors[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkGreen,
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
        ResponsiveWrapper(builder: (context, w, h) {
            if (!_initialized) return Center(child: CircularProgressIndicator(color: _brightBlue, strokeWidth: 3));
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
    final months = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'];
    return Positioned(      left: w * 0.03, top: h * 0.005, width: w * 0.94, height: h * 0.04,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TapTile(onTap: () { HapticFeedback.lightImpact(); setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1)); }, child: Icon(Icons.chevron_left, color: _brightBlue, size: 22)),
        Text('${months[_focusedDay.month - 1]} ${_focusedDay.year}', style: GoogleFonts.bangers(color: _green, fontWeight: FontWeight.bold, fontSize: 15)),
        TapTile(onTap: () { HapticFeedback.lightImpact(); setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1)); }, child: Icon(Icons.chevron_right, color: _brightBlue, size: 22)),
      ]),
    );
  }

  Widget _calendarBlock(double w, double h) {
    final calTop = h * 0.05;
    final calH = h * 0.46;
    final cs = w / 7;
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;
    final totalCells = ((daysInMonth + firstWeekday - 1) / 7).ceil() * 7;

    return Positioned(
      left: w * 0.01, top: calTop, width: w * 0.98, height: calH,
      child: Column(children: [
        _dayNameRow(w, calH * 0.05),
        Expanded(child: _daysGrid(daysInMonth, firstWeekday, totalCells, w)),
      ]),
    );
  }

  Widget _dayNameRow(double w, double dh) {
    final days = ['L','M','M','J','V','S','D'];
    return SizedBox(width: w, height: dh,
      child: Row(children: days.map((d) => SizedBox(width: w / 7, child: Center(child: Text(d, style: GoogleFonts.bangers(color: _white.withValues(alpha: 0.5), fontSize: 9))))).toList()),
    );
  }

  Widget _daysGrid(int daysInMonth, int firstWeekday, int totalCells, double w) {

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.9,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNum = index - firstWeekday + 2;
        if (dayNum < 1 || dayNum > daysInMonth) {
          if (dayNum < 1) {
            final prevMonthDay = DateTime(_focusedDay.year, _focusedDay.month, 0).day + dayNum;
            return _dayCell(prevMonthDay, _green.withValues(alpha: 0.08), isOutside: true, num: prevMonthDay);
          }
          return _dayCell(0, Colors.transparent, isOutside: true, num: 0);
        }
        final color = _cellBg(DateTime(_focusedDay.year, _focusedDay.month, dayNum));
        final events = _getEventsForDay(DateTime(_focusedDay.year, _focusedDay.month, dayNum));
        final isToday = dayNum == DateTime.now().day && _focusedDay.month == DateTime.now().month && _focusedDay.year == DateTime.now().year;
        final isSelected = _selectedDay != null && dayNum == _selectedDay!.day && _focusedDay.month == _selectedDay!.month && _focusedDay.year == _selectedDay!.year;
        return _dayCell(dayNum, color, events: events, isToday: isToday, isSelected: isSelected);
      },
    );
  }

  Widget _dayCell(int day, Color bg, {List<Schedule>? events, bool isToday = false, bool isSelected = false, bool isOutside = false, int num = 0}) {
    if (day == 0) return const SizedBox.shrink();
    final hasEvents = events != null && events.isNotEmpty;
    final hasClasses = events?.any((e) => e.type == 'Clase') ?? false;
    final classForFacu = events?.any((e) => e.type == 'Clase' && e.userId == 'Facu') ?? false;
    final classForRocio = events?.any((e) => e.type == 'Clase' && e.userId == 'Rocio') ?? false;
    
    Color cellBg;
    if (isOutside) { cellBg = _green.withValues(alpha: 0.05); }
    else if (classForFacu) { cellBg = const Color(0xFF0088FF); }
    else if (classForRocio) { cellBg = const Color(0xFF9D00FF); }
    else if (hasEvents) { cellBg = bg; }
    else { cellBg = _green.withValues(alpha: 0.08); }

    Color textColor;
    if (isOutside) { textColor = _white.withValues(alpha: 0.15); }
    else if (hasClasses) { textColor = _white; }
    else if (hasEvents) { textColor = _white; }
    else { textColor = _white.withValues(alpha: 0.25); }

    return GestureDetector(
      onTap: () {
        if (!isOutside) {
          HapticFeedback.selectionClick();
          setState(() => _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, day));
        }
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: _white, width: 2) : (isToday ? Border.all(color: _brightBlue, width: 2) : null),
        ),
        child: Stack(children: [
          Center(child: Text('$day', style: GoogleFonts.bangers(color: textColor, fontSize: 13))),
          if (hasEvents && !hasClasses)
            Positioned(bottom: 2, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,
              children: events!.where((e) => e.type != 'Clase').take(3).map((e) => Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 0.5), decoration: BoxDecoration(color: Color(e.color), shape: BoxShape.circle))).toList(),
            )),
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
        Text(' Proximos', style: GoogleFonts.bangers(color: _green, fontSize: 14)),
        const SizedBox(height: 4),
        Expanded(
          child: upcoming.isEmpty
              ? Center(child: Text('Sin eventos', style: GoogleFonts.bangers(color: _white.withValues(alpha: 0.3), fontSize: 12)))
              : ListView.builder(
                  itemCount: upcoming.length,
                  itemBuilder: (context, i) {
                    final e = upcoming[i];
                    final isToday = isSameDay(e.date, DateTime.now());
                    final dateStr = '${e.date.day}/${e.date.month}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: GestureDetector(
                        onTap: () => _editSchedule(e),
                        onLongPress: () => _deleteSchedule(e),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _brightBlue.withValues(alpha: 0.15),
                              border: Border.all(color: _brightBlue, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Color(e.color).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(e.color), width: 2)),
                                child: Text(dateStr, style: GoogleFonts.bangers(color: Color(e.color), fontWeight: FontWeight.bold, fontSize: 10)),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(color: _brightBlue, border: Border.all(color: _black, width: 4), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)]),
            child: const Center(child: Icon(Icons.add, color: Color(0xFF000000), size: 28)),
          ),
        ),
      ),
    );
  }
}
