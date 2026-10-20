import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/download_queue_item.dart';
import '../../../providers/music_player_provider.dart';
import '../helpers/music_ui_helpers.dart';

void showDownloadQueueModal(BuildContext context, MusicPlayerProvider pv) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF141414),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Consumer<MusicPlayerProvider>(
        builder: (context, provider, _) {
          final queue = provider.downloadQueue;
          final hasFinished = queue.any((i) => i.isCompleted || i.isFailed || i.isCancelled);

          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.queue_music_rounded, color: Color(0xFF39FF14), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'COLA DE DESCARGAS',
                        style: GoogleFonts.bangers(
                          color: Colors.white,
                          fontSize: 20,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      if (hasFinished)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            provider.clearFinishedDownloads();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LIMPIAR',
                              style: GoogleFonts.bangers(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF222222),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (queue.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF39FF14), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No hay descargas pendientes',
                            style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Busca en YouTube y toca "GUARDAR" en los temas que quieras descargar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: queue.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final item = queue[i];
                          return DownloadQueueItemTile(provider: provider, item: item);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class DownloadQueueItemTile extends StatelessWidget {
  final MusicPlayerProvider provider;
  final DownloadQueueItem item;

  const DownloadQueueItemTile({
    super.key,
    required this.provider,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    Color statusBg;
    Color statusColor;
    String statusText;

    if (item.isDownloading) {
      statusBg = const Color(0xFF1E381A);
      statusColor = const Color(0xFF39FF14);
      statusText = '${(item.progress * 100).toInt()}%';
    } else if (item.isQueued) {
      final pos = provider.getQueuePosition(item.id);
      statusBg = const Color(0xFF3D3212);
      statusColor = const Color(0xFFFFDE59);
      statusText = 'EN COLA #$pos';
    } else if (item.isCompleted) {
      statusBg = const Color(0xFF1B2E18);
      statusColor = const Color(0xFF39FF14);
      statusText = 'GUARDADA';
    } else {
      statusBg = const Color(0xFF3B1A1A);
      statusColor = const Color(0xFFFF5252);
      statusText = 'FALLÓ';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: item.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          item.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => fallbackMusicCover(width: 44, height: 44),
                        )
                      : fallbackMusicCover(width: 44, height: 44),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.author} • ${item.durationFormatted}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.statusMessage,
                      style: TextStyle(
                        color: item.isFailed ? const Color(0xFFFF5252) : Colors.white38,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.bangers(color: statusColor, fontSize: 12),
                ),
              ),
              if (item.isQueued)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.removeFromQueue(item.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF282828),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white60, size: 14),
                  ),
                ),
              if (item.isFailed)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.retryDownload(item.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF282828),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Color(0xFF39FF14), size: 14),
                  ),
                ),
            ],
          ),
          if (item.isDownloading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: item.progress,
                backgroundColor: const Color(0xFF242424),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF39FF14)),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
