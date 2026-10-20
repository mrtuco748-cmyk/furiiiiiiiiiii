import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';

const _dark = Color(0xFF1A1A1A);
const _cSent = Color(0xFF00F0FF);
const _cInbox = Color(0xFFFF1493);
const _cRead = Color(0xFF7A3E5A);
const _cSealed = Color(0xFFFFB300);

class LetterDialogs {
  static String formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static void showLetter({
    required BuildContext context,
    required String title,
    required String body,
    required String date,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: GoogleFonts.bangers(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: GoogleFonts.bangers(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              formatDate(date),
              style: GoogleFonts.bangers(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TapTile(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _dark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close, color: color, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  static void showSentLetterEditor({
    required BuildContext context,
    required Map<String, dynamic> letter,
    required Future<void> Function(int id, String newTitle, String newBody)
        onSave,
  }) {
    final titleCtrl =
        TextEditingController(text: letter['title']?.toString() ?? '');
    final bodyCtrl =
        TextEditingController(text: letter['content']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Editar carta',
          style: GoogleFonts.bangers(color: _cSent, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.bangers(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Título',
                hintStyle: GoogleFonts.bangers(color: Colors.white38),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Cuerpo',
                hintStyle: GoogleFonts.bangers(color: Colors.white38),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Text(
              'Fecha: ${formatDate(letter['created_at']?.toString() ?? '')}',
              style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TapTile(
            onTap: () async {
              final newTitle = titleCtrl.text.trim();
              final newBody = bodyCtrl.text.trim();
              if (newTitle.isEmpty || newBody.isEmpty) return;
              HapticFeedback.heavyImpact();
              final id = (letter['id'] as num?)?.toInt() ?? 0;
              await onSave(id, newTitle, newBody);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cSent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Guardar',
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          TapTile(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _dark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: _cSent, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  static void handleCardTap({
    required BuildContext context,
    required Map<String, dynamic> letter,
    required bool incoming,
    required bool isSealed,
    required bool isReadByMe,
    required String? myId,
    required void Function(int id) onMarkRead,
    required Future<void> Function(int id, String newTitle, String newBody)
        onSaveSent,
  }) {
    final title = letter['title']?.toString() ?? '';
    final body = letter['content']?.toString() ?? '';
    final date = letter['created_at']?.toString() ?? '';
    final color = incoming
        ? (isSealed ? _cSealed : (isReadByMe ? _cRead : _cInbox))
        : _cSent;

    final isMySent = !incoming && letter['from_user'] == myId;
    if (isSealed) {
      showLetter(
        context: context,
        title: title,
        body: '🔒 Se podrá abrir más adelante',
        date: date,
        color: _cSealed,
      );
    } else if (isMySent) {
      showSentLetterEditor(
        context: context,
        letter: letter,
        onSave: onSaveSent,
      );
    } else {
      if (incoming) onMarkRead((letter['id'] as num?)?.toInt() ?? -1);
      showLetter(
        context: context,
        title: title,
        body: body,
        date: date,
        color: color,
      );
    }
  }
}
