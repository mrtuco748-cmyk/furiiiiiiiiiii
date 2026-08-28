import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';

/// Chip de reacción (emoji o "+" para custom) en la barra de long-press.
class ChatReactChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ChatReactChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ChatStyle.primary;
    final bg = selected ? c : ChatStyle.bg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TapTile(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: bg, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: GoogleFonts.bangers(
              fontSize: label == '+' ? 22 : 18,
              fontWeight: FontWeight.w900,
              color: selected ? ChatStyle.bg : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}