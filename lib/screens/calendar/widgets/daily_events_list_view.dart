import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/class_schedule.dart';
import '../../../models/event_type.dart';
import '../../../models/schedule.dart';
import '../../../widgets/tap_tile.dart';
import 'daily_event_cards.dart';

const _c = Color(0xFF00D4FF);
const _near = Color(0xFF1A1A1A);
const _cBright = Color(0xFF0088AA);

class DailyEventsListView extends StatelessWidget {
  final List<Schedule> events;
  final List<ClassSchedule> classes;
  final EventType? Function(String name) eventTypeResolver;
  final VoidCallback onOpenForm;
  final VoidCallback onOpenClasses;
  final void Function(Schedule s) onEditEvent;
  final void Function(Schedule s) onDeleteEvent;

  const DailyEventsListView({
    super.key,
    required this.events,
    required this.classes,
    required this.eventTypeResolver,
    required this.onOpenForm,
    required this.onOpenClasses,
    required this.onEditEvent,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty && classes.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _near,
            border: Border.all(color: _near, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF000000),
                offset: Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, color: _cBright, size: 48),
              const SizedBox(height: 10),
              Text(
                'Sin eventos este dia',
                style: GoogleFonts.bangers(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              TapTile(
                onTap: onOpenForm,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _c,
                      border: Border.all(color: _c, width: 4),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF000000),
                          offset: Offset(5, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Color(0xFF0D0D0D),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        if (classes.isNotEmpty) ...[
          Text('CLASES', style: GoogleFonts.bangers(color: _c, fontSize: 13)),
          const SizedBox(height: 4),
          ...classes.map(
            (cs) => DailyClassCard(
              classSchedule: cs,
              onTap: onOpenClasses,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (events.isNotEmpty) ...[
          Text('EVENTOS', style: GoogleFonts.bangers(color: _c, fontSize: 13)),
          const SizedBox(height: 4),
          ...events.map(
            (e) => DailyEventCard(
              schedule: e,
              eventType: eventTypeResolver(e.type),
              onTap: () => onEditEvent(e),
              onLongPress: () => onDeleteEvent(e),
            ),
          ),
        ],
      ],
    );
  }
}

class DailyLoadingView extends StatelessWidget {
  const DailyLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(color: _c, strokeWidth: 4),
      ),
    );
  }
}

class DailyErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const DailyErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF330000),
          border: Border.all(color: Colors.red, width: 5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF000000),
              offset: Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, color: Colors.red, size: 44),
            const SizedBox(height: 14),
            TapTile(
              onTap: () {
                onRetry();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _near,
                    border: Border.all(color: _near, width: 3),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF000000),
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.refresh, color: Colors.red, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

