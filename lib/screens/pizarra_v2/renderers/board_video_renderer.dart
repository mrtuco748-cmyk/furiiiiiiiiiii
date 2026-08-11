import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';

/// Renderer para video embed (YouTube, TikTok, etc.).
/// Muestra thumbnail + play button. Al tocar, abre el video en el navegador.
class BoardVideoRenderer extends StatelessWidget {
  final BoardElementV2 element;

  const BoardVideoRenderer({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    final data = VideoData.fromMap(element.data);
    final w = element.width ?? 320;
    final h = element.height ?? 180;

    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Thumbnail or placeholder
          if (data.thumbnailUrl != null)
            Image.network(
              data.thumbnailUrl!,
              fit: BoxFit.cover,
              width: w,
              height: h,
              errorBuilder: (_, _, _) => _placeholder(w, h, data),
            )
          else
            _placeholder(w, h, data),
          // Play button (visual; la apertura la maneja el canvas al
          // tocar el video con selección activa)
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          // Title overlay
          if (data.title != null && data.title!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                child: Text(
                  data.title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(double w, double h, VideoData data) {
    return Container(
      width: w,
      height: h,
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _providerIcon(data.provider),
            color: Colors.white54,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            data.provider.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  IconData _providerIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle;
      case 'tiktok':
        return Icons.music_video;
      default:
        return Icons.videocam;
    }
  }
}