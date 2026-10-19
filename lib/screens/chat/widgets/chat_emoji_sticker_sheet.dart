import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/sticker_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';

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
  List<File> _stickers = [];
  bool _loadingStickers = true;
  bool _importing = false;
  String? _statusMessage;

  static const Map<String, List<String>> _emojiCategories = {
    'Favoritos': ['❤️', '😂', '🥰', '😍', '🥺', '😭', '🔥', '👍', '💖', '✨', '💋', '🌹', '😘', '🤤', '🤤', '🎉'],
    'Caras': [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊',
      '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😋', '😛', '😜', '🤪', '😝',
      '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏', '😒',
      '🙄', '😬', '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢',
      '🤮', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐', '😕',
      '😟', '🙁', '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨', '😰', '😥',
      '😢', '😭', '😱', '😖', '😣', '😞', '😓', '😩', '😫', '🥱', '😤', '😡',
    ],
    'Amor': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕',
      '💞', '💓', '💗', '💖', '💘', '💝', '💟', '💌', '💋', '👩‍❤️‍👨', '💏', '💑',
      '💐', '🌹', '🥀', '🌺', '🌸', '🌷', '💍', '💎',
    ],
    'Gestos': [
      '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘', '👌', '🤏',
      '👈', '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐️', '🖖', '👋', '🤙', '💪',
      '🙏', '🤝', '👏', '🙌', '👐', '🤲',
    ],
    'Animales': [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮',
      '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤', '🦆',
      '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞',
      '🐢', '🐍', '🦎', '🐙', '🦑', '🦐', '🦀', '🐬', '🐳', '🦈',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadStickers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStickers() async {
    setState(() => _loadingStickers = true);
    final list = await StickerService.getSavedStickers();
    if (mounted) {
      setState(() {
        _stickers = list;
        _loadingStickers = false;
      });
    }
  }

  Future<void> _exportFromWhatsApp() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _importing = true;
      _statusMessage = 'Buscando stickers de WhatsApp...';
    });

    final count = await StickerService.exportFromWhatsAppDirect();
    if (!mounted) return;

    if (count > 0) {
      setState(() {
        _statusMessage = '¡Se exportaron $count stickers de WhatsApp con éxito!';
      });
      await _loadStickers();
    } else {
      // Si la búsqueda automática no encontró la ruta o está restringida por Scoped Storage, abrir selector
      setState(() {
        _statusMessage = 'Selecciona la carpeta o archivos de stickers...';
      });
      final pickedCount = await StickerService.pickAndImportStickers();
      if (!mounted) return;
      if (pickedCount > 0) {
        setState(() {
          _statusMessage = '¡Se importaron $pickedCount stickers con éxito!';
        });
        await _loadStickers();
      } else {
        setState(() {
          _statusMessage = 'No se encontraron stickers de WhatsApp en el almacenamiento.';
        });
      }
    }

    setState(() => _importing = false);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _statusMessage = null);
    });
  }

  void _onEmojiTap(String emoji) {
    HapticFeedback.selectionClick();
    final text = widget.textController.text;
    final selection = widget.textController.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      widget.textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + emoji.length),
      );
    } else {
      widget.textController.text += emoji;
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    final text = widget.textController.text;
    if (text.isEmpty) return;
    final characters = text.characters;
    widget.textController.text = characters.skipLast(1).toString();
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
                _buildEmojiView(),
                _buildStickersView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiView() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: _emojiCategories.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 8, bottom: 4),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white38,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: entry.value.map((emoji) {
                      return InkWell(
                        onTap: () => _onEmojiTap(emoji),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: Text(emoji, style: const TextStyle(fontSize: 26)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        // Barra inferior de borrado rápido
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: ChatStyle.inputBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.backspace_outlined, color: Colors.white70, size: 22),
                onPressed: _onBackspace,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStickersView() {
    if (_loadingStickers) {
      return Center(
        child: CircularProgressIndicator(color: widget.theme.a, strokeWidth: 3),
      );
    }

    if (_stickers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sticky_note_2, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'No tienes stickers guardados',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Trae todos tus stickers enviados y recibidos de WhatsApp con un solo toque.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              TapTile(
                onTap: _importing ? () {} : _exportFromWhatsApp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_importing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.download_for_offline, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _importing ? 'Importando...' : 'Exportar desde WhatsApp',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Barra superior de stickers con contador y botón para traer más
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: ChatStyle.inputBg,
          child: Row(
            children: [
              Text(
                '${_stickers.length} stickers disponibles',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TapTile(
                onTap: _importing ? () {} : _exportFromWhatsApp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Traer más de WhatsApp',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grilla de stickers
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: _stickers.length,
            itemBuilder: (ctx, i) {
              final file = _stickers[i];
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  widget.onStickerSelected(file);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ChatStyle.inputBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Colors.white38,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
