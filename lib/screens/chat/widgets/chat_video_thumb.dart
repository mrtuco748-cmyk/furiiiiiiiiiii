import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';

/// Thumbnail interactivo para videos en las burbujas de chat.
class ChatVideoThumb extends StatefulWidget {
  final String path;
  final Color textColor;
  const ChatVideoThumb({super.key, required this.path, required this.textColor});

  @override
  State<ChatVideoThumb> createState() => _ChatVideoThumbState();
}

class _ChatVideoThumbState extends State<ChatVideoThumb> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return SizedBox(
        width: 200,
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: widget.textColor, strokeWidth: 2),
        ),
      );
    }
    return TapTile(
      onTap: () {
        final c = _ctrl!;
        setState(() {
          c.value.isPlaying ? c.pause() : c.play();
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 220,
          child: AspectRatio(
            aspectRatio: _ctrl!.value.aspectRatio == 0
                ? 16 / 9
                : _ctrl!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_ctrl!),
                if (!_ctrl!.value.isPlaying)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ChatStyle.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: ChatStyle.primary, size: 28),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
