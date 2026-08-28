import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/message.dart';
import '../../../theme/app_theme.dart';
import '../chat_style.dart';
import 'chat_media_body.dart';
import 'chat_reactions_row.dart';

/// Burbuja de mensaje: texto/media, reply, ticks y reacciones.
class ChatMessageTile extends StatelessWidget {
  final Message message;
  final bool isMine;
  final ThemeSet theme;
  final bool downloading;
  final VoidCallback onLongPress;
  final void Function(String key) onReactionTap;
  final VoidCallback onDownload;

  const ChatMessageTile({
    super.key,
    required this.message,
    required this.isMine,
    required this.theme,
    required this.downloading,
    required this.onLongPress,
    required this.onReactionTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final panel = ChatStyle.panel;
    final blockColor = isMine ? theme.a : theme.e;
    final textColor = isMine ? theme.dark : theme.light;
    final subColor = isMine ? theme.dark.withValues(alpha: 0.6) : Colors.white38;
    final raw = message.createdAt;
    final timeStr = raw != null
        ? '${raw.hour.toString().padLeft(2, '0')}:${raw.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: message.reactions.isEmpty ? 8 : 14,
        left: isMine ? 48 : 4,
        right: isMine ? 4 : 48,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: blockColor,
                  border: Border.all(color: blockColor, width: 3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.replyContent != null &&
                        message.replyContent!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: panel,
                          border: Border.all(color: panel, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.replyContent!,
                          style: GoogleFonts.bangers(
                            fontSize: 11,
                            color: ChatStyle.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ChatMediaBody(
                      message: message,
                      textColor: textColor,
                      downloading: downloading,
                      onDownload: onDownload,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.bangers(fontSize: 10, color: subColor),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            switch (message.tickState) {
                              MessageTick.read => Icons.done_all,
                              MessageTick.delivered => Icons.done_all,
                              MessageTick.sent => Icons.done,
                            },
                            size: 14,
                            color: message.tickState == MessageTick.read
                                ? const Color(0xFF4FC3FF)
                                : subColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (message.reactions.isNotEmpty)
                Positioned(
                  bottom: -12,
                  right: isMine ? 8 : null,
                  left: isMine ? null : 8,
                  child: ChatReactionsRow(
                    reactions: message.reactions,
                    onTap: onReactionTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}