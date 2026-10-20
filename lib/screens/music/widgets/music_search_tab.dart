import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/music_player_provider.dart';
import '../../../services/music_download_service.dart';
import '../../../widgets/tap_tile.dart';
import '../helpers/music_ui_helpers.dart';

class MusicSearchTab extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool isSearching;
  final List<YouTubeSearchResult> searchResults;
  final VoidCallback onSearch;
  final MusicPlayerProvider pv;
  final VoidCallback onOpenDownloadQueue;

  const MusicSearchTab({
    super.key,
    required this.searchCtrl,
    required this.isSearching,
    required this.searchResults,
    required this.onSearch,
    required this.pv,
    required this.onOpenDownloadQueue,
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
                child: TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: 'Buscar canción o artista...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFF0033)),
                    filled: true,
                    fillColor: const Color(0xFF161616),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TapTile(
                onTap: onSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0033),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'BUSCAR',
                    style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isSearching)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF0033)),
            ),
          )
        else if (searchResults.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'Escribe algo para buscar en YouTube',
                style: GoogleFonts.bangers(color: Colors.white38, fontSize: 16),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: searchResults.length,
              itemBuilder: (ctx, i) {
                final item = searchResults[i];
                final isAlreadySaved = pv.tracks.any((t) => t.youtubeId == item.id);
                final isCurrentDownloading = pv.isDownloadingItem(item.id);
                final isQueued = pv.isQueuedItem(item.id);
                final queuePos = pv.getQueuePosition(item.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.thumbnailUrl.isNotEmpty
                            ? Image.network(
                                item.thumbnailUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => fallbackMusicCover(width: 56, height: 56),
                              )
                            : fallbackMusicCover(width: 56, height: 56),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.author} • ${item.durationFormatted}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TapTile(
                        onTap: () {
                          if (isAlreadySaved) {
                            return;
                          }
                          if (isCurrentDownloading) {
                            HapticFeedback.selectionClick();
                            onOpenDownloadQueue();
                            return;
                          }
                          if (isQueued) {
                            HapticFeedback.selectionClick();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF2E2710),
                                content: Text(
                                  '"${item.title}" está en la posición #$queuePos de la cola de descargas.',
                                  style: GoogleFonts.bangers(color: const Color(0xFFFFDE59)),
                                ),
                                action: SnackBarAction(
                                  label: 'VER COLA',
                                  textColor: const Color(0xFF39FF14),
                                  onPressed: onOpenDownloadQueue,
                                ),
                              ),
                            );
                            return;
                          }

                          HapticFeedback.mediumImpact();
                          final added = pv.addToDownloadQueue(item);
                          if (!context.mounted) return;
                          if (added) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1B2E18),
                                content: Text(
                                  pv.isDownloading && !isCurrentDownloading
                                      ? '¡"${item.title}" agregada a la cola (#${pv.queuedCount})!'
                                      : 'Iniciando descarga de "${item.title}"...',
                                  style: GoogleFonts.bangers(color: Colors.white),
                                ),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'VER COLA',
                                  textColor: const Color(0xFF39FF14),
                                  onPressed: onOpenDownloadQueue,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAlreadySaved
                                ? const Color(0xFF222222)
                                : isCurrentDownloading
                                    ? const Color(0xFF1E381A)
                                    : isQueued
                                        ? const Color(0xFF3D3212)
                                        : const Color(0xFF39FF14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCurrentDownloading) ...[
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF39FF14),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                isAlreadySaved
                                    ? 'GUARDADO'
                                    : isCurrentDownloading
                                        ? '${(pv.downloadProgress * 100).toInt()}%'
                                        : isQueued
                                            ? 'EN COLA (#$queuePos)'
                                            : 'GUARDAR',
                                style: GoogleFonts.bangers(
                                  color: isAlreadySaved
                                      ? Colors.white38
                                      : isCurrentDownloading
                                          ? const Color(0xFF39FF14)
                                          : isQueued
                                              ? const Color(0xFFFFDE59)
                                              : const Color(0xFF0A0A0A),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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
