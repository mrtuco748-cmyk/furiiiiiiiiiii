import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';
import 'event_sheet_utils.dart';

/// Campo de texto brutalista estilizado para EventSheet.
class EventInputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool autofocus;

  const EventInputField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: calBox(calField),
      child: Row(
        children: [
          Icon(icon, color: calCyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              style: GoogleFonts.bangers(
                color: calWhite,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
              cursorColor: calCyan,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.bangers(color: calMuted, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de rango horario (inicio -> fin) en una sola fila.
class EventTimeRangeRow extends StatelessWidget {
  final TimeOfDay? start;
  final TimeOfDay? end;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const EventTimeRangeRow({
    super.key,
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    final startFmt = formatTimeOfDay(start);
    final endFmt = formatTimeOfDay(end);

    return Row(
      children: [
        Expanded(
          child: EventPillButton(
            icon: Icons.schedule,
            text: startFmt.isEmpty ? '--:--' : startFmt,
            onTap: onPickStart,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, color: calMuted, size: 18),
        ),
        Expanded(
          child: EventPillButton(
            icon: Icons.schedule,
            text: endFmt.isEmpty ? '--:--' : endFmt,
            onTap: onPickEnd,
          ),
        ),
      ],
    );
  }
}

/// Botón píldora interactivo para selección de hora/fecha.
class EventPillButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const EventPillButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Fila selectora de color de evento.
class EventColorPicker extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  const EventColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final c in eventColors)
          TapTile(
            onTap: () {
              HapticFeedback.selectionClick();
              onColorSelected(c);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: selectedColor == c ? 44 : 36,
              height: selectedColor == c ? 44 : 36,
              decoration: calBox(Color(c), r: 12),
              child: selectedColor == c
                  ? const Icon(Icons.check, color: calInk, size: 22)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Botón de acción (guardar / borrar) para EventSheet.
class EventActionButton extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final bool busy;

  const EventActionButton({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: CircularProgressIndicator(
                    color: calInk,
                    strokeWidth: 3,
                  ),
                )
              : Icon(icon, color: fg, size: 28),
        ),
      ),
    );
  }
}
