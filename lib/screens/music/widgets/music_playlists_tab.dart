import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/music_playlist.dart';
import '../../../providers/music_player_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../modals/music_playlist_sheets.dart';

class MusicPlaylistsTab extends StatelessWidget {
  final MusicPlayerProvider pv;
  final ValueChanged<MusicPlaylist> onSelectPlaylist;

  const MusicPlaylistsTab({
    super.key,
    required this.pv,
    required this.onSelectPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'PLAYLISTS DE LA PAREJA',
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
                ),
              ),
              TapTile(
                onTap: () => showCreatePlaylistDialog(context, pv),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Color(0xFF111111), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'NUEVA',
                        style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: pv.playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.queue_music, color: Colors.white24, size: 56),
                      const SizedBox(height: 14),
                      Text(
                        'No hay playlists creadas todavía',
                        style: GoogleFonts.bangers(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea playlists compartidas para viajes, entrenamientos o momentos juntos',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TapTile(
                        onTap: () => showCreatePlaylistDialog(context, pv),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+ CREAR PRIMERA PLAYLIST',
                            style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: pv.playlists.length,
                  itemBuilder: (ctx, i) {
                    final playlist = pv.playlists[i];
                    final playlistTracks = pv.getTracksForPlaylist(playlist);
                    final isFacu = playlist.createdBy.toLowerCase().contains('facu');
                    final authorColor = isFacu ? const Color(0xFF00D4FF) : const Color(0xFFFF1493);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.playlist_play, color: Color(0xFF00D4FF), size: 28),
                            ),
                            title: Text(
                              playlist.title,
                              style: GoogleFonts.bangers(color: Colors.white, fontSize: 17),
                            ),
                            subtitle: Text(
                              playlist.description.isNotEmpty
                                    ? playlist.description
                                    : 'Creada por ${playlist.createdBy}',
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TapTile(
                                  onTap: playlistTracks.isEmpty
                                      ? () {}
                                      : () {
                                          HapticFeedback.heavyImpact();
                                          pv.playPlaylist(playlist);
                                        },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: playlistTracks.isNotEmpty
                                          ? const Color(0xFF39FF14)
                                          : const Color(0xFF222222),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: playlistTracks.isNotEmpty
                                          ? const Color(0xFF0A0A0A)
                                          : Colors.white38,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TapTile(
                                  onTap: () => showPlaylistMenu(context, playlist, pv),
                                  child: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${playlistTracks.length} canciones',
                                    style: GoogleFonts.bangers(color: Colors.white70, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    playlist.createdBy,
                                    style: GoogleFonts.bangers(color: authorColor, fontSize: 12),
                                  ),
                                ),
                                const Spacer(),
                                TapTile(
                                  onTap: () => onSelectPlaylist(playlist),
                                  child: Text(
                                    'VER TEMAS →',
                                    style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
