import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/class_schedule.dart';
import '../../../models/event_type.dart';
import '../../../models/schedule.dart';

const _dark = Color(0xFF0D0D0D);
const _near = Color(0xFF1A1A1A);
const _cBright = Color(0xFF0088AA);

/// Tarjeta para una clase semanal en la vista diaria.
class DailyClassCard extends StatelessWidget {
  final ClassSchedule classSchedule;
  final VoidCallback onTap;

  const DailyClassCard({
    super.key,
    required this.classSchedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _near,
              border: Border.all(color: _near, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xFF000000),
                    offset: Offset(4, 4),
                    blurRadius: 0)
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Color(0xFF00D4FF), size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classSchedule.title,
                        style: GoogleFonts.bangers(
                            color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        classSchedule.endTime.isNotEmpty
                            ? '${classSchedule.startTime} - ${classSchedule.endTime}${classSchedule.professor.isNotEmpty ? ' · ${classSchedule.professor}' : ''}'
                            : '${classSchedule.startTime}${classSchedule.professor.isNotEmpty ? ' · ${classSchedule.professor}' : ''}',
                        style: GoogleFonts.bangers(
                            color: _cBright, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta para un evento fechado en la vista diaria.
class DailyEventCard extends StatelessWidget {
  final Schedule schedule;
  final EventType? eventType;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DailyEventCard({
    super.key,
    required this.schedule,
    required this.eventType,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        eventType != null ? Color(eventType!.color) : Color(schedule.color);
    final icon = eventType?.iconData ?? Icons.event;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _near,
              border: Border.all(color: _near, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xFF000000),
                    offset: Offset(4, 4),
                    blurRadius: 0)
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: _dark, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: GoogleFonts.bangers(
                            color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${schedule.startTime} - ${schedule.endTime}${schedule.location.isNotEmpty ? ' · ${schedule.location}' : ''}',
                        style:
                            GoogleFonts.bangers(color: color, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, color: color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
