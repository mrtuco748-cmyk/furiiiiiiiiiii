import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/music_player_provider.dart';
import '../../../widgets/tap_tile.dart';

class MusicHeader extends StatelessWidget {
  final MusicPlayerProvider pv;
  final VoidCallback onOpenQueue;

  const MusicHeader({
    super.key,
    required this.pv,
    required this.onOpenQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          TapTile(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.headphones, color: Color(0xFF39FF14), size: 28),
          const SizedBox(width: 10),
          Text(
            'MÚSICA',
            style: GoogleFonts.bangers(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (pv.activeOrQueuedCount > 0) ...[
            GestureDetector(
              onTap: onOpenQueue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF232E16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF39FF14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${pv.activeOrQueuedCount} en cola',
                      style: GoogleFonts.bangers(
                        color: const Color(0xFF39FF14),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${pv.tracks.length} temas',
              style: GoogleFonts.bangers(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MusicTabsBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabSelected;

  const MusicTabsBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              title: 'TEMAS',
              icon: Icons.library_music,
              active: currentTab == 0,
              color: const Color(0xFF9D00FF),
              onTap: () => onTabSelected(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              title: 'PLAYLISTS',
              icon: Icons.playlist_play,
              active: currentTab == 1,
              color: const Color(0xFF00D4FF),
              onTap: () => onTabSelected(1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              title: 'BUSCAR',
              icon: Icons.search,
              active: currentTab == 2,
              color: const Color(0xFFFF0033),
              onTap: () => onTabSelected(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bg = active ? color : const Color(0xFF161616);
    return TapTile(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.bangers(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MusicDownloadProgressBar extends StatelessWidget {
  final MusicPlayerProvider pv;
  final VoidCallback onOpenQueue;

  const MusicDownloadProgressBar({
    super.key,
    required this.pv,
    required this.onOpenQueue,
  });

  @override
  Widget build(BuildContext context) {
    final currentItem = pv.currentDownloadingItem;
    final title = currentItem?.title ?? pv.downloadStatus;
    final statusMsg = currentItem?.statusMessage ?? pv.downloadStatus;
    final queuedCount = pv.queuedCount;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onOpenQueue();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF39FF14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        statusMsg,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (queuedCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF382F10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$queuedCount en cola',
                      style: GoogleFonts.bangers(
                        color: const Color(0xFFFFDE59),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${(pv.downloadProgress * 100).toInt()}%',
                  style: GoogleFonts.bangers(color: const Color(0xFF39FF14), fontSize: 14),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pv.downloadProgress,
                backgroundColor: const Color(0xFF222222),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF39FF14)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
