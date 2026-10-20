import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/schedule.dart';
import '../../../providers/schedule_provider.dart';

const _c = Color(0xFF00D4FF);
const _dark = Color(0xFF1A1A1A);
const _cDeep = Color(0xFF003344);
const _white = Color(0xFFFFFFFF);

/// Bloque inferior de próximos eventos para el calendario principal.
class CalendarUpcomingEvents extends StatelessWidget {
  final double width;
  final double height;
  final ValueChanged<Schedule> onEdit;
  final ValueChanged<Schedule> onDelete;

  const CalendarUpcomingEvents({
    super.key,
    required this.width,
    required this.height,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final upcoming = context
        .watch<ScheduleProvider>()
        .schedules
        .where((s) =>
            s.type != 'Clase' &&
            s.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Positioned(
      left: width * 0.03,
      top: height * 0.54,
      width: width * 0.94,
      height: height * 0.40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(' Proximos',
              style: GoogleFonts.bangers(color: _c, fontSize: 14)),
          const SizedBox(height: 4),
          Expanded(
            child: upcoming.isEmpty
                ? Center(
                    child: Text(
                      'Sin eventos',
                      style: GoogleFonts.bangers(
                        color: _white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: upcoming.length,
                    itemBuilder: (context, i) {
                      final e = upcoming[i];
                      final dateStr = '${e.date.day}/${e.date.month}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: GestureDetector(
                          onTap: () => onEdit(e),
                          onLongPress: () => onDelete(e),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _cDeep,
                              border: Border.all(color: _cDeep, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Color(e.color),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Color(e.color), width: 2),
                                  ),
                                  child: Text(
                                    dateStr,
                                    style: GoogleFonts.bangers(
                                      color: _dark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.title,
                                        style: GoogleFonts.bangers(
                                          color: _white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${e.startTime}-${e.endTime} ${e.location}',
                                        style: GoogleFonts.bangers(
                                          color:
                                              _white.withValues(alpha: 0.4),
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: _white.withValues(alpha: 0.3),
                                    size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
