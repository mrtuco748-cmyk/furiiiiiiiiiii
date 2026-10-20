import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/music_player_provider.dart';

class FloatingMusicBar extends StatelessWidget {
  final MusicPlayerProvider musicPv;
  final Animation<double> vinylTurns;
  final VoidCallback onDismiss;
  final VoidCallback onOpenMusicScreen;

  const FloatingMusicBar({
    super.key,
    required this.musicPv,
    required this.vinylTurns,
    required this.onDismiss,
    required this.onOpenMusicScreen,
  });

  @override
  Widget build(BuildContext context) {
    final track = musicPv.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final progress = musicPv.duration.inMilliseconds > 0
        ? (musicPv.position.inMilliseconds / musicPv.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onOpenMusicScreen,
                    child: RotationTransition(
                      turns: vinylTurns,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF282828),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00F0FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.music_note,
                                size: 10,
                                color: Color(0xFF121212),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onOpenMusicScreen,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: GoogleFonts.bangers(
                              fontSize: 15,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist.isNotEmpty
                                ? track.artist
                                : 'F.U.R.I Música',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: musicPv.playPrevious,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C2C2C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.skip_previous_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: musicPv.togglePlayPause,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00F0FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            musicPv.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 24,
                            color: const Color(0xFF121212),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: musicPv.playNext,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C2C2C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.skip_next_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF262626),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFF282828),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  color: const Color(0xFF00F0FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
