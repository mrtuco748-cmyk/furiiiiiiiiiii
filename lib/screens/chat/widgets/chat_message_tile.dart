import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/message.dart';
import '../../../theme/app_theme.dart';
import '../chat_style.dart';
import 'chat_media_body.dart';
import 'chat_reactions_row.dart';

/// Burbuja de mensaje estilo WhatsApp con bloques sólidos temáticos F.U.R.I.
/// Cero bordes contrastantes, esquinas redondeadas con cola WhatsApp,
/// metadata de hora y palomitas en la esquina inferior derecha.
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
    final isSticker = message.messageType == 'sticker';
    final blockColor = isSticker
        ? Colors.transparent
        : (isMine ? theme.a : ChatStyle.partnerBubble);
    final textColor = isMine ? theme.dark : ChatStyle.lightText;
    final subColor = isSticker
        ? Colors.white70
        : (isMine ? theme.dark.withValues(alpha: 0.65) : ChatStyle.subText);
    final raw = message.createdAt;
    final timeStr = raw != null
        ? '${raw.hour.toString().padLeft(2, '0')}:${raw.minute.toString().padLeft(2, '0')}'
        : '';

    final bubbleRadius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Padding(
      padding: EdgeInsets.only(
        bottom: message.reactions.isEmpty ? 6 : 14,
        left: isMine ? 48 : 6,
        right: isMine ? 6 : 48,
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
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                padding: isSticker
                    ? const EdgeInsets.all(2)
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: isSticker ? BorderRadius.zero : bubbleRadius,
                ),
                child: Column(
                  crossAxisAlignment:
                      isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Banner de respuesta citada (reply)
                    if (message.replyContent != null &&
                        message.replyContent!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Colors.black.withValues(alpha: 0.12)
                              : const Color(0xFF1B2228),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 3,
                                decoration: BoxDecoration(
                                  color: isMine ? theme.dark : ChatStyle.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  message.replyContent!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isMine
                                        ? theme.dark.withValues(alpha: 0.85)
                                        : Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Cuerpo del mensaje (texto o multimedia)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ChatMediaBody(
                        message: message,
                        textColor: textColor,
                        downloading: downloading,
                        onDownload: onDownload,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Fila de hora y palomitas de entrega/lectura (vistos)
                    if (isSticker)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x99141414),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
                                    ? ChatStyle.checkBlue
                                    : Colors.white70,
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 4),
                            Icon(
                              switch (message.tickState) {
                                MessageTick.read => Icons.done_all,
                                MessageTick.delivered => Icons.done_all,
                                MessageTick.sent => Icons.done,
                              },
                              size: 15,
                              color: message.tickState == MessageTick.read
                                  ? ChatStyle.checkBlue
                                  : subColor,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),

              // Reacciones flotantes en la base de la burbuja
              if (message.reactions.isNotEmpty)
                Positioned(
                  bottom: -11,
                  right: isMine ? 6 : null,
                  left: isMine ? null : 6,
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