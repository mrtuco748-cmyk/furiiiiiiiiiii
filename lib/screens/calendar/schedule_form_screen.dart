import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/event_type_provider.dart';
import '../../models/schedule.dart';
import '../../models/event_type.dart';
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

class ScheduleFormScreen extends StatefulWidget {
  final Schedule? schedule;
  final DateTime? initialDate;

  const ScheduleFormScreen({super.key, this.schedule, this.initialDate});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _instCtrl;
  late final TextEditingController _startTimeCtrl;
  late final TextEditingController _endTimeCtrl;

  late DateTime _date;
  String _type = 'Clase';
  int _color = 0xFF7B2D8E;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _locCtrl = TextEditingController(text: s?.location ?? '');
    _instCtrl = TextEditingController(text: s?.instructor ?? '');
    _startTimeCtrl = TextEditingController(text: s?.startTime ?? '');
    _endTimeCtrl = TextEditingController(text: s?.endTime ?? '');
    _date = s?.date ?? widget.initialDate ?? DateTime.now();
    _type = s?.type ?? 'Clase';
    _color = s?.color ?? 0xFF7B2D8E;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _instCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _c, onPrimary: _dark, surface: _near),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    HapticFeedback.selectionClick();
    final parts = ctrl.text.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 12, minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 12, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _c, onPrimary: _dark, surface: _near),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      ctrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showTypePicker(List<EventType> types) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _near,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _c, width: 4),
        ),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 260,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Icon(Icons.category, color: _c, size: 36)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: types.map((t) => TapTile(
                onTap: () {
                  setState(() { _type = t.name; _color = t.color; });
                  Navigator.pop(ctx);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _type == t.name ? _c : _near,
                      border: Border.all(color: Color(t.color), width: 3),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
                    ),
                    child: Icon(t.iconData, color: _type == t.name ? _dark : Color(t.color), size: 28),
                  ),
                ),
              )).toList(),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    HapticFeedback.heavyImpact();
    setState(() => _saving = true);

    final provider = context.read<ScheduleProvider>();
    final s = Schedule(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      date: _date,
      startTime: _startTimeCtrl.text,
      endTime: _endTimeCtrl.text,
      location: _locCtrl.text.trim(),
      instructor: _instCtrl.text.trim(),
      type: _type,
      color: _color,
      userId: AppState.identity ?? '',
    );

    try {
      if (widget.schedule != null) {
        await provider.updateSchedule(s.copyWith(id: widget.schedule!.id));
      } else {
        await provider.addSchedule(s);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('ScheduleFormScreen._save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error al guardar', style: GoogleFonts.bangers(fontSize: 12, color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (widget.schedule?.id == null) return;
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
      await context.read<ScheduleProvider>().deleteSchedule(widget.schedule!.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = context.watch<EventTypeProvider>().types;
    final isEditing = widget.schedule != null;

    return Scaffold(
      backgroundColor: _near,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          ResponsiveWrapper(builder: (context, w, h) {
              return SizedBox(width: w, height: h, child: Stack(children: [
                _backBtn(w, h),
                _formBlock(w, h, types),
                _saveBtn(w, h),
                if (isEditing) _deleteBtn(w, h),
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
      left: w * 0.02, top: h * 0.01, width: w * 0.13, height: h * 0.06,
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

  Widget _formBlock(double w, double h, List<EventType> types) {
    return Positioned(
      left: w * 0.04, top: h * 0.09, width: w * 0.92, height: h * 0.74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _c,
            border: Border.all(color: _c, width: 4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.title, color: Color(0xFF00D4FF), size: 22),
                const SizedBox(width: 10),
                Expanded(child: _textField(_titleCtrl, '...')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.category, color: Color(0xFF00D4FF), size: 22),
                const SizedBox(width: 10),
                Expanded(child: _typeSelector(types)),
                const SizedBox(width: 6),
                _manageTypesBtn(),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.calendar_today, color: Color(0xFF00D4FF), size: 22),
                const SizedBox(width: 10),
                Expanded(child: _dateField()),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.access_time, color: Color(0xFF00D4FF), size: 22),
                const SizedBox(width: 10),
                Expanded(child: _timeField(_startTimeCtrl)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Color(0xFF0088AA), size: 18),
                const SizedBox(width: 8),
                Expanded(child: _timeField(_endTimeCtrl)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.place, color: Color(0xFF00D4FF), size: 22),
                const SizedBox(width: 10),
                Expanded(child: _textField(_locCtrl, '...')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.badge, color: Color(0xFF00D4FF), size: 22),
                const SizedBox(width: 10),
                Expanded(child: _textField(_instCtrl, 'profesor (opcional)')),
              ]),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.notes, color: Color(0xFF0088AA), size: 22)),
                const SizedBox(width: 10),
                Expanded(child: _textField(_descCtrl, '...', maxLines: 3)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: _near,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.bangers(color: const Color(0xFF0088AA), fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _typeSelector(List<EventType> types) {
    final currentType = types.where((t) => t.name == _type).firstOrNull;
    final icon = currentType?.iconData ?? Icons.category;
    final displayColor = currentType != null ? Color(currentType.color) : _c;

    return TapTile(
      onTap: types.isNotEmpty ? () => _showTypePicker(types) : () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _near,
            border: Border.all(color: displayColor, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: Row(children: [
            Icon(icon, color: displayColor, size: 28),
            const SizedBox(width: 8),
            Icon(Icons.category, color: displayColor, size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _manageTypesBtn() {
    return TapTile(
      onTap: _manageTypesDialog,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _near,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: const Icon(Icons.settings, color: Color(0xFF00D4FF), size: 22),
      ),
    );
  }

  Widget _manageTextField(TextEditingController ctrl, String hint) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _near,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.bangers(color: _c, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.bangers(color: _cDeep, fontSize: 13),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ),
    );
  }

  Future<void> _manageTypesDialog() async {
    HapticFeedback.selectionClick();
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final etp = ctx.read<EventTypeProvider>();
          return AlertDialog(
            backgroundColor: _near,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _c, width: 4),
            ),
            title: Row(children: [
              const Icon(Icons.category, color: Color(0xFF00D4FF), size: 26),
              const SizedBox(width: 8),
              Text('Tipos de evento',
                  style: GoogleFonts.bangers(color: _c, fontSize: 15)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: _manageTextField(nameCtrl, 'Nuevo tipo')),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF00D4FF), size: 30),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final picked = await showDialog<int>(
                          context: ctx,
                          builder: (c) => const _EventColorPickerDialog(),
                        );
                        if (picked == null || !ctx.mounted) return;
                        final icon = await _pickIconDialog(ctx, 'event');
                        if (icon == null || !ctx.mounted) return;
                        await etp.addType(EventType(
                          name: nameCtrl.text.trim(),
                          color: picked,
                          icon: icon,
                        ));
                        nameCtrl.clear();
                        setDialogState(() {});
                      },
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: etp.types.map((t) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(t.iconData, color: Color(t.color), size: 22),
                        title: Text(t.name,
                            style: GoogleFonts.bangers(
                                color: Colors.white, fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: t.id == null
                              ? null
                              : () async {
                                  await etp.deleteType(t.id!);
                                  if (t.name == _type) {
                                    setState(() => _type = 'Clase');
                                  }
                                  setDialogState(() {});
                                },
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
                      border: Border.all(color: _c, width: 3),
                      borderRadius: BorderRadius.circular(18),
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

  Future<String?> _pickIconDialog(BuildContext ctx, String current) async {
    String selected = current;
    const iconNames = [
      'event', 'school', 'book', 'assignment', 'science', 'alarm',
      'schedule', 'star', 'favorite', 'celebration', 'restaurant', 'coffee',
      'cake', 'shopping_cart', 'notifications', 'group', 'workspaces',
      'check_circle', 'edit_note', 'description', 'menu_book', 'auto_stories',
      'pan_tool', 'handyman', 'local_dining', 'fastfood', 'local_pizza',
      'local_bar', 'wine_bar', 'menu',
    ];
    return showDialog<String>(
      context: ctx,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialogState) {
          return AlertDialog(
            backgroundColor: _near,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _c, width: 4),
            ),
            title: Text('Elegir icono',
                style: GoogleFonts.bangers(color: _c, fontSize: 15)),
            content: SizedBox(
              width: 300,
              height: 280,
              child: GridView.count(
                crossAxisCount: 6,
                childAspectRatio: 1,
                children: iconNames.map((name) {
                  final sel = selected == name;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selected = name),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: sel ? _c : _dark,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: sel ? _c : _cBright, width: 2),
                      ),
                      child: Icon(
                        EventType(name: '', color: 0, icon: name).iconData,
                        color: sel ? _dark : _c,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
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
                      border: Border.all(color: _c, width: 3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 22),
                  ),
                ),
              ),
              TapTile(
                onTap: () => Navigator.pop(c, selected),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _c,
                      border: Border.all(color: _dark, width: 3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 22),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dateField() {
    return TapTile(
      onTap: _pickDate,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _near,
            border: Border.all(color: _c, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today, color: Color(0xFF00D4FF), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('EEE d MMM', 'es').format(_date),
                style: GoogleFonts.bangers(color: _c, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _timeField(TextEditingController ctrl) {
    return TapTile(
      onTap: () => _pickTime(ctrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _near,
            border: Border.all(color: _c, width: 3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.access_time, color: Color(0xFF00D4FF), size: 18),
            const SizedBox(width: 6),
            Text(
              ctrl.text.isEmpty ? '--:--' : ctrl.text,
              style: GoogleFonts.bangers(color: _c, fontSize: 13),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _saveBtn(double w, double h) {
    return Positioned(
      left: w * 0.20, bottom: h * 0.04, width: w * 0.60, height: h * 0.08,
      child: TapTile(
        onTap: _saving ? () {} : _save,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _saving ? _cDeep : _c,
              border: Border.all(color: _saving ? _cDeep : _c, width: 5),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Center(
              child: _saving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: _dark))
                  : const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteBtn(double w, double h) {
    return Positioned(
      right: w * 0.06, top: h * 0.85, width: w * 0.13, height: w * 0.13,
      child: TapTile(
        onTap: _delete,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4A0000),
              border: Border.all(color: const Color(0xFF4A0000), width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: const Center(child: Icon(Icons.delete, color: Colors.red, size: 28)),
          ),
        ),
      ),
    );
  }

  Widget _xFloating(double w, double h) {
    return Positioned(
      left: w * 0.03, bottom: h * 0.12,
      child: Container(width: 3, height: 20, color: _c),
    );
  }
}

const _eventColors = [
  Color(0xFF7B2D8E), Color(0xFF4CAF50), Color(0xFFE53935), Color(0xFFFF9800),
  Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFF00BCD4), Color(0xFF795548),
  Color(0xFFE91E63), Color(0xFF3F51B5), Color(0xFF009688), Color(0xFF673AB7),
  Color(0xFFFF5722), Color(0xFF607D8B), Color(0xFFCDDC39), Color(0xFF8BC34A),
];

class _EventColorPickerDialog extends StatefulWidget {
  const _EventColorPickerDialog();

  @override
  State<_EventColorPickerDialog> createState() =>
      _EventColorPickerDialogState();
}

class _EventColorPickerDialogState extends State<_EventColorPickerDialog> {
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
        children: _eventColors.map((c) => GestureDetector(
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
                border: Border.all(color: _c, width: 3),
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
