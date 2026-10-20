import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import '../../../models/message.dart';
import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';
import 'chat_audio_player_tile.dart';
import 'chat_video_thumb.dart';

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
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          height: 1.35,
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'image':
      case 'gif':
      case 'sticker':
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
      case 'sticker':
        return Image.file(
          File(path),
          width: 140,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image,
            color: textColor,
            size: 40,
          ),
        );
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ],
        );
      case 'video':
        return ChatVideoThumb(path: path, textColor: textColor);
      case 'voice':
        return ChatAudioPlayerTile(path: path, textColor: textColor);
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
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
