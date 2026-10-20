import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/music_player_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../helpers/music_ui_helpers.dart';

class MusicBottomPlayer extends StatelessWidget {
  final MusicPlayerProvider pv;
  final VoidCallback onOpenComments;

  const MusicBottomPlayer({
    super.key,
    required this.pv,
    required this.onOpenComments,
  });

  @override
  Widget build(BuildContext context) {
    final track = pv.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: const Color(0xFF39FF14),
              inactiveTrackColor: const Color(0xFF2A2A2A),
              thumbColor: const Color(0xFF39FF14),
            ),
            child: Slider(
              value: pv.position.inSeconds.toDouble().clamp(0.0, pv.duration.inSeconds.toDouble()),
              max: pv.duration.inSeconds > 0 ? pv.duration.inSeconds.toDouble() : 1.0,
              onChanged: (val) {
                pv.seek(Duration(seconds: val.toInt()));
              },
            ),
          ),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: track.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        track.thumbnailUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => fallbackMusicCover(width: 44, height: 44),
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
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${formatMusicDuration(pv.position)} / ${formatMusicDuration(pv.duration)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TapTile(
                onTap: onOpenComments,
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.chat_bubble_outline, color: Color(0xFF00D4FF), size: 22),
                ),
              ),
              const SizedBox(width: 4),
              TapTile(
                onTap: pv.playPrevious,
                child: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 6),
              TapTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  pv.isPlaying ? pv.pause() : pv.resume();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF39FF14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pv.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: const Color(0xFF0A0A0A),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TapTile(
                onTap: pv.playNext,
                child: const Icon(Icons.skip_next, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
