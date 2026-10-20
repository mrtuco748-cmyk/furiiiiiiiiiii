import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/schedule.dart';
import '../../providers/event_type_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';
import 'widgets/event_type_dialogs.dart';
import 'widgets/schedule_form_buttons.dart';
import 'widgets/schedule_form_card.dart';
import 'widgets/schedule_form_fields.dart';

const _c = Color(0xFF00D4FF);
const _dark = Color(0xFF0D0D0D);
const _near = Color(0xFF1A1A1A);

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
    final confirm = await ScheduleDeleteConfirmDialog.show(context);
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
          ResponsiveWrapper(
            builder: (context, w, h) {
              return SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    ScheduleBackButton(
                      width: w,
                      height: h,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                    ScheduleFormCard(
                      width: w,
                      height: h,
                      titleCtrl: _titleCtrl,
                      descCtrl: _descCtrl,
                      locCtrl: _locCtrl,
                      instCtrl: _instCtrl,
                      startTimeCtrl: _startTimeCtrl,
                      endTimeCtrl: _endTimeCtrl,
                      date: _date,
                      selectedType: _type,
                      types: types,
                      onPickDate: _pickDate,
                      onPickTime: _pickTime,
                      onOpenTypePicker: () => EventTypeDialogs.showTypePicker(
                        context: context,
                        types: types,
                        selectedType: _type,
                        onSelected: (t) => setState(() {
                          _type = t.name;
                          _color = t.color;
                        }),
                      ),
                      onManageTypes: () => EventTypeDialogs.showManageTypesDialog(
                        context: context,
                        currentType: _type,
                        onTypeDeleted: (reset) => setState(() => _type = reset),
                      ),
                    ),
                    ScheduleSaveButton(
                      width: w,
                      height: h,
                      saving: _saving,
                      onTap: _save,
                    ),
                    if (isEditing)
                      ScheduleDeleteButton(
                        width: w,
                        height: h,
                        onTap: _delete,
                      ),
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

  Widget _xFloating(double w, double h) {
    return Positioned(
      left: w * 0.03,
      bottom: h * 0.12,
      child: Container(width: 3, height: 20, color: _c),
    );
  }
}
