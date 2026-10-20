import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/class_schedule.dart';
import '../../providers/class_schedule_provider.dart';
import '../../providers/class_type_provider.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/tap_tile.dart';
import 'widgets/add_class_dialog.dart';
import 'widgets/class_board_week_strip.dart';
import 'widgets/class_delete_confirm_dialog.dart';
import 'widgets/class_schedule_cards.dart';
import 'widgets/class_type_dialogs.dart';

const _c = Color(0xFF00D4FF);
const _near = Color(0xFF1A1A1A);
const _cDeep = Color(0xFF003344);

Widget fillIcon(IconData icon, Color color) {
  return FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)),
  );
}

class ClassBoardScreen extends StatefulWidget {
  const ClassBoardScreen({super.key});

  @override
  State<ClassBoardScreen> createState() => _ClassBoardScreenState();
}

class _ClassBoardScreenState extends State<ClassBoardScreen> {
  int _selectedDay = DateTime.now().weekday;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      await Future.wait([
        context.read<ClassScheduleProvider>().loadSchedules(),
        context.read<ClassTypeProvider>().loadTypes(),
      ]);
      if (mounted) setState(() { _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
      debugPrint('ClassBoardScreen._init error: $e');
    }
  }

  Color _typeColor(int? typeId) {
    if (typeId == null) return _c;
    final types = context.read<ClassTypeProvider>().types;
    return Color(types.where((t) => t.id == typeId).map((t) => t.color).firstOrNull ?? 0xFF00D4FF);
  }

  void _openAddDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AddClassDialog(
        selectedDay: _selectedDay,
        onManageTypes: _manageTypes,
      ),
    ).then((_) => _loadData());
  }

  void _openEditDialog(ClassSchedule s) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AddClassDialog(
        selectedDay: _selectedDay,
        schedule: s,
        onManageTypes: _manageTypes,
      ),
    ).then((_) => _loadData());
  }

  void _manageTypes() {
    ClassTypeDialogs.showManageTypes(context);
  }

  Future<void> _deleteSchedule(ClassSchedule s) async {
    HapticFeedback.heavyImpact();
    if (s.id == null) return;
    final confirm = await ClassDeleteConfirmDialog.show(context);
    if (confirm == true && mounted) {
      await context.read<ClassScheduleProvider>().deleteSchedule(s.id!);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _near,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          ResponsiveWrapper(
            builder: (context, w, h) {
              if (_isLoading) return _loadingState(w, h);
              if (_hasError) return _errorState(w, h);

              final schedules = context.watch<ClassScheduleProvider>().getByDay(_selectedDay);

              return SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    _backBtn(w, h),
                    ClassBoardWeekStrip(
                      width: w,
                      height: h,
                      selectedDay: _selectedDay,
                      onSelectDay: (day) => setState(() => _selectedDay = day),
                    ),
                    ClassScheduleCards(
                      width: w,
                      height: h,
                      schedules: schedules,
                      typeColor: _typeColor,
                      onOpenAdd: _openAddDialog,
                      onOpenEdit: _openEditDialog,
                      onDelete: _deleteSchedule,
                    ),
                    _typesBtn(w, h),
                    _addBtn(w, h),
                    _xFloating(w, h),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _backBtn(double w, double h) {
    return Positioned(
      left: w * 0.02, top: h * 0.01, width: w * 0.12, height: h * 0.06,
      child: TapTile(
        onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _c,
              border: Border.all(color: _c, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: const Center(child: Icon(Icons.arrow_back, color: Color(0xFF0D0D0D), size: 26)),
          ),
        ),
      ),
    );
  }

  Widget _typesBtn(double w, double h) {
    return Positioned(
      right: w * 0.04, top: h * 0.02, width: w * 0.11, height: w * 0.11,
      child: TapTile(
        onTap: _manageTypes,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: _cDeep,
              border: Border.all(color: _cDeep, width: 4),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
            ),
            child: const Center(child: Icon(Icons.category, color: Color(0xFF00D4FF), size: 24)),
          ),
        ),
      ),
    );
  }

  Widget _addBtn(double w, double h) {
    return Positioned(
      right: w * 0.04, bottom: h * 0.04, width: w * 0.13, height: w * 0.13,
      child: TapTile(
        onTap: _openAddDialog,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _c,
              border: Border.all(color: _c, width: 5),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: const Center(child: Icon(Icons.add, color: Color(0xFF0D0D0D), size: 30)),
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
        ClassBoardWeekStrip(
          width: w,
          height: h,
          selectedDay: _selectedDay,
          onSelectDay: (day) => setState(() => _selectedDay = day),
        ),
        Positioned(
          left: 0, top: h * 0.30, width: w, height: h * 0.4,
          child: const Center(child: SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: _c, strokeWidth: 4))),
        ),
      ]),
    );
  }

  Widget _errorState(double w, double h) {
    return SizedBox(
      width: w,
      height: h,
      child: Stack(children: [
        _backBtn(w, h),
        Positioned(
          left: w * 0.12, top: h * 0.28, width: w * 0.76, height: h * 0.38,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF330000),
                border: Border.all(color: Colors.red, width: 5),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 44),
                const SizedBox(height: 14),
                TapTile(
                  onTap: () { HapticFeedback.lightImpact(); _loadData(); },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _near,
                        border: Border.all(color: _near, width: 3),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
                      ),
                      child: const Icon(Icons.refresh, color: Colors.red, size: 28),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _xFloating(double w, double h) {
    return Positioned(
      left: w * 0.01, top: h * 0.55,
      child: Container(width: 4, height: 22, color: _c),
    );
  }
}
