import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';

import '../../../models/message.dart';
import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';

/// Cuerpo de una burbuja según si es texto o media (descargable/local).
class ChatMediaBody extends StatelessWidget {
  final Message message;
  final Color textColor;
  final bool downloading;
  final VoidCallback onDownload;

  const ChatMediaBody({
    super.key,
    required this.message,
    required this.textColor,
    required this.downloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (!message.isMedia) {
      return Text(
        message.content,
        style: GoogleFonts.bangers(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: textColor,
        ),
      );
    }

    if (message.hasLocalMedia) {
      return _ChatLocalMediaView(message: message, textColor: textColor);
    }

    if (message.needsCloudDownload || downloading) {
      return GestureDetector(
        onTap: downloading ? null : onDownload,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ChatStyle.mediaBg,
            border: Border.all(color: ChatStyle.mediaBg, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (downloading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: ChatStyle.primary),
                )
              else
                Icon(_iconFor(message.messageType), color: textColor, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  downloading
                      ? 'Descargando...'
                      : (message.attachmentName ?? message.previewText),
                  style: GoogleFonts.bangers(fontSize: 13, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!downloading) ...[
                const SizedBox(width: 8),
                Icon(Icons.download, color: textColor, size: 18),
              ],
            ],
          ),
        ),
      );
    }

    // cloud borrado y sin local
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, color: textColor.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 6),
        Text(
          message.attachmentName ?? message.previewText,
          style: GoogleFonts.bangers(fontSize: 13, color: textColor),
        ),
      ],
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'image':
      case 'gif':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'voice':
        return Icons.mic;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _ChatLocalMediaView extends StatelessWidget {
  final Message message;
  final Color textColor;
  const _ChatLocalMediaView({required this.message, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final path = message.localPath!;
    switch (message.messageType) {
      case 'image':
      case 'gif':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                width: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image,
                  color: textColor,
                  size: 40,
                ),
              ),
            ),
            if (message.content.isNotEmpty &&
                message.content != message.attachmentName) ...[
              const SizedBox(height: 6),
              Text(
                message.content,
                style: GoogleFonts.bangers(fontSize: 14, color: textColor),
              ),
            ],
          ],
        );
      case 'video':
        return _ChatVideoThumb(path: path, textColor: textColor);
      case 'voice':
        return _ChatAudioPlayerTile(path: path, textColor: textColor);
      default:
        return TapTile(
          onTap: () => OpenFilex.open(path),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: textColor, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.attachmentName ?? message.content,
                  style: GoogleFonts.bangers(fontSize: 13, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.open_in_new, color: textColor, size: 16),
            ],
          ),
        );
    }
  }
}

class _ChatVideoThumb extends StatefulWidget {
  final String path;
  final Color textColor;
  const _ChatVideoThumb({required this.path, required this.textColor});

  @override
  State<_ChatVideoThumb> createState() => _ChatVideoThumbState();
}

class _ChatVideoThumbState extends State<_ChatVideoThumb> {
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
                      border: Border.all(color: ChatStyle.bg, width: 2),
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

class _ChatAudioPlayerTile extends StatefulWidget {
  final String path;
  final Color textColor;
  const _ChatAudioPlayerTile({required this.path, required this.textColor});

  @override
  State<_ChatAudioPlayerTile> createState() => _ChatAudioPlayerTileState();
}

class _ChatAudioPlayerTileState extends State<_ChatAudioPlayerTile> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    await _player.play(DeviceFileSource(widget.path));
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: _toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _playing ? Icons.stop : Icons.play_arrow,
            color: widget.textColor,
            size: 26,
          ),
          const SizedBox(width: 6),
          Icon(Icons.graphic_eq, color: widget.textColor, size: 20),
          const SizedBox(width: 6),
          Text(
            'Audio',
            style: GoogleFonts.bangers(
              fontSize: 13,
              color: widget.textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}