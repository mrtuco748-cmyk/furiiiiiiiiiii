import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/music_track.dart';
import '../../../providers/music_player_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../helpers/music_ui_helpers.dart';
import '../modals/music_comments_sheet.dart';
import '../modals/music_playlist_sheets.dart';
import '../modals/music_track_options_sheet.dart';

class MusicTrackCard extends StatelessWidget {
  final MusicTrack track;
  final MusicPlayerProvider pv;

  const MusicTrackCard({
    super.key,
    required this.track,
    required this.pv,
  });

  @override
  Widget build(BuildContext context) {
    final isPlayingThis = pv.currentTrack?.id == track.id;
    final isFacu = track.addedBy.toLowerCase().contains('facu');
    final authorColor = isFacu ? const Color(0xFF00D4FF) : const Color(0xFFFF1493);
    final authorInitial = isFacu ? 'F' : 'R';
    final trackId = track.id ?? track.cloudId ?? 0;
    final isDownloadingLocal = pv.localDownloadingIds.contains(trackId);
    final hasLocal = track.localPath.isNotEmpty && File(track.localPath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isPlayingThis ? const Color(0xFF261238) : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
            onTap: () {
              HapticFeedback.selectionClick();
              pv.play(track);
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      track.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => fallbackMusicCover(),
                    )
                  : fallbackMusicCover(),
            ),
            title: Text(
              track.title,
              style: GoogleFonts.bangers(
                color: isPlayingThis ? const Color(0xFF39FF14) : Colors.white,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    track.artist,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: authorColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    authorInitial,
                    style: GoogleFonts.bangers(
                      color: const Color(0xFF111111),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  track.durationFormatted,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            trailing: TapTile(
              onTap: () => pv.toggleFavorite(track),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  track.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: track.isFavorite ? const Color(0xFFFF5757) : Colors.white38,
                  size: 22,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                TapTile(
                  onTap: isDownloadingLocal
                      ? () {}
                      : () async {
                          if (hasLocal) {
                            showOfflineSheet(context, track, pv);
                          } else {
                            HapticFeedback.selectionClick();
                            final ok = await pv.downloadTrackLocally(track);
                            if (context.mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0D6B15),
                                  content: Text(
                                    'Descargada para escuchar sin conexión',
                                    style: GoogleFonts.bangers(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasLocal ? const Color(0xFF1A2B1C) : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (isDownloadingLocal)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF39FF14),
                            ),
                          )
                        else
                          Icon(
                            hasLocal ? Icons.check_circle : Icons.download,
                            color: hasLocal ? const Color(0xFF39FF14) : Colors.white60,
                            size: 15,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          hasLocal ? 'OFFLINE' : 'DESCARGAR',
                          style: GoogleFonts.bangers(
                            color: hasLocal ? const Color(0xFF39FF14) : Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TapTile(
                  onTap: () => showCommentsSheet(context, track, pv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Color(0xFF00D4FF), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'COMENTAR',
                          style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TapTile(
                  onTap: () => showAddToPlaylistSheet(context, track, pv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.playlist_add, color: Color(0xFFE040FB), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '+ PLAYLIST',
                          style: GoogleFonts.bangers(color: const Color(0xFFE040FB), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                TapTile(
                  onTap: () => showTrackOptions(context, track, pv),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(Icons.more_horiz, color: Colors.white38, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
