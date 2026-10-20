import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../models/class_schedule.dart';
import '../../../providers/class_schedule_provider.dart';
import '../../../providers/class_type_provider.dart';
import '../../../widgets/tap_tile.dart';

const Color _c = Color(0xFF00D4FF);
const Color _dark = Color(0xFF0D0D0D);
const Color _near = Color(0xFF1A1A1A);
const Color _cDeep = Color(0xFF003344);

class AddClassDialog extends StatefulWidget {
  final int selectedDay;
  final ClassSchedule? schedule;
  final VoidCallback onManageTypes;

  const AddClassDialog({
    super.key,
    required this.selectedDay,
    this.schedule,
    required this.onManageTypes,
  });

  @override
  State<AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> {
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
      debugPrint('AddClassDialog._save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('error', style: TextStyle(fontWeight: FontWeight.w900)),
            backgroundColor: Colors.red,
          ),
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
            Expanded(
              child: SingleChildScrollView(
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
              ),
            ),
          ]),
          if (types.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.category, color: Color(0xFF00D4FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
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
                ),
              ),
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
