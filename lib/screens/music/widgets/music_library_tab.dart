import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/music_playlist.dart';
import '../../../providers/music_player_provider.dart';
import '../../../widgets/tap_tile.dart';
import 'music_track_card.dart';

class MusicLibraryTab extends StatelessWidget {
  final MusicPlayerProvider pv;
  final MusicPlaylist? selectedPlaylistFilter;
  final VoidCallback onClearPlaylistFilter;
  final VoidCallback onSwitchToSearchTab;

  const MusicLibraryTab({
    super.key,
    required this.pv,
    required this.selectedPlaylistFilter,
    required this.onClearPlaylistFilter,
    required this.onSwitchToSearchTab,
  });

  @override
  Widget build(BuildContext context) {
    if (pv.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9D00FF)),
      );
    }

    final tracks = selectedPlaylistFilter != null
        ? pv.getTracksForPlaylist(selectedPlaylistFilter!)
        : pv.tracks;

    return Column(
      children: [
        if (selectedPlaylistFilter != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.playlist_play, color: Color(0xFF00D4FF), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PLAYLIST: ${selectedPlaylistFilter!.title.toUpperCase()}',
                    style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TapTile(
                  onTap: onClearPlaylistFilter,
                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),
        Expanded(
          child: tracks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  itemCount: tracks.length,
                  itemBuilder: (ctx, i) {
                    final track = tracks[i];
                    return MusicTrackCard(track: track, pv: pv);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_off, color: Colors.white24, size: 56),
          const SizedBox(height: 14),
          Text(
            selectedPlaylistFilter != null
                ? 'Esta playlist no tiene canciones todavía'
                : 'No hay canciones en la biblioteca',
            style: GoogleFonts.bangers(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'Busca temas en YouTube para agregarlos a la biblioteca',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TapTile(
            onTap: onSwitchToSearchTab,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0033),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'BUSCAR EN YOUTUBE',
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
