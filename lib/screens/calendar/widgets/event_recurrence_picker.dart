import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/recurrence.dart';
import '../../../widgets/tap_tile.dart';
import 'event_sheet_utils.dart';

/// Selector interactivo de periodicidad y opciones detalladas para eventos de calendario.
class EventRecurrencePicker extends StatelessWidget {
  final RecurrenceKind kind;
  final Set<int> weekdays;
  final int everyN;
  final DateTime date;
  final ValueChanged<RecurrenceKind> onKindChanged;
  final ValueChanged<Set<int>> onWeekdaysChanged;
  final ValueChanged<int> onEveryNChanged;
  final VoidCallback onDatePick;

  const EventRecurrencePicker({
    super.key,
    required this.kind,
    required this.weekdays,
    required this.everyN,
    required this.date,
    required this.onKindChanged,
    required this.onWeekdaysChanged,
    required this.onEveryNChanged,
    required this.onDatePick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRepeatRow(),
        const SizedBox(height: 10),
        _buildRepeatDetail(),
      ],
    );
  }

  /// UNA fila de 5 iconos: una vez · semana · cada N días · mes · año.
  Widget _buildRepeatRow() {
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
                    onKindChanged(o.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 46,
                    decoration: calBox(kind == o.$1 ? calCyan : calField),
                    child: Icon(o.$2,
                        color: kind == o.$1 ? calInk : calCyan, size: 24),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Lo que cambia según la repetición elegida.
  Widget _buildRepeatDetail() {
    final dateText = '${date.day}/${date.month}/${date.year}';
    switch (kind) {
      case RecurrenceKind.weekly:
        const names = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];
        return Row(
          children: [
            for (var d = 1; d <= 7; d++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TapTile(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final next = Set<int>.from(weekdays);
                      if (next.contains(d)) {
                        next.remove(d);
                      } else {
                        next.add(d);
                      }
                      onWeekdaysChanged(next);
                    },
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: calBox(
                          weekdays.contains(d) ? calCyan : calField,
                          r: 10),
                      child: Text(
                        names[d - 1],
                        style: GoogleFonts.bangers(
                          color: weekdays.contains(d) ? calInk : calWhite,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      case RecurrenceKind.everyNDays:
        return Row(
          children: [
            Expanded(child: _pill(Icons.event, dateText, onDatePick)),
            const SizedBox(width: 8),
            _stepBtn(
              Icons.remove,
              () => onEveryNChanged((everyN - 1).clamp(1, 365)),
            ),
            Container(
              width: 64,
              height: 48,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: calBox(calField),
              child: Text('$everyN',
                  style: GoogleFonts.bangers(color: calWhite, fontSize: 22)),
            ),
            _stepBtn(
              Icons.add,
              () => onEveryNChanged((everyN + 1).clamp(1, 365)),
            ),
          ],
        );
      case RecurrenceKind.none:
      case RecurrenceKind.monthly:
      case RecurrenceKind.yearly:
        return _pill(Icons.event, dateText, onDatePick);
    }
  }

  static Widget _pill(IconData icon, String text, VoidCallback onTap) {
    return TapTile(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: calBox(calField),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: calCyan, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bangers(color: calWhite, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _stepBtn(IconData icon, VoidCallback onTap) => TapTile(
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
}
