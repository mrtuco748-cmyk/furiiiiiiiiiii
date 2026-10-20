import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/schedule.dart';
import '../../../widgets/tap_tile.dart';

const _c = Color(0xFF00D4FF);
const _near = Color(0xFF1A1A1A);
const _cDeep = Color(0xFF003344);
const _cBright = Color(0xFF0088AA);

/// Barra superior de navegación por fechas día a día.
class DailyDateNav extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<int> onShiftDay;
  final VoidCallback onPickDate;

  const DailyDateNav({
    super.key,
    required this.selectedDate,
    required this.onShiftDay,
    required this.onPickDate,
  });

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = _sameDay(selectedDate, DateTime.now());

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _cDeep,
          border: Border.all(color: _cDeep, width: 3),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF000000),
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            TapTile(
              onTap: () => onShiftDay(-1),
              child: const Icon(Icons.chevron_left,
                  color: Color(0xFF00D4FF), size: 24),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onPickDate,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEEE d MMM', 'es').format(selectedDate),
                      style: GoogleFonts.bangers(
                        color: today ? _c : Colors.white,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (today)
                      Text(
                        'HOY',
                        style: GoogleFonts.bangers(
                            color: _cBright, fontSize: 9),
                      ),
                  ],
                ),
              ),
            ),
            TapTile(
              onTap: () => onShiftDay(1),
              child: const Icon(Icons.chevron_right,
                  color: Color(0xFF00D4FF), size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo brutalista de confirmación para eliminar un evento.
class DailyDeleteDialog {
  static Future<bool?> show(BuildContext context, Schedule s) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _near,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.red, width: 4),
        ),
        title: const Icon(Icons.delete_forever, color: Colors.red, size: 40),
        content: Text(
          s.title,
          style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TapTile(
            onTap: () => Navigator.pop(ctx, false),
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
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    )
                  ],
                ),
                child:
                    const Icon(Icons.close, color: Color(0xFF00D4FF), size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TapTile(
            onTap: () => Navigator.pop(ctx, true),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  border: Border.all(color: Colors.red, width: 3),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF000000),
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    )
                  ],
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF0D0D0D), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
