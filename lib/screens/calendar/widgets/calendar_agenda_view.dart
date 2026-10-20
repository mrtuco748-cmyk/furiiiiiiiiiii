import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/class_schedule.dart';
import '../../../models/schedule.dart';
import '../../../widgets/tap_tile.dart';
import '../day_agenda.dart';
import '../event_sheet.dart';

/// Vista de agenda del día seleccionado en el calendario unificado.
class CalendarAgendaView extends StatelessWidget {
  final DateTime selectedDay;
  final List<Schedule> schedules;
  final List<ClassSchedule> classes;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onAdd;

  const CalendarAgendaView({
    super.key,
    required this.selectedDay,
    required this.schedules,
    required this.classes,
    this.error,
    required this.onRetry,
    required this.onAdd,
  });

  static const _dayNames = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final items =
        DayAgenda.forDay(schedules: schedules, classes: classes, day: selectedDay);
    final title =
        '${_dayNames[selectedDay.weekday - 1]} ${selectedDay.day}/${selectedDay.month}';

    Widget body;
    if (error != null && items.isEmpty) {
      body = Center(
        child: TapTile(
          onTap: onRetry,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, color: Color(0xFFFF5757), size: 48),
            const SizedBox(height: 6),
            Text(error!,
                style: GoogleFonts.bangers(color: calWhite, fontSize: 18)),
            const Icon(Icons.refresh, color: calCyan, size: 30),
          ]),
        ),
      );
    } else if (items.isEmpty) {
      body = Center(
        child: TapTile(
          onTap: onAdd,
          child: const Icon(Icons.event_available, color: calField, size: 72),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _buildAgendaTile(context, items[i]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(title,
            style: GoogleFonts.bangers(color: calCyan, fontSize: 22)),
      ),
      Expanded(child: body),
    ]);
  }

  Widget _buildAgendaTile(BuildContext context, AgendaItem it) {
    final c = Color(it.color);
    final time = it.startTime.isEmpty
        ? ''
        : (it.endTime.isEmpty ? it.startTime : '${it.startTime}-${it.endTime}');
    final initial = it.userId.isEmpty ? '' : it.userId[0].toUpperCase();
    return TapTile(
      onTap: () => showEventSheet(
        context,
        day: selectedDay,
        schedule: it.schedule,
        legacyClass: it.legacyClass,
      ),
      child: GestureDetector(
        onLongPress: () async {
          if (await confirmDelete(context) && context.mounted) {
            await deleteAgendaEntry(
              context,
              schedule: it.schedule,
              legacyClass: it.legacyClass,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: calBox(calPanel, r: 16),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: calBox(c, r: 12),
              child: Text(initial,
                  style: GoogleFonts.bangers(color: calInk, fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bangers(color: calWhite, fontSize: 19)),
                  if (time.isNotEmpty || it.location.isNotEmpty)
                    Text(
                      [time, it.location].where((e) => e.isNotEmpty).join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bangers(color: calMuted, fontSize: 15),
                    ),
                ],
              ),
            ),
            if (it.recurring)
              const Icon(Icons.autorenew, color: calCyan, size: 22),
          ]),
        ),
      ),
    );
  }
}
