import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/schedule.dart';

const _c = Color(0xFF00D4FF);
const _dark = Color(0xFF1A1A1A);
const _white = Color(0xFFFFFFFF);

/// Celda individual de día en la grilla mensual del calendario.
class CalendarDayCell extends StatelessWidget {
  final int day;
  final List<Schedule>? events;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.events,
    this.isToday = false,
    this.isSelected = false,
    this.isOutside = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (day == 0) return const SizedBox.shrink();
    final hasEvents = events != null && events!.isNotEmpty;

    final Color cellBg;
    if (isOutside) {
      cellBg = const Color(0xFF0B1620);
    } else if (isSelected) {
      cellBg = _c;
    } else if (isToday) {
      cellBg = const Color(0xFF0E2A38);
    } else {
      cellBg = const Color(0xFF122433);
    }

    final Color textColor;
    if (isSelected) {
      textColor = _dark;
    } else if (isToday) {
      textColor = _c;
    } else if (isOutside) {
      textColor = _white.withValues(alpha: 0.25);
    } else {
      textColor = _white.withValues(alpha: 0.75);
    }

    return GestureDetector(
      onTap: () {
        if (!isOutside) {
          HapticFeedback.selectionClick();
          onTap?.call();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: _c, width: 2)
              : (isToday ? Border.all(color: _c, width: 1.6) : null),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: GoogleFonts.bangers(color: textColor, fontSize: 13),
              ),
            ),
            if (hasEvents)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...events!
                        .where((e) => e.type == 'Clase')
                        .take(3)
                        .map(
                          (e) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: Color(e.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ...events!
                        .where((e) => e.type != 'Clase')
                        .take(3)
                        .map(
                          (e) => Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: Color(e.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
