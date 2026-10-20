import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/class_schedule.dart';
import '../../models/event_type.dart';
import '../../models/schedule.dart';
import '../../providers/class_schedule_provider.dart';
import '../../providers/event_type_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../router.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/tap_tile.dart';
import 'widgets/daily_date_nav.dart';
import 'widgets/daily_events_list_view.dart';

const _c = Color(0xFF00D4FF);
const _dark = Color(0xFF0D0D0D);
const _near = Color(0xFF1A1A1A);

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
          colorScheme: const ColorScheme.dark(
              primary: _c, onPrimary: _dark, surface: _near),
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
    await context
        .push(RouterRoutes.scheduleForm, extra: _selectedDate)
        .then((_) => _loadData());
  }

  Future<void> _editEvent(Schedule s) async {
    HapticFeedback.mediumImpact();
    await context
        .push(RouterRoutes.scheduleForm, extra: s)
        .then((_) => _loadData());
  }

  Future<void> _deleteEvent(Schedule s) async {
    if (s.id == null) return;
    HapticFeedback.heavyImpact();
    final confirm = await DailyDeleteDialog.show(context, s);
    if (confirm == true && mounted) {
      await context.read<ScheduleProvider>().deleteSchedule(s.id!);
      await _loadData();
    }
  }

  void _openClasses() {
    HapticFeedback.mediumImpact();
    context.push(RouterRoutes.classBoard).then((_) => _loadData());
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

            final events = _dayEvents;
            final classes = _dayClasses;
            final isEmpty = events.isEmpty && classes.isEmpty;

            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  _backBtn(w, h),
                  Positioned(
                    left: w * 0.16,
                    top: h * 0.012,
                    width: w * 0.68,
                    height: h * 0.055,
                    child: DailyDateNav(
                      selectedDate: _selectedDate,
                      onShiftDay: _shiftDay,
                      onPickDate: _pickDate,
                    ),
                  ),
                  Positioned(
                    left: isEmpty ? w * 0.08 : w * 0.04,
                    top: isEmpty ? h * 0.12 : h * 0.10,
                    width: isEmpty ? w * 0.84 : w * 0.92,
                    height: isEmpty ? h * 0.60 : h * 0.82,
                    child: DailyEventsListView(
                      events: events,
                      classes: classes,
                      eventTypeResolver: _eventType,
                      onOpenForm: _openForm,
                      onOpenClasses: _openClasses,
                      onEditEvent: _editEvent,
                      onDeleteEvent: _deleteEvent,
                    ),
                  ),
                  _addBtn(w, h),
                  _xFloating(w, h),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _backBtn(double w, double h) => Positioned(
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
                border: Border.all(color: _c, width: 4),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5))
                ],
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Color(0xFF0D0D0D), size: 26),
              ),
            ),
          ),
        ),
      );

  Widget _addBtn(double w, double h) => Positioned(
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
                border: Border.all(color: _c, width: 5),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5))
                ],
              ),
              child: const Center(
                child: Icon(Icons.add, color: Color(0xFF0D0D0D), size: 30),
              ),
            ),
          ),
        ),
      );

  Widget _loadingState(double w, double h) => SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            _backBtn(w, h),
            Positioned(
              left: w * 0.08,
              top: h * 0.20,
              width: w * 0.84,
              height: h * 0.30,
              child: const DailyLoadingView(),
            ),
          ],
        ),
      );

  Widget _errorState(double w, double h) => SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            _backBtn(w, h),
            Positioned(
              left: w * 0.12,
              top: h * 0.28,
              width: w * 0.76,
              height: h * 0.38,
              child: DailyErrorView(
                onRetry: () {
                  HapticFeedback.lightImpact();
                  _loadData();
                },
              ),
            ),
          ],
        ),
      );

  Widget _xFloating(double w, double h) => Positioned(
        left: w * 0.01,
        top: h * 0.55,
        child: Container(width: 4, height: 22, color: _c),
      );
}
