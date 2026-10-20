import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/music_track.dart';
import '../../../providers/music_player_provider.dart';
import '../../../widgets/tap_tile.dart';
import 'music_comments_sheet.dart';
import 'music_playlist_sheets.dart';

void showOfflineSheet(BuildContext context, MusicTrack track, MusicPlayerProvider pv) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF39FF14), size: 22),
                const SizedBox(width: 10),
                Text(
                  'DISPONIBLE SIN CONEXIÓN',
                  style: GoogleFonts.bangers(color: const Color(0xFF39FF14), fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta canción está descargada en el almacenamiento del dispositivo para reproducirse sin consumir datos móviles.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TapTile(
              onTap: () {
                Navigator.pop(ctx);
                pv.removeLocalCopy(track);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF222222),
                    content: Text(
                      'Copia local eliminada. La canción sigue en la nube.',
                      style: GoogleFonts.bangers(color: Colors.white),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0A0A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'ELIMINAR COPIA LOCAL (LIBERAR ESPACIO)',
                    style: GoogleFonts.bangers(color: const Color(0xFFFF5757), fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showTrackOptions(BuildContext context, MusicTrack track, MusicPlayerProvider pv) {
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
              track.title,
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TapTile(
              onTap: () {
                Navigator.pop(ctx);
                showAddToPlaylistSheet(context, track, pv);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.playlist_add, color: Color(0xFF00D4FF), size: 20),
                    const SizedBox(width: 12),
                    Text('AGREGAR A PLAYLIST', style: GoogleFonts.bangers(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TapTile(
              onTap: () {
                Navigator.pop(ctx);
                showCommentsSheet(context, track, pv);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Color(0xFF00D4FF), size: 20),
                    const SizedBox(width: 12),
                    Text('VER COMENTARIOS Y NOTAS', style: GoogleFonts.bangers(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TapTile(
              onTap: () {
                Navigator.pop(ctx);
                pv.deleteTrack(track);
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
                    Text('ELIMINAR DE LA BIBLIOTECA', style: GoogleFonts.bangers(color: Color(0xFFFF5757), fontSize: 15)),
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
