import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../chat_style.dart';
import 'chat_emoji_picker_view.dart';
import 'chat_stickers_picker_view.dart';

/// Panel interactivo inferior estilo WhatsApp con dos pestañas:
/// 1. Emojis organizados por categorías con teclado rápido.
/// 2. Stickers locales con opción de "Exportar desde WhatsApp" y visualización en cuadrícula.
class ChatEmojiStickerSheet extends StatefulWidget {
  final TextEditingController textController;
  final void Function(File stickerFile) onStickerSelected;
  final ThemeSet theme;

  const ChatEmojiStickerSheet({
    super.key,
    required this.textController,
    required this.onStickerSelected,
    required this.theme,
  });

  @override
  State<ChatEmojiStickerSheet> createState() => _ChatEmojiStickerSheetState();
}

class _ChatEmojiStickerSheetState extends State<ChatEmojiStickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      decoration: const BoxDecoration(
        color: ChatStyle.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Barra de pestañas estilo WhatsApp (Emojis | Stickers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: ChatStyle.inputBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabCtrl,
                    indicatorColor: widget.theme.a,
                    indicatorWeight: 3,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.sentiment_satisfied_alt_outlined, size: 24),
                        text: 'EMOJIS',
                      ),
                      Tab(
                        icon: Icon(Icons.sticky_note_2_outlined, size: 24),
                        text: 'STICKERS',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_hide_outlined, color: Colors.white70),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          if (_statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFF1B3B36),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF25D366),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                ChatEmojiPickerView(textController: widget.textController),
                ChatStickersPickerView(
                  theme: widget.theme,
                  onStickerSelected: widget.onStickerSelected,
                  onStatusChanged: (msg) {
                    if (mounted) setState(() => _statusMessage = msg);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
