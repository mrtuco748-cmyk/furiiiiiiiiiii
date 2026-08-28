import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/class_schedule_provider.dart';
import '../../providers/class_type_provider.dart';
import '../../models/class_schedule.dart';
import '../../models/class_type.dart';
import '../../app_state.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';

const _c = Color(0xFF00D4FF);
const _dark = Color(0xFF0D0D0D);
const _near = Color(0xFF1A1A1A);
const _cDeep = Color(0xFF003344);
const _cBright = Color(0xFF0088AA);

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
      builder: (ctx) => _AddClassDialog(
        selectedDay: _selectedDay,
        onManageTypes: _manageTypes,
      ),
    ).then((_) => _loadData());
  }

  void _openEditDialog(ClassSchedule s) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => _AddClassDialog(
        selectedDay: _selectedDay,
        schedule: s,
        onManageTypes: _manageTypes,
      ),
    ).then((_) => _loadData());
  }

  void _manageTypes() {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final tp = ctx.read<ClassTypeProvider>();
          return AlertDialog(
            backgroundColor: _near,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _c, width: 4),
            ),
            title: Row(children: [
              const Icon(Icons.category, color: Color(0xFF00D4FF), size: 26),
              const SizedBox(width: 8),
              Text('Tipos de clase',
                  style: GoogleFonts.bangers(
                      color: _c,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: _manageField(nameCtrl, 'Nuevo tipo')),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF00D4FF), size: 30),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final picked = await showDialog<int>(
                          context: ctx,
                          builder: (c) => const _ColorPickerDialog(),
                        );
                        if (picked == null) return;
                        await tp.addType(ClassType(
                            name: nameCtrl.text.trim(), color: picked));
                        nameCtrl.clear();
                        setDialogState(() {});
                      },
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: tp.types.map((t) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Color(t.color),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        title: Text(t.name,
                            style: GoogleFonts.bangers(
                                color: Colors.white,
                                fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, size: 18, color: _cBright),
                              onPressed: () async {
                                final edited = await _editType(ctx, t);
                                if (edited != null) {
                                  await tp.updateType(edited);
                                  setDialogState(() {});
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: t.id == null
                                  ? null
                                  : () async {
                                      await tp.deleteType(t.id!);
                                      setDialogState(() {});
                                    },
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TapTile(
                onTap: () => Navigator.pop(ctx),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _near,
                      border: Border.all(color: _near, width: 3),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 22),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<ClassType?> _editType(BuildContext ctx, ClassType type) async {
    final nameCtrl = TextEditingController(text: type.name);
    int pickedColor = type.color;
    return showDialog<ClassType>(
      context: ctx,
      builder: (c) => StatefulBuilder(
        builder: (c, setEditState) => AlertDialog(
          backgroundColor: _near,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _c, width: 4),
          ),
          title: Text('Editar tipo',
              style: GoogleFonts.bangers(color: _c, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _manageField(nameCtrl, 'Nombre'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allColors.map((col) => GestureDetector(
                  onTap: () =>
                      setEditState(() => pickedColor = col.toARGB32()),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: col,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pickedColor == col.toARGB32()
                            ? _c
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TapTile(
              onTap: () => Navigator.pop(c),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _near,
                    border: Border.all(color: _near, width: 3),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
                  ),
                  child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 22),
                ),
              ),
            ),
            TapTile(
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(c, ClassType(
                  id: type.id,
                  name: nameCtrl.text.trim(),
                  color: pickedColor,
                ));
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _c,
                    border: Border.all(color: _c, width: 3),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _manageField(TextEditingController ctrl, String hint) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _dark,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.bangers(
              color: const Color(0xFF00D4FF), fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.bangers(
                color: const Color(0xFF0088AA), fontSize: 13),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSchedule(ClassSchedule s) async {
    HapticFeedback.heavyImpact();
    if (s.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _near,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.red, width: 4),
        ),
        title: const Icon(Icons.delete_forever, color: Colors.red, size: 40),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx, false),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _near,
                  border: Border.all(color: _near, width: 3),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
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
                  border: Border.all(color: Colors.red, width: 3),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
                ),
                child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
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
          ResponsiveWrapper(builder: (context, w, h) {

              if (_isLoading) return _loadingState(w, h);
              if (_hasError) return _errorState(w, h);

              return SizedBox(width: w, height: h, child: Stack(children: [
                _backBtn(w, h),
                _weekStrip(w, h),
                _classCards(w, h),
                _typesBtn(w, h),
                _addBtn(w, h),
                _xFloating(w, h),
              ]));
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

  Widget _weekStrip(double w, double h) {
    const names = ['LUN','MAR','MIÉ','JUE','VIE','SÁB','DOM'];
    final stripH = h * 0.075;
    return Positioned(
      left: w * 0.03, top: h * 0.10, width: w * 0.94, height: stripH,
      child: Row(children: List.generate(7, (i) {
        final day = i + 1;
        final selected = day == _selectedDay;
        final isToday = day == DateTime.now().weekday;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: TapTile(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? _c : (isToday ? const Color(0xFF0E2A38) : _near),
                  border: Border.all(color: selected ? _c : (isToday ? _c : _cDeep), width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)]
                      : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(names[i], style: GoogleFonts.bangers(fontSize: 11, fontWeight: FontWeight.w900,
                    color: selected ? _dark : (isToday ? _c : _white70))),
                ]),
              ),
            ),
          ),
        );
      })),
    );
  }

  static const _white70 = Color(0xB3FFFFFF);

  Widget _classCards(double w, double h) {
    final schedules = context.watch<ClassScheduleProvider>().getByDay(_selectedDay);
    final top = h * 0.195;

    if (schedules.isEmpty) {
      return Positioned(
        left: w * 0.03, top: top, width: w * 0.94, height: h * 0.74,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _near,
              border: Border.all(color: _near, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.event_busy, color: _cBright, size: 48),
              const SizedBox(height: 12),
              TapTile(
                onTap: _openAddDialog,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _c,
                      border: Border.all(color: _c, width: 4),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF0D0D0D), size: 30),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Positioned(
      left: w * 0.03, top: top, width: w * 0.94, height: h * 0.74,
      child: ListView(
        padding: EdgeInsets.zero,
        children: schedules.asMap().entries.map((entry) {
          final s = entry.value;
          final color = _typeColor(s.classTypeId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onLongPress: () => _deleteSchedule(s),
              child: TapTile(
                onTap: () => _openEditDialog(s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _near,
                      border: Border.all(color: _near, width: 4),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
                    ),
                    child: Row(children: [
                      Container(width: 8, height: 84, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.startTime, style: GoogleFonts.bangers(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
                            Text(s.endTime, style: GoogleFonts.bangers(color: _white70, fontSize: 11)),
                          ]),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.title, style: GoogleFonts.bangers(color: color, fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (s.professor.isNotEmpty)
                                Padding(padding: const EdgeInsets.only(top: 3), child: Text(s.professor, style: GoogleFonts.bangers(color: _white70, fontSize: 11))),
                            ]),
                          ),
                          Icon(Icons.school, color: color.withValues(alpha: 0.5), size: 26),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
    return SizedBox(width: w, height: h, child: Stack(children: [
      _backBtn(w, h),
      _weekStrip(w, h),
      Positioned(
        left: 0, top: h * 0.30, width: w, height: h * 0.4,
        child: Center(child: SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: _c, strokeWidth: 4))),
      ),
    ]));
  }

  Widget _errorState(double w, double h) {
    return SizedBox(width: w, height: h, child: Stack(children: [
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
    ]));
  }

  Widget _xFloating(double w, double h) {
    return Positioned(
      left: w * 0.01, top: h * 0.55,
      child: Container(width: 4, height: 22, color: _c),
    );
  }
}

class _AddClassDialog extends StatefulWidget {
  final int selectedDay;
  final ClassSchedule? schedule;
  final VoidCallback onManageTypes;
  const _AddClassDialog({
    required this.selectedDay,
    this.schedule,
    required this.onManageTypes,
  });

  @override
  State<_AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<_AddClassDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _profCtrl;
  late int _day;
  int? _typeId;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _startCtrl = TextEditingController(text: s?.startTime ?? '');
    _endCtrl = TextEditingController(text: s?.endTime ?? '');
    _profCtrl = TextEditingController(text: s?.professor ?? '');
    _day = s?.dayOfWeek ?? widget.selectedDay;
    _typeId = s?.classTypeId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _profCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _startCtrl.text.trim().isEmpty) {
      return;
    }
    HapticFeedback.heavyImpact();
    final provider = context.read<ClassScheduleProvider>();
    final types = context.read<ClassTypeProvider>().types;
    final existing = widget.schedule;
    final typeColor =
        types.where((t) => t.id == _typeId).map((t) => t.color).firstOrNull;
    final s = ClassSchedule(
      id: existing?.id,
      cloudId: existing?.cloudId,
      dayOfWeek: _day,
      classTypeId: _typeId,
      startTime: _startCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      endTime: _endCtrl.text.trim(),
      professor: _profCtrl.text.trim(),
      userId: existing?.userId ?? AppState.identity ?? '',
      color: typeColor ?? existing?.color ?? 0xFF7B2D8E,
    );
    try {
      if (existing != null) {
        await provider.updateSchedule(s);
      } else {
        await provider.addSchedule(s);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('ClassBoardScreen._saveSchedule error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('error', style: TextStyle(fontWeight: FontWeight.w900)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = context.watch<ClassTypeProvider>().types;
    final isEditing = widget.schedule != null;
    return AlertDialog(
      backgroundColor: _near,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _c, width: 4),
      ),
      title: Icon(isEditing ? Icons.edit : Icons.add, color: _c, size: 32),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _txtField(_titleCtrl, '...'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _txtField(_startCtrl, '08:00')),
            const SizedBox(width: 8),
            Expanded(child: _txtField(_endCtrl, '10:00')),
          ]),
          const SizedBox(height: 12),
          _txtField(_profCtrl, 'Profesor (opcional)'),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.calendar_view_day, color: Color(0xFF00D4FF), size: 20),
            const SizedBox(width: 8),
            Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (i) {
                  final d = i + 1;
                  final sel = d == _day;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TapTile(
                      onTap: () => setState(() => _day = d),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sel ? _c : _cDeep,
                            border: Border.all(color: sel ? _c : _cDeep, width: sel ? 3 : 2),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 0)],
                          ),
                          child: Text('$d', style: GoogleFonts.bangers(color: sel ? _dark : _c, fontSize: 13, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            )),
          ]),
          if (types.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.category, color: Color(0xFF00D4FF), size: 20),
              const SizedBox(width: 8),
              Expanded(child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: types.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TapTile(
                      onTap: () => setState(() => _typeId = t.id),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _typeId == t.id ? Color(t.color) : _dark,
                            border: Border.all(color: Color(t.color), width: 3),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 0)],
                          ),
                          child: Icon(Icons.book, color: _typeId == t.id ? _dark : Color(t.color), size: 22),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              )),
              TapTile(
                onTap: widget.onManageTypes,
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _cDeep,
                    border: Border.all(color: _cDeep, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.settings, color: Color(0xFF00D4FF), size: 20),
                ),
              ),
            ]),
          ],
        ]),
      ),
      actions: [
        TapTile(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _near,
                border: Border.all(color: _near, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
              ),
              child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 24),
            ),
          ),
        ),
        TapTile(
          onTap: _save,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _c,
                border: Border.all(color: _c, width: 4),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
              ),
              child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _txtField(TextEditingController ctrl, String hint) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: _dark,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.bangers(color: const Color(0xFF0088AA), fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }
}

const _allColors = [
  Color(0xFF7B2D8E), Color(0xFF4CAF50), Color(0xFFE53935), Color(0xFFFF9800),
  Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFF00BCD4), Color(0xFF795548),
  Color(0xFFE91E63), Color(0xFF3F51B5), Color(0xFF009688), Color(0xFF673AB7),
  Color(0xFFFF5722), Color(0xFF607D8B), Color(0xFFCDDC39), Color(0xFF8BC34A),
];

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog();

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  int _selected = 0xFF7B2D8E;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _near,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _c, width: 4),
      ),
      title: Text('Elegir color',
          style: GoogleFonts.bangers(color: _c, fontSize: 15)),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allColors.map((c) => GestureDetector(
          onTap: () {
            _selected = c.toARGB32();
            Navigator.pop(context, _selected);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selected == c.toARGB32() ? _c : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        )).toList(),
      ),
      actions: [
        TapTile(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _near,
                border: Border.all(color: _near, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 22),
            ),
          ),
        ),
      ],
    );
  }
}
