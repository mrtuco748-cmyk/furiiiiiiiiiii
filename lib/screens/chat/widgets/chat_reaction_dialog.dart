import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/message.dart';
import '../../../providers/chat_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';
import 'chat_react_chip.dart';

Future<String?> promptCustomEmoji(BuildContext context) async {
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: ChatStyle.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reacción personalizada',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 8,
          style: const TextStyle(color: Colors.white, fontSize: 20),
          decoration: const InputDecoration(
            hintText: 'Emoji o texto corto...',
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChatStyle.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
  ctrl.dispose();
  return result;
}

void showChatReactionBar(BuildContext context, Message msg, ChatProvider chat) {
  HapticFeedback.mediumImpact();
  showDialog<void>(
    context: context,
    barrierColor: const Color(0x88000000),
    builder: (ctx) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: ChatStyle.panel,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...Message.defaultReactionEmojis.map((e) {
                  final selected = msg.myReactionKey(chat.myId) == e;
                  return ChatReactChip(
                    label: e,
                    selected: selected,
                    onTap: () {
                      Navigator.pop(ctx);
                      chat.toggleReaction(msg, e);
                    },
                  );
                }),
                TapTile(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final custom = await promptCustomEmoji(context);
                    if (custom != null && custom.isNotEmpty) {
                      chat.toggleReaction(msg, custom);
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: ChatStyle.inputBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
