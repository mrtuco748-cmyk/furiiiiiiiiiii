import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app_state.dart';
import '../../../providers/gallery_provider.dart';

class GaleriaCommentsList extends StatelessWidget {
  final List<GalleryComment> comments;
  final GalleryProvider provider;

  const GaleriaCommentsList({
    super.key,
    required this.comments,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Sé el primero en comentar esta foto 💕',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = comments[i];
        final isMine = c.userId == AppState.myId;
        final initial = isMine
            ? (AppState.identity?.substring(0, 1).toUpperCase() ?? 'F')
            : (AppState.identity?.toUpperCase().startsWith('F') == true
                ? 'R'
                : 'F');
        final userColor = isMine ? const Color(0xFF00F0FF) : const Color(0xFFFF1493);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Bloque sólido sin bordes
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: userColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.bangers(
                      color: const Color(0xFF121212),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMine
                          ? 'Tú'
                          : (AppState.identity == 'Facu' ? 'Rocío' : 'Facu'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: userColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMine && c.id != null)
                GestureDetector(
                  onTap: () => provider.deleteComment(c.id!),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white38,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
