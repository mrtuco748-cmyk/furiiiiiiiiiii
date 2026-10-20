import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/sticker_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';
import '../chat_style.dart';

/// Vista de selección, gestión e importación de stickers de WhatsApp.
class ChatStickersPickerView extends StatefulWidget {
  final ThemeSet theme;
  final void Function(File stickerFile) onStickerSelected;
  final void Function(String? message)? onStatusChanged;

  const ChatStickersPickerView({
    super.key,
    required this.theme,
    required this.onStickerSelected,
    this.onStatusChanged,
  });

  @override
  State<ChatStickersPickerView> createState() => _ChatStickersPickerViewState();
}

class _ChatStickersPickerViewState extends State<ChatStickersPickerView> {
  List<File> _stickers = [];
  bool _loadingStickers = true;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadStickers();
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

  void _setStatus(String? message, {int autoClearSeconds = 0}) {
    widget.onStatusChanged?.call(message);
    if (autoClearSeconds > 0) {
      Future.delayed(Duration(seconds: autoClearSeconds), () {
        if (mounted) widget.onStatusChanged?.call(null);
      });
    }
  }

  Future<void> _exportFromWhatsApp() async {
    HapticFeedback.mediumImpact();
    setState(() => _importing = true);
    _setStatus('Buscando stickers de WhatsApp...');

    final count = await StickerService.exportFromWhatsAppDirect();
    if (!mounted) return;

    if (count > 0) {
      _setStatus('¡Se exportaron $count stickers de WhatsApp con éxito!', autoClearSeconds: 4);
      await _loadStickers();
    } else {
      _setStatus('Selecciona la carpeta o archivos de stickers...');
      final pickedCount = await StickerService.pickAndImportStickers();
      if (!mounted) return;
      if (pickedCount > 0) {
        _setStatus('¡Se importaron $pickedCount stickers con éxito!', autoClearSeconds: 4);
        await _loadStickers();
      } else {
        _setStatus('No se encontraron stickers de WhatsApp en el almacenamiento.', autoClearSeconds: 4);
      }
    }

    if (mounted) {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStickers) {
      return Center(
        child: CircularProgressIndicator(color: widget.theme.a, strokeWidth: 3),
      );
    }

    if (_stickers.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
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

  Widget _buildEmptyView() {
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
}
