import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/class_schedule.dart';
import '../../../models/schedule.dart';
import '../../../providers/class_schedule_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../day_agenda.dart';

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
  0xFF00D4FF,
  0xFFFF66C4,
  0xFF39FF14,
  0xFFFFDE59,
  0xFFFF6B00,
  0xFF9D00FF,
];

/// Color por defecto según quién crea el evento (F cian / R rosa).
int defaultColorFor(String? identity) =>
    identity == 'Rocio' ? 0xFFFF66C4 : 0xFF00D4FF;

BoxDecoration calBox(Color c, {double r = 14, double bw = 0}) => BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(r),
    );

TimeOfDay? parseTimeOfDay(String? hhmm) {
  final p = (hhmm ?? '').split(':');
  if (p.length != 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

String formatTimeOfDay(TimeOfDay? t) => t == null
    ? ''
    : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

Future<DateTime?> pickEventDate(BuildContext context, DateTime current) =>
    showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

Future<TimeOfDay?> pickEventTime(
  BuildContext context, {
  required bool isStart,
  TimeOfDay? currentStart,
  TimeOfDay? currentEnd,
}) =>
    showTimePicker(
      context: context,
      initialTime: (isStart ? currentStart : currentEnd) ??
          (isStart
              ? const TimeOfDay(hour: 9, minute: 0)
              : currentStart ?? const TimeOfDay(hour: 10, minute: 0)),
    );

/// Guarda un evento nuevo o modificado y migra clases viejas si corresponde.
Future<void> saveAgendaEvent(
  BuildContext context, {
  required Schedule base,
  Schedule? existingSchedule,
  ClassSchedule? legacyClass,
}) async {
  final schedules = context.read<ScheduleProvider>();
  final classes = context.read<ClassScheduleProvider>();
  if (existingSchedule != null) {
    await schedules.updateSchedule(base);
  } else {
    await schedules.addSchedule(base);
    if (legacyClass != null) {
      for (final x in DayAgenda.legacyGroup(classes.schedules, legacyClass)) {
        if (x.id != null) await classes.deleteSchedule(x.id!);
      }
    }
  }
}

/// Confirmación de borrado (compartida con la agenda).
Future<bool> confirmDelete(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: calPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Text(
        '¿Borrar? Se borra para los dos.',
        style: GoogleFonts.bangers(color: calWhite, fontSize: 20),
      ),
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
