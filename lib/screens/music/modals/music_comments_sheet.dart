import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../models/music_track.dart';
import '../../../providers/music_player_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../helpers/music_ui_helpers.dart';

void showCommentsSheet(BuildContext context, MusicTrack track, MusicPlayerProvider pv) {
  final trackId = track.cloudId ?? track.id ?? 0;
  pv.loadComments(trackId);
  final commentCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: track.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            track.thumbnailUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => fallbackMusicCover(width: 44, height: 44),
                          )
                        : fallbackMusicCover(width: 44, height: 44),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Comentarios de Facu y Rocío',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TapTile(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF222222), height: 1),
              const SizedBox(height: 10),
              Expanded(
                child: Consumer<MusicPlayerProvider>(
                  builder: (context, provider, _) {
                    final comments = provider.getCommentsForTrack(trackId);
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Aún no hay comentarios en este tema',
                              style: GoogleFonts.bangers(color: Colors.white38, fontSize: 14),
                            ),
                            const Text(
                              '¡Dejale una nota o dedicatoria a tu pareja!',
                              style: TextStyle(color: Colors.white24, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (c, idx) {
                        final com = comments[idx];
                        final isFacu = com.userId.toLowerCase().contains('facu');
                        final authorColor = isFacu ? const Color(0xFF00D4FF) : const Color(0xFFFF1493);
                        final currentId = AppState.identity ?? 'Facu';
                        final isOwn = com.userId.toLowerCase() == currentId.toLowerCase();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: authorColor,
                                child: Text(
                                  isFacu ? 'F' : 'R',
                                  style: GoogleFonts.bangers(
                                    color: const Color(0xFF111111),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      com.userId,
                                      style: GoogleFonts.bangers(color: authorColor, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      com.content,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwn)
                                TapTile(
                                  onTap: () => provider.deleteComment(com),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.delete_outline, color: Colors.white38, size: 16),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Escribí un comentario o dedicatoria...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TapTile(
                      onTap: () {
                        final text = commentCtrl.text.trim();
                        if (text.isNotEmpty) {
                          pv.addComment(trackId, text);
                          commentCtrl.clear();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.send, color: Color(0xFF111111), size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
