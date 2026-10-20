import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app_state.dart';
import '../../../providers/gallery_provider.dart';

class GaleriaPinCard extends StatelessWidget {
  final GalleryItem item;
  final int index;
  final ImageProvider? image;
  final double aspectRatio;
  final VoidCallback onTap;

  const GaleriaPinCard({
    super.key,
    required this.item,
    required this.index,
    required this.image,
    required this.aspectRatio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = item.userId == AppState.myId;
    final initial = isMine
        ? (AppState.identity?.substring(0, 1).toUpperCase() ?? 'F')
        : (AppState.identity?.toUpperCase().startsWith('F') == true ? 'R' : 'F');
    final tagColor = isMine ? const Color(0xFF00F0FF) : const Color(0xFFFF1493);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Bloque sólido sin bordes
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image(
                  image: image!,
                  fit: BoxFit.cover,
                )
              else
                const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white24,
                    size: 28,
                  ),
                ),

              // Badge de autor
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: tagColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.bangers(
                        color: const Color(0xFF121212),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Reacciones al pie si existen
              if (item.reactions.isNotEmpty)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 11,
                          color: Color(0xFFFF1493),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${item.reactions.values.fold<int>(0, (sum, list) => sum + list.length)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
