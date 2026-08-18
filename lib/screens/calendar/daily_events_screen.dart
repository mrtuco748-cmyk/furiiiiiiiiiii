import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/class_schedule.dart';
import '../../models/event_type.dart';
import '../../models/schedule.dart';
import '../../providers/class_schedule_provider.dart';
import '../../providers/event_type_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/tap_tile.dart';
import 'class_board_screen.dart';
import 'schedule_form_screen.dart';

const _c = Color(0xFF00D4FF);
const _dark = Color(0xFF000000);
const _near = Color(0xFF1A1A1A);
const _cDeep = Color(0xFF003344);
const _cBright = Color(0xFF0088AA);

/// Lista de eventos fechados + clases recurrentes de un día concreto,
/// con navegación día a día y date picker.
class DailyEventsScreen extends StatefulWidget {
  final DateTime? initialDate;
  const DailyEventsScreen({super.key, this.initialDate});

  @override
  State<DailyEventsScreen> createState() => _DailyEventsScreenState();
}

class _DailyEventsScreenState extends State<DailyEventsScreen> {
  late DateTime _selectedDate;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      await Future.wait([
        context.read<ScheduleProvider>().loadSchedules(),
        context.read<ClassScheduleProvider>().loadSchedules(),
        context.read<EventTypeProvider>().loadTypes(),
      ]);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      debugPrint('DailyEventsScreen._loadData error: $e');
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Schedule> get _dayEvents {
    final pv = context.read<ScheduleProvider>();
    return pv.schedules
        .where((s) => _sameDay(s.date, _selectedDate))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<ClassSchedule> get _dayClasses =>
      context.read<ClassScheduleProvider>().getByDay(_selectedDate.weekday);

  EventType? _eventType(String name) => context
      .read<EventTypeProvider>()
      .types
      .where((t) => t.name == name)
      .firstOrNull;

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme:
              const ColorScheme.dark(primary: _c, onPrimary: _dark, surface: _near),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  void _shiftDay(int delta) {
    HapticFeedback.lightImpact();
    setState(() => _selectedDate = _selectedDate.add(Duration(days: delta)));
  }

  Future<void> _openForm() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => ScheduleFormScreen(initialDate: _selectedDate)))
        .then((_) => _loadData());
  }

  Future<void> _editEvent(Schedule s) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ScheduleFormScreen(schedule: s)))
        .then((_) => _loadData());
  }

  Future<void> _deleteEvent(Schedule s) async {
    if (s.id == null) return;
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _near,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.red, width: 4),
        ),
        title: const Icon(Icons.delete_forever, color: Colors.red, size: 40),
        content: Text(s.title,
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx, false),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _dark,
                  border: Border.all(color: _c, width: 3),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)
                  ],
                ),
                child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TapTile(
            onTap: () => Navigator.pop(ctx, true),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  border: Border.all(color: _dark, width: 3),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)
                  ],
                ),
                child: const Icon(Icons.check, color: Color(0xFF000000), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ScheduleProvider>().deleteSchedule(s.id!);
      await _loadData();
    }
  }

  void _openClasses() {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ClassBoardScreen()))
        .then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _near,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          ResponsiveWrapper(builder: (context, w, h) {
            if (_isLoading) return _loadingState(w, h);
            if (_hasError) return _errorState(w, h);

            return SizedBox(width: w, height: h, child: Stack(children: [
              _backBtn(w, h),
              _dateNav(w, h),
              _listBlock(w, h),
              _addBtn(w, h),
              _xFloating(w, h),
            ]));
          }),
        ],
      ),
    );
  }

  Widget _backBtn(double w, double h) {
    return Positioned(
      left: w * 0.02,
      top: h * 0.01,
      width: w * 0.12,
      height: h * 0.06,
      child: TapTile(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _c,
              border: Border.all(color: _dark, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)
              ],
            ),
            child: const Center(
                child: Icon(Icons.arrow_back, color: Color(0xFF000000), size: 26)),
          ),
        ),
      ),
    );
  }

  Widget _dateNav(double w, double h) {
    final today = _sameDay(_selectedDate, DateTime.now());
    return Positioned(
      left: w * 0.16,
      top: h * 0.012,
      width: w * 0.68,
      height: h * 0.055,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _cDeep,
            border: Border.all(color: _c, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)
            ],
          ),
          child: Row(children: [
            TapTile(
              onTap: () => _shiftDay(-1),
              child: const Icon(Icons.chevron_left, color: Color(0xFF00D4FF), size: 24),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEEE d MMM', 'es').format(_selectedDate),
                      style: GoogleFonts.bangers(
                          color: today ? _c : Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (today)
                      Text('HOY',
                          style: GoogleFonts.bangers(
                              color: _cBright, fontSize: 9)),
                  ],
                ),
              ),
            ),
            TapTile(
              onTap: () => _shiftDay(1),
              child: const Icon(Icons.chevron_right, color: Color(0xFF00D4FF), size: 24),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _listBlock(double w, double h) {
    final events = _dayEvents;
    final classes = _dayClasses;

    if (events.isEmpty && classes.isEmpty) {
      return Positioned(
        left: w * 0.08,
        top: h * 0.12,
        width: w * 0.84,
        height: h * 0.60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _near,
              border: Border.all(color: _cBright, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)
              ],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.event_busy, color: _cBright, size: 48),
              const SizedBox(height: 10),
              Text('Sin eventos este dia',
                  style: GoogleFonts.bangers(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
              const SizedBox(height: 14),
              TapTile(
                onTap: _openForm,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _c,
                      border: Border.all(color: _dark, width: 4),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)
                      ],
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF000000), size: 30),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Positioned(
      left: w * 0.04,
      top: h * 0.10,
      width: w * 0.92,
      height: h * 0.82,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          if (classes.isNotEmpty) ...[
            Text('CLASES', style: GoogleFonts.bangers(color: _c, fontSize: 13)),
            const SizedBox(height: 4),
            ...classes.map((cs) => _classCard(cs)),
            const SizedBox(height: 10),
          ],
          if (events.isNotEmpty) ...[
            Text('EVENTOS', style: GoogleFonts.bangers(color: _c, fontSize: 13)),
            const SizedBox(height: 4),
            ...events.map((e) => _eventCard(e)),
          ],
        ],
      ),
    );
  }

  Widget _classCard(ClassSchedule cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _openClasses,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _dark,
              border: Border.all(color: _c, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)
              ],
            ),
            child: Row(children: [
              const Icon(Icons.school, color: Color(0xFF00D4FF), size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cs.title,
                        style: GoogleFonts.bangers(
                            color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      cs.endTime.isNotEmpty
                          ? '${cs.startTime} - ${cs.endTime}${cs.professor.isNotEmpty ? ' · ${cs.professor}' : ''}'
                          : '${cs.startTime}${cs.professor.isNotEmpty ? ' · ${cs.professor}' : ''}',
                      style: GoogleFonts.bangers(
                          color: _cBright, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3), size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _eventCard(Schedule s) {
    final type = _eventType(s.type);
    final color = type != null ? Color(type.color) : Color(s.color);
    final icon = type?.iconData ?? Icons.event;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _editEvent(s),
        onLongPress: () => _deleteEvent(s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _dark,
              border: Border.all(color: color, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)
              ],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        style: GoogleFonts.bangers(
                            color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '${s.startTime} - ${s.endTime}${s.location.isNotEmpty ? ' · ${s.location}' : ''}',
                      style: GoogleFonts.bangers(color: color, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit, color: color, size: 18),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _addBtn(double w, double h) {
    return Positioned(
      right: w * 0.04,
      bottom: h * 0.04,
      width: w * 0.13,
      height: w * 0.13,
      child: TapTile(
        onTap: _openForm,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _c,
              border: Border.all(color: _dark, width: 5),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)
              ],
            ),
            child: const Center(
                child: Icon(Icons.add, color: Color(0xFF000000), size: 30)),
          ),
        ),
      ),
    );
  }

  Widget _loadingState(double w, double h) {
    return SizedBox(
        width: w,
        height: h,
        child: Stack(children: [
          _backBtn(w, h),
          Positioned(
            left: w * 0.08,
            top: h * 0.20,
            width: w * 0.84,
            height: h * 0.30,
            child: Center(
                child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(color: _c, strokeWidth: 4))),
          ),
        ]));
  }

  Widget _errorState(double w, double h) {
    return SizedBox(
        width: w,
        height: h,
        child: Stack(children: [
          _backBtn(w, h),
          Positioned(
            left: w * 0.12,
            top: h * 0.28,
            width: w * 0.76,
            height: h * 0.38,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF330000),
                  border: Border.all(color: Colors.red, width: 5),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)
                  ],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 44),
                  const SizedBox(height: 14),
                  TapTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _loadData();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _dark,
                          border: Border.all(color: Colors.red, width: 3),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)
                          ],
                        ),
                        child: const Icon(Icons.refresh, color: Colors.red, size: 28),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]));
  }

  Widget _xFloating(double w, double h) {
    return Positioned(
      left: w * 0.01,
      top: h * 0.55,
      child: Container(width: 4, height: 22, color: _c),
    );
  }
}
