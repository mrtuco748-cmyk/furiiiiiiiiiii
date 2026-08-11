import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../app_state.dart';

/// Dialog para buscar y agregar videos al pizarrón.
class BoardVideoSearchDialog extends StatefulWidget {
  final BoardProviderV2 provider;
  final VoidCallback onClose;

  const BoardVideoSearchDialog({
    super.key,
    required this.provider,
    required this.onClose,
  });

  @override
  State<BoardVideoSearchDialog> createState() => _BoardVideoSearchDialogState();
}

class _BoardVideoSearchDialogState extends State<BoardVideoSearchDialog> {
  final _urlCtrl = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _addVideo() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Ingresá una URL');
      return;
    }

    final videoData = _parseVideoUrl(url);
    if (videoData == null) {
      setState(() => _error = 'URL no válida');
      return;
    }

    HapticFeedback.heavyImpact();
    widget.provider.add(BoardElementV2(
      type: BoardElementType.video,
      title: videoData.title ?? 'Video',
      content: url,
      x: 100,
      y: 100,
      width: 320,
      height: 180,
      userId: AppState.myId,
      isNew: true,
      data: videoData.toMap(),
    ));

    widget.onClose();
  }

  VideoData? _parseVideoUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // YouTube
    if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      String? videoId;
      if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.first;
      }

      if (videoId != null) {
        return VideoData(
          url: url,
          provider: 'youtube',
          title: 'YouTube Video',
          thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        );
      }
    }

    // TikTok
    if (uri.host.contains('tiktok.com')) {
      return VideoData(
        url: url,
        provider: 'tiktok',
        title: 'TikTok Video',
      );
    }

    // Generic
    return VideoData(
      url: url,
      provider: 'other',
      title: uri.host.isEmpty ? 'Video' : uri.host,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      top: 64,
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Agregar video',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Pegá la URL del video (YouTube, TikTok, etc.)',
                  hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                  ),
                  errorText: _error.isNotEmpty ? _error : null,
                ),
                onSubmitted: (_) => _addVideo(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Soporta: YouTube, TikTok, URLs directas',
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addVideo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC3F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Agregar',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
