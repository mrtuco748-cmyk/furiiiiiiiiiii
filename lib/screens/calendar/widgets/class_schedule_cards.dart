import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/class_schedule.dart';
import '../../../widgets/tap_tile.dart';

const Color _c = Color(0xFF00D4FF);
const Color _near = Color(0xFF1A1A1A);
const Color _cBright = Color(0xFF0088AA);
const Color _white70 = Color(0xB3FFFFFF);

class ClassScheduleCards extends StatelessWidget {
  final double width;
  final double height;
  final List<ClassSchedule> schedules;
  final Color Function(int? typeId) typeColor;
  final VoidCallback onOpenAdd;
  final void Function(ClassSchedule s) onOpenEdit;
  final void Function(ClassSchedule s) onDelete;

  const ClassScheduleCards({
    super.key,
    required this.width,
    required this.height,
    required this.schedules,
    required this.typeColor,
    required this.onOpenAdd,
    required this.onOpenEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final top = height * 0.195;

    if (schedules.isEmpty) {
      return Positioned(
        left: width * 0.03,
        top: top,
        width: width * 0.94,
        height: height * 0.74,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _near,
              border: Border.all(color: _near, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, color: _cBright, size: 48),
                const SizedBox(height: 12),
                TapTile(
                  onTap: onOpenAdd,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _c,
                        border: Border.all(color: _c, width: 4),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF0D0D0D), size: 30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: width * 0.03,
      top: top,
      width: width * 0.94,
      height: height * 0.74,
      child: ListView(
        padding: EdgeInsets.zero,
        children: schedules.asMap().entries.map((entry) {
          final s = entry.value;
          final color = typeColor(s.classTypeId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onLongPress: () => onDelete(s),
              child: TapTile(
                onTap: () => onOpenEdit(s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _near,
                      border: Border.all(color: _near, width: 4),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0),
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 84,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.startTime, style: GoogleFonts.bangers(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
                            Text(s.endTime, style: GoogleFonts.bangers(color: _white70, fontSize: 11)),
                          ]),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.title, style: GoogleFonts.bangers(color: color, fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (s.professor.isNotEmpty)
                                Padding(padding: const EdgeInsets.only(top: 3), child: Text(s.professor, style: GoogleFonts.bangers(color: _white70, fontSize: 11))),
                            ]),
                          ),
                          Icon(Icons.school, color: color.withValues(alpha: 0.5), size: 26),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
