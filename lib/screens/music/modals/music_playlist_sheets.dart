import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/music_playlist.dart';
import '../../../models/music_track.dart';
import '../../../providers/music_player_provider.dart';
import '../../../widgets/tap_tile.dart';

void showAddToPlaylistSheet(BuildContext context, MusicTrack track, MusicPlayerProvider pv) {
  final trackIdentifier = track.cloudId ?? track.id ?? 0;

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.playlist_add, color: Color(0xFF00D4FF), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'GUARDAR EN PLAYLIST',
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
                    ),
                    const Spacer(),
                    TapTile(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (pv.playlists.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No hay playlists creadas aún',
                        style: GoogleFonts.bangers(color: Colors.white38, fontSize: 15),
                      ),
                    ),
                  )
                else
                  ...pv.playlists.map((pl) {
                    final inPlaylist = pl.trackIds.contains(trackIdentifier);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CheckboxListTile(
                        value: inPlaylist,
                        activeColor: const Color(0xFF00D4FF),
                        checkColor: const Color(0xFF0A0A0A),
                        title: Text(
                          pl.title,
                          style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${pl.trackIds.length} temas',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        onChanged: (_) {
                          pv.toggleTrackInPlaylist(pl, trackIdentifier);
                          setSheetState(() {});
                        },
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                TapTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    showCreatePlaylistDialog(context, pv);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '+ CREAR NUEVA PLAYLIST',
                        style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void showCreatePlaylistDialog(BuildContext context, MusicPlayerProvider pv) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'NUEVA PLAYLIST',
          style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nombre de la playlist (ej: Viajes)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Descripción (opcional)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.bangers(color: Colors.white54, fontSize: 14),
            ),
          ),
          TapTile(
            onTap: () {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                pv.createPlaylist(title, descCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CREAR',
                style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14),
              ),
            ),
          ),
        ],
      );
    },
  );
}

void showPlaylistMenu(BuildContext context, MusicPlaylist playlist, MusicPlayerProvider pv) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              playlist.title,
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TapTile(
              onTap: () {
                Navigator.pop(ctx);
                pv.playPlaylist(playlist);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow, color: Color(0xFF39FF14), size: 20),
                    const SizedBox(width: 12),
                    Text('REPRODUCIR PLAYLIST', style: GoogleFonts.bangers(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TapTile(
              onTap: () {
                Navigator.pop(ctx);
                pv.deletePlaylist(playlist);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0A0A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Color(0xFFFF5757), size: 20),
                    const SizedBox(width: 12),
                    Text('ELIMINAR PLAYLIST', style: GoogleFonts.bangers(color: Color(0xFFFF5757), fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
