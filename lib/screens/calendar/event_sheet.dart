import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/class_schedule.dart';
import '../../models/recurrence.dart';
import '../../models/schedule.dart';
import '../../providers/class_schedule_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/tap_tile.dart';
import 'day_agenda.dart';

// Paleta del calendario (sección cian). Todo bloque: fondo == borde, sólido,
// redondeado, sin sombras ni transparencias (skill_visual).
const calBg = Color(0xFF0A1620);
const calPanel = Color(0xFF122433);
const calField = Color(0xFF1B3346);
const calCyan = Color(0xFF00D4FF);
const calInk = Color(0xFF062030);
const calWhite = Color(0xFFFFFFFF);
const calMuted = Color(0xFF7FA3B8);

const eventColors = <int>[
  0xFF00D4FF, 0xFFFF66C4, 0xFF39FF14, 0xFFFFDE59, 0xFFFF6B00, 0xFF9D00FF,
];

/// Color por defecto según quién crea el evento (F cian / R rosa).
int defaultColorFor(String? identity) =>
    identity == 'Rocio' ? 0xFFFF66C4 : 0xFF00D4FF;

BoxDecoration calBox(Color c, {double r = 14, double bw = 0}) => BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(r),
    );

/// Abre el formulario único de evento (crear o editar).
/// - [schedule]: edita un evento (único o repetido) de `schedules`.
/// - [legacyClass]: edita una clase vieja; al guardar se convierte en un
///   evento repetido semanal y se borran las filas viejas del grupo.
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
    _start = _parse(s?.startTime ?? c?.startTime);
    _end = _parse(s?.endTime ?? c?.endTime);
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

  static TimeOfDay? _parse(String? hhmm) {
    final p = (hhmm ?? '').split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String _fmt(TimeOfDay? t) => t == null
      ? ''
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
    final schedules = context.read<ScheduleProvider>();
    final classes = context.read<ClassScheduleProvider>();
    final rule = _rule;
    final now = DateTime.now();
    final base = Schedule(
      id: widget.schedule?.id,
      cloudId: widget.schedule?.cloudId,
      title: title,
      date: DateTime(_date.year, _date.month, _date.day),
      startTime: _fmt(_start),
      endTime: _fmt(_end),
      location: _place.text.trim(),
      type: 'Evento',
      color: _color,
      userId: widget.schedule?.userId ??
          widget.legacyClass?.userId ??
          AppState.identity ??
          '',
      recurrence: rule.encode(),
      createdAt: widget.schedule?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      if (widget.schedule != null) {
        await schedules.updateSchedule(base);
      } else {
        await schedules.addSchedule(base);
        // Clase vieja editada: ya vive como repetido en `schedules`; se
        // borran sus filas de `class_schedules` (todas las del grupo).
        final c = widget.legacyClass;
        if (c != null) {
          for (final x in DayAgenda.legacyGroup(classes.schedules, c)) {
            if (x.id != null) await classes.deleteSchedule(x.id!);
          }
        }
      }
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
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ??
          (start ? const TimeOfDay(hour: 9, minute: 0) : _start ?? const TimeOfDay(hour: 10, minute: 0)),
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
            _input(_title, Icons.title, 'Título', autofocus: !_editing),
            const SizedBox(height: 10),
            _repeatRow(),
            const SizedBox(height: 10),
            _repeatDetail(),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _pill(Icons.schedule, _fmt(_start).isEmpty ? '--:--' : _fmt(_start), () => _pickTime(true))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, color: calMuted, size: 18),
              ),
              Expanded(child: _pill(Icons.schedule, _fmt(_end).isEmpty ? '--:--' : _fmt(_end), () => _pickTime(false))),
            ]),
            const SizedBox(height: 10),
            _input(_place, Icons.place, 'Lugar / nota'),
            const SizedBox(height: 12),
            _colorRow(),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: const Color(0xFFFF5757), fontSize: 15)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              if (_editing) ...[
                _actionBtn(Icons.delete, const Color(0xFFFF5757), calWhite, _saving ? null : _delete),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _actionBtn(
                  Icons.check,
                  calCyan,
                  calInk,
                  _saving ? null : _save,
                  busy: _saving,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, IconData icon, String hint,
      {bool autofocus = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: calBox(calField),
      child: Row(children: [
        Icon(icon, color: calCyan, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: c,
            autofocus: autofocus,
            style: GoogleFonts.bangers(color: calWhite, fontSize: 18, letterSpacing: 0.5),
            cursorColor: calCyan,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.bangers(color: calMuted, fontSize: 18),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _pill(IconData icon, String text, VoidCallback onTap) {
    return TapTile(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: calBox(calField),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: calCyan, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bangers(color: calWhite, fontSize: 18)),
          ),
        ]),
      ),
    );
  }

  /// UNA fila de 5 iconos: una vez · semana · cada N días · mes · año.
  Widget _repeatRow() {
    const opts = <(RecurrenceKind, IconData, String)>[
      (RecurrenceKind.none, Icons.looks_one, 'Una vez'),
      (RecurrenceKind.weekly, Icons.view_week, 'Días de la semana'),
      (RecurrenceKind.everyNDays, Icons.autorenew, 'Cada N días'),
      (RecurrenceKind.monthly, Icons.calendar_view_month, 'Todos los meses'),
      (RecurrenceKind.yearly, Icons.cake, 'Todos los años'),
    ];
    return Row(
      children: [
        for (final o in opts)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Tooltip(
                message: o.$3,
                child: TapTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _kind = o.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 46,
                    decoration: calBox(_kind == o.$1 ? calCyan : calField),
                    child: Icon(o.$2,
                        color: _kind == o.$1 ? calInk : calCyan, size: 24),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Lo que cambia según la repetición elegida (solo UN control a la vez).
  Widget _repeatDetail() {
    final dateText = '${_date.day}/${_date.month}/${_date.year}';
    switch (_kind) {
      case RecurrenceKind.weekly:
        const names = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];
        return Row(children: [
          for (var d = 1; d <= 7; d++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: TapTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _weekdays.contains(d)
                        ? _weekdays.remove(d)
                        : _weekdays.add(d));
                  },
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: calBox(_weekdays.contains(d) ? calCyan : calField, r: 10),
                    child: Text(names[d - 1],
                        style: GoogleFonts.bangers(
                            color: _weekdays.contains(d) ? calInk : calWhite,
                            fontSize: 16)),
                  ),
                ),
              ),
            ),
        ]);
      case RecurrenceKind.everyNDays:
        return Row(children: [
          Expanded(child: _pill(Icons.event, dateText, _pickDate)),
          const SizedBox(width: 8),
          _stepBtn(Icons.remove, () => setState(() => _everyN = (_everyN - 1).clamp(1, 365))),
          Container(
            width: 64,
            height: 48,
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: calBox(calField),
            child: Text('$_everyN', style: GoogleFonts.bangers(color: calWhite, fontSize: 22)),
          ),
          _stepBtn(Icons.add, () => setState(() => _everyN = (_everyN + 1).clamp(1, 365))),
        ]);
      case RecurrenceKind.none:
      case RecurrenceKind.monthly:
      case RecurrenceKind.yearly:
        return _pill(Icons.event, dateText, _pickDate);
    }
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => TapTile(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 44,
          height: 48,
          decoration: calBox(calField),
          child: Icon(icon, color: calCyan, size: 22),
        ),
      );

  Widget _colorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final c in eventColors)
          TapTile(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _color = c);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: _color == c ? 44 : 36,
              height: _color == c ? 44 : 36,
              decoration: calBox(Color(c), r: 12),
              child: _color == c
                  ? const Icon(Icons.check, color: calInk, size: 22)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, Color bg, Color fg, VoidCallback? onTap,
      {bool busy = false}) {
    return TapTile(
      onTap: onTap ?? () {},
      child: Container(
        height: 54,
        width: 64,
        decoration: calBox(bg, r: 16),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: calInk, strokeWidth: 3))
              : Icon(icon, color: fg, size: 28),
        ),
      ),
    );
  }
}

/// Confirmación de borrado (compartida con la agenda).
Future<bool> confirmDelete(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: calPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Text('¿Borrar? Se borra para los dos.',
          style: GoogleFonts.bangers(color: calWhite, fontSize: 20)),
      actions: [
        IconButton(
          onPressed: () => Navigator.pop(ctx, false),
          icon: const Icon(Icons.close, color: calMuted, size: 28),
        ),
        IconButton(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.delete, color: Color(0xFFFF5757), size: 28),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Borra un renglón de la agenda (evento o grupo de clase vieja).
Future<void> deleteAgendaEntry(
  BuildContext context, {
  Schedule? schedule,
  ClassSchedule? legacyClass,
}) async {
  HapticFeedback.heavyImpact();
  if (schedule?.id != null) {
    await context.read<ScheduleProvider>().deleteSchedule(schedule!.id!);
  } else if (legacyClass != null) {
    final classes = context.read<ClassScheduleProvider>();
    for (final x in DayAgenda.legacyGroup(classes.schedules, legacyClass)) {
      if (x.id != null) await classes.deleteSchedule(x.id!);
    }
  }
}
