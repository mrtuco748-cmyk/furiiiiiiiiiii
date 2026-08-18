import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../app_state.dart';

/// Dialog para buscar y agregar videos al pizarrón.
/// Si `editElementId` no es null, edita el video existente en vez de crear.
class BoardVideoSearchDialog extends StatefulWidget {
  final BoardProviderV2 provider;
  final VoidCallback onClose;
  final double spawnX;
  final double spawnY;
  final int? editElementId;

  const BoardVideoSearchDialog({
    super.key,
    required this.provider,
    required this.onClose,
    this.spawnX = 100,
    this.spawnY = 100,
    this.editElementId,
  });

  @override
  State<BoardVideoSearchDialog> createState() => _BoardVideoSearchDialogState();
}

class _BoardVideoSearchDialogState extends State<BoardVideoSearchDialog> {
  final _urlCtrl = TextEditingController();
  String _error = '';

  bool get _isEditing => widget.editElementId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final el = widget.provider.findById(widget.editElementId);
      if (el != null) {
        _urlCtrl.text = el.content;
      }
    }
  }

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
      setState(() => _error = 'Solo se soportan URLs de YouTube o TikTok');
      return;
    }

    HapticFeedback.heavyImpact();
    if (_isEditing) {
      // Editar video existente: conserva id y posición.
      final live = widget.provider.findById(widget.editElementId);
      if (live != null) {
        widget.provider.update(live.copyWith(
          title: videoData.title ?? 'Video',
          content: url,
          data: videoData.toMap(),
        ));
      }
    } else {
      widget.provider.add(BoardElementV2(
        type: BoardElementType.video,
        title: videoData.title ?? 'Video',
        content: url,
        x: widget.spawnX,
        y: widget.spawnY,
        width: 320,
        height: 180,
        userId: AppState.myId,
        isNew: true,
        data: videoData.toMap(),
      ));
    }

    widget.onClose();
  }

  /// Solo acepta YouTube (youtube.com / youtu.be) y TikTok.
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

      if (videoId != null && videoId.isNotEmpty) {
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

    return null;
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
                  Text(
                    _isEditing ? 'Editar video' : 'Agregar video',
                    style: const TextStyle(
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
                  hintText: _isEditing
                      ? 'Nueva URL del video...'
                      : 'Pegá la URL del video (YouTube, TikTok, etc.)',
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
              if (!widget.provider.isOnline)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5757),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OFFLINE - cambios se guardan localmente',
                    style: TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Solo YouTube y TikTok',
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
                        border: Border.all(color: const Color(0xFF4FC3F7), width: 1.5),
                      ),
                      child: Text(
                        _isEditing ? 'Guardar' : 'Agregar',
                        style: const TextStyle(
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
