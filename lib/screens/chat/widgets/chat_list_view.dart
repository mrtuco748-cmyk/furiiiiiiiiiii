import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/message.dart';
import '../../../providers/chat_provider.dart';
import '../../../theme/app_theme.dart';
import '../chat_style.dart';
import 'chat_message_tile.dart';
import 'chat_swipe_to_reply.dart';

bool _isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  final localA = a.toLocal();
  final localB = b.toLocal();
  return localA.year == localB.year &&
      localA.month == localB.month &&
      localA.day == localB.day;
}

String _formatDateHeader(DateTime dt) {
  final now = DateTime.now();
  final local = dt.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final msgDate = DateTime(local.year, local.month, local.day);
  final diff = today.difference(msgDate).inDays;
  if (diff == 0) return 'HOY';
  if (diff == 1) return 'AYER';
  const months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  final mName = months[(local.month - 1).clamp(0, 11)];
  if (local.year == now.year) {
    return '${local.day} de $mName';
  }
  return '${local.day} de $mName de ${local.year}';
}

Widget _dateChip(DateTime dt) {
  final text = _formatDateHeader(dt);
  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: ChatStyle.panel,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ChatStyle.subText,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}

/// Lista de mensajes invertida con chips de fecha y carga paginada
class ChatListView extends StatelessWidget {
  final ScrollController scrollController;
  final ChatProvider chat;
  final ThemeSet theme;
  final void Function(Message) onSwipeReply;
  final void Function(Message) onLongPressMessage;

  const ChatListView({
    super.key,
    required this.scrollController,
    required this.chat,
    required this.theme,
    required this.onSwipeReply,
    required this.onLongPressMessage,
  });

  @override
  Widget build(BuildContext context) {
    final items = chat.messages.reversed.toList();
    final bool showTopLoader = chat.loadingOlder;
    final bool showStartBanner = !chat.hasMore && items.isNotEmpty;
    final int extraTopItem = (showTopLoader || showStartBanner) ? 1 : 0;
    final int itemCount = items.length + extraTopItem;

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      itemCount: itemCount,
      itemBuilder: (ctx, i) {
        if (i == items.length) {
          if (showTopLoader) {
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: ChatStyle.primary,
                  ),
                ),
              ),
            );
          }
          if (showStartBanner) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ChatStyle.panel.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Inicio de los mensajes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ChatStyle.subText,
                  ),
                ),
              ),
            );
          }
        }

        final m = items[i];
        final next = i + 1 < items.length ? items[i + 1] : null;
        final bool showDateHeader =
            next == null || !_isSameDay(m.createdAt, next.createdAt);
        final isMine = m.fromUser == chat.myId;

        final tile = ChatSwipeToReply(
          onReply: () => onSwipeReply(m),
          child: ChatMessageTile(
            message: m,
            isMine: isMine,
            theme: theme,
            downloading: chat.isDownloading(m.id),
            onLongPress: () => onLongPressMessage(m),
            onReactionTap: (key) => chat.toggleReaction(m, key),
            onDownload: () => chat.downloadMedia(m),
          ),
        );

        if (showDateHeader && m.createdAt != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateChip(m.createdAt!),
              tile,
            ],
          );
        }

        return tile;
      },
    );
  }
}
