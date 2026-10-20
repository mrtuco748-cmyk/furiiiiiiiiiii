import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/chat_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';

/// Banner cuando se está respondiendo a un mensaje
class ChatReplyBanner extends StatelessWidget {
  final ChatProvider chat;
  final ThemeSet theme;

  const ChatReplyBanner({
    super.key,
    required this.chat,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final preview = chat.replyTo?.previewText ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChatStyle.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: theme.a,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.reply, color: Colors.white70, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Respondiendo a mensaje',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.a,
                  ),
                ),
                Text(
                  preview,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            onPressed: chat.clearReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Banner de error transitorio
class ChatErrorBanner extends StatelessWidget {
  final ChatProvider chat;
  const ChatErrorBanner({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ChatStyle.errorBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chat.error ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TapTile(
            onTap: chat.clearError,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Estado de error general con botón para reintentar
class ChatErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const ChatErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: ChatStyle.errorBg, size: 48),
          const SizedBox(height: 12),
          const Text('Error al cargar mensajes', style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              onRetry();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Estado sin mensajes
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Colors.white.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin mensajes aún',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¡Envía el primer mensaje a tu pareja!',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
