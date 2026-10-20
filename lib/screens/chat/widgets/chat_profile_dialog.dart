import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../chat_style.dart';

ImageProvider? getAvatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;
  if (avatarUrl.startsWith('data:image')) {
    final comma = avatarUrl.indexOf(',');
    if (comma != -1) {
      final base64Str = avatarUrl.substring(comma + 1);
      try {
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
  } else if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
    return NetworkImage(avatarUrl);
  } else if (File(avatarUrl).existsSync()) {
    return FileImage(File(avatarUrl));
  }
  return null;
}

Future<void> pickAndSetMyAvatar({
  required BuildContext context,
  required ImagePicker picker,
  required Future<void> Function(String base64Image) onUpdateAvatar,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: ChatStyle.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cambiar mi foto de perfil',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: ChatStyle.primary),
              title: Text(
                'Elegir de la galería',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: ChatStyle.primary),
              title: Text(
                'Tomar foto con la cámara',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null || !context.mounted) return;

  try {
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    if (picked == null || !context.mounted) return;

    final bytes = await File(picked.path).readAsBytes();
    final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    if (!context.mounted) return;
    await onUpdateAvatar(base64Image);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Foto de perfil actualizada!',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF25D366),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (_) {}
}

void showChatProfileDialog({
  required BuildContext context,
  required String partnerName,
  required String? avatarUrl,
  required VoidCallback onChangeAvatar,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: ChatStyle.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: const Color(0xFF2A2A2A),
              backgroundImage: getAvatarImageProvider(avatarUrl),
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 42,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              partnerName,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pareja F.U.R.I',
              style: GoogleFonts.plusJakartaSans(
                color: ChatStyle.subText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatStyle.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: Text(
                'Cambiar mi foto de perfil',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                onChangeAvatar();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
