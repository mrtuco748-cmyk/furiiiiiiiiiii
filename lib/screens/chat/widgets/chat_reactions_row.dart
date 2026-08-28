import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';

/// Fila de reacciones (emojis con contador) que se muestra debajo de un burbuja.
class ChatReactionsRow extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final void Function(String key) onTap;
  const ChatReactionsRow({super.key, required this.reactions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ChatStyle.panel,
        border: Border.all(color: ChatStyle.panel, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in reactions.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: TapTile(
                onTap: () => onTap(e.key),
                child: Text(
                  e.value.length > 1 ? '${e.key}${e.value.length}' : e.key,
                  style: GoogleFonts.bangers(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}