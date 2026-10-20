import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/class_schedule.dart';
import '../../models/recurrence.dart';
import '../../models/schedule.dart';
import '../../providers/class_schedule_provider.dart';
import 'day_agenda.dart';
import 'widgets/event_recurrence_picker.dart';
import 'widgets/event_sheet_inputs.dart';
import 'widgets/event_sheet_utils.dart';

export 'widgets/event_sheet_utils.dart';

/// Abre el formulario único de evento (crear o editar).
Future<void> showEventSheet(
  BuildContext context, {
  required DateTime day,
  Schedule? schedule,
  ClassSchedule? legacyClass,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: calPanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => EventSheet(
      day: day,
      schedule: schedule,
      legacyClass: legacyClass,
    ),
  );
}

class EventSheet extends StatefulWidget {
  final DateTime day;
  final Schedule? schedule;
  final ClassSchedule? legacyClass;

  const EventSheet({
    super.key,
    required this.day,
    this.schedule,
    this.legacyClass,
  });

  @override
  State<EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<EventSheet> {
  late final TextEditingController _title;
  late final TextEditingController _place;
  late DateTime _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  late RecurrenceKind _kind;
  Set<int> _weekdays = {};
  int _everyN = 2;
  late int _color;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.schedule != null || widget.legacyClass != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    final c = widget.legacyClass;
    _title = TextEditingController(text: s?.title ?? c?.title ?? '');
    _place = TextEditingController(text: s?.location ?? c?.professor ?? '');
    _date = s?.date ?? widget.day;
    _start = parseTimeOfDay(s?.startTime ?? c?.startTime);
    _end = parseTimeOfDay(s?.endTime ?? c?.endTime);
    _color = s?.color ?? c?.color ?? defaultColorFor(AppState.identity);

    if (c != null) {
      final group = DayAgenda.legacyGroup(
          context.read<ClassScheduleProvider>().schedules, c);
      _kind = RecurrenceKind.weekly;
      _weekdays = group.map((x) => x.dayOfWeek).toSet();
    } else {
      final r = Recurrence.parse(s?.recurrence);
      _kind = r.kind;
      _weekdays = r.kind == RecurrenceKind.weekly
          ? {...r.weekdays}
          : {widget.day.weekday};
      if (r.kind == RecurrenceKind.everyNDays) _everyN = r.interval;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    super.dispose();
  }

  Recurrence get _rule {
    switch (_kind) {
      case RecurrenceKind.none:
        return Recurrence.none;
      case RecurrenceKind.weekly:
        return Recurrence.weekly(_weekdays);
      case RecurrenceKind.everyNDays:
        return Recurrence.everyNDays(_everyN);
      case RecurrenceKind.monthly:
        return Recurrence.monthly();
      case RecurrenceKind.yearly:
        return Recurrence.yearly();
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Poné un título');
      return;
    }
    if (_kind == RecurrenceKind.weekly && _weekdays.isEmpty) {
      setState(() => _error = 'Elegí al menos un día');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final base = Schedule(
      id: widget.schedule?.id,
      cloudId: widget.schedule?.cloudId,
      title: title,
      date: DateTime(_date.year, _date.month, _date.day),
      startTime: formatTimeOfDay(_start),
      endTime: formatTimeOfDay(_end),
      location: _place.text.trim(),
      type: 'Evento',
      color: _color,
      userId: widget.schedule?.userId ??
          widget.legacyClass?.userId ??
          AppState.identity ??
          '',
      recurrence: _rule.encode(),
      createdAt: widget.schedule?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await saveAgendaEvent(
        context,
        base: base,
        existingSchedule: widget.schedule,
        legacyClass: widget.legacyClass,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'No se pudo guardar. Revisá la conexión.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDelete(context);
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    await deleteAgendaEntry(
      context,
      schedule: widget.schedule,
      legacyClass: widget.legacyClass,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final d = await pickEventDate(context, _date);
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool start) async {
    final t = await pickEventTime(
      context,
      isStart: start,
      currentStart: _start,
      currentEnd: _end,
    );
    if (t == null) return;
    setState(() {
      if (start) {
        _start = t;
      } else {
        _end = t;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: calBox(calField, r: 3, bw: 0),
              ),
            ),
            const SizedBox(height: 14),
            EventInputField(
              controller: _title,
              icon: Icons.title,
              hint: 'Título',
              autofocus: !_editing,
            ),
            const SizedBox(height: 10),
            EventRecurrencePicker(
              kind: _kind,
              weekdays: _weekdays,
              everyN: _everyN,
              date: _date,
              onKindChanged: (k) => setState(() => _kind = k),
              onWeekdaysChanged: (w) => setState(() => _weekdays = w),
              onEveryNChanged: (n) => setState(() => _everyN = n),
              onDatePick: _pickDate,
            ),
            const SizedBox(height: 10),
            EventTimeRangeRow(
              start: _start,
              end: _end,
              onPickStart: () => _pickTime(true),
              onPickEnd: () => _pickTime(false),
            ),
            const SizedBox(height: 10),
            EventInputField(
              controller: _place,
              icon: Icons.place,
              hint: 'Lugar / nota',
            ),
            const SizedBox(height: 12),
            EventColorPicker(
              selectedColor: _color,
              onColorSelected: (c) => setState(() => _color = c),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.bangers(
                  color: const Color(0xFFFF5757),
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (_editing) ...[
                  EventActionButton(
                    icon: Icons.delete,
                    bg: const Color(0xFFFF5757),
                    fg: calWhite,
                    onTap: _saving ? null : _delete,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: EventActionButton(
                    icon: Icons.check,
                    bg: calCyan,
                    fg: calInk,
                    onTap: _saving ? null : _save,
                    busy: _saving,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
