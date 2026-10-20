import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/gallery_provider.dart';

class GaleriaReactionsRow extends StatelessWidget {
  final GalleryProvider provider;
  final GalleryItem item;

  const GaleriaReactionsRow({
    super.key,
    required this.provider,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    const emojis = ['❤️', '🔥', '😍', '🥰', '✨'];

    return Row(
      children: emojis.map((e) {
        final active = item.reactions[e]?.isNotEmpty ?? false;
        final count = item.reactions[e]?.length ?? 0;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (item.id != null) {
                HapticFeedback.selectionClick();
                provider.toggleReaction(item.id!, e);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF1493)
                    : const Color(0xFF222222), // Bloque sólido sin bordes
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e, style: const TextStyle(fontSize: 16)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
