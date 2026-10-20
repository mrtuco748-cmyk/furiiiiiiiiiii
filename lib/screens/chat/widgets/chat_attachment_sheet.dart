import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';

String? chatMimeFromExt(String ext) {
  switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'mp3':
      return 'audio/mpeg';
    case 'm4a':
      return 'audio/mp4';
    case 'wav':
      return 'audio/wav';
    case 'pdf':
      return 'application/pdf';
    default:
      return null;
  }
}

void showChatAttachmentSheet({
  required BuildContext context,
  required VoidCallback onPickGallery,
  required VoidCallback onPickCamera,
  required VoidCallback onPickVideo,
  required VoidCallback onPickFile,
  required Future<void> Function(PlatformFile file) onPickGif,
}) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: ChatStyle.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      Widget item(IconData icon, String label, Color color, VoidCallback onTap) {
        return TapTile(
          onTap: () {
            Navigator.pop(ctx);
            onTap();
          },
          child: Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              item(Icons.photo_library, 'Galería', const Color(0xFF9C27B0), onPickGallery),
              item(Icons.camera_alt, 'Cámara', const Color(0xFFE91E63), onPickCamera),
              item(Icons.videocam, 'Video', const Color(0xFF00B0FF), onPickVideo),
              item(Icons.attach_file, 'Archivo', const Color(0xFFFF9800), onPickFile),
              item(Icons.gif_box, 'GIF', const Color(0xFF4CAF50), () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const ['gif'],
                );
                if (result == null || result.files.single.path == null) return;
                await onPickGif(result.files.single);
              }),
            ],
          ),
        ),
      );
    },
  );
}
