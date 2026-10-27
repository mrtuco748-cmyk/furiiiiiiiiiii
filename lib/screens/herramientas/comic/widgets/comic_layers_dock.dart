import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_bubble.dart';
import '../models/comic_panel.dart';
import '../models/comic_sticker.dart';

/// Dock lateral de capas y elementos de la página activa de cómic.
/// Permite visualizar, seleccionar y gestionar viñetas, globos y efectos de sonido.
class ComicLayersDock extends StatelessWidget {
  final ComicController controller;
  final VoidCallback onClose;
  final VoidCallback? onElementSelected;

  const ComicLayersDock({
    super.key,
    required this.controller,
    required this.onClose,
    this.onElementSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final page = controller.activePage;
        final selectedPanelId = controller.selectedPanelId;
        final selectedBubbleId = controller.selectedBubbleId;
        final selectedSfxId = controller.selectedSfxId;

        return Container(
          width: 164,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            border: Border.all(color: const Color(0xFF333333), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: SafeArea(
            top: true,
            bottom: true,
            left: false,
            right: false,
            child: Column(
              children: [
                // Cabecera: Título de capas de la página + Botón cerrar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.layers, size: 16, color: Color(0xFF00D4FF)),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'CAPAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF282828),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.close, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF333333), height: 1),

                // Lista de elementos en orden visual (globos arriba, viñetas de fondo)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    children: [
                      // Sección: Globos de Diálogo
                      if (page.bubbles.isNotEmpty) ...[
                        _buildSectionHeader('GLOBOS (${page.bubbles.length})'),
                        for (int i = page.bubbles.length - 1; i >= 0; i--)
                          _buildBubbleTile(page.bubbles[i], page.bubbles[i].id == selectedBubbleId),
                        const SizedBox(height: 6),
                      ],

                      // Sección: Onomatopeyas SFX
                      if (page.sfxStickers.isNotEmpty) ...[
                        _buildSectionHeader('SFX (${page.sfxStickers.length})'),
                        for (int i = page.sfxStickers.length - 1; i >= 0; i--)
                          _buildSfxTile(page.sfxStickers[i], page.sfxStickers[i].id == selectedSfxId),
                        const SizedBox(height: 6),
                      ],

                      // Sección: Viñetas / Paneles
                      if (page.panels.isNotEmpty) ...[
                        _buildSectionHeader('VIÑETAS (${page.panels.length})'),
                        for (int i = page.panels.length - 1; i >= 0; i--)
                          _buildPanelTile(page.panels[i], i, page.panels[i].id == selectedPanelId),
                      ],

                      if (page.bubbles.isEmpty && page.sfxStickers.isEmpty && page.panels.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Página vacía\nUsa + para añadir',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildBubbleTile(ComicBubble bubble, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1B2E35) : const Color(0xFF262626),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF383838), width: isSelected ? 1.5 : 1.0),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF00D4FF)),
        title: Text(
          bubble.text.isNotEmpty ? bubble.text : 'Globo vacío',
          style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          controller.selectBubble(bubble.id);
          onElementSelected?.call();
        },
      ),
    );
  }

  Widget _buildSfxTile(ComicSticker sfx, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2D2515) : const Color(0xFF262626),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? const Color(0xFFFFDE59) : const Color(0xFF383838), width: isSelected ? 1.5 : 1.0),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: const Icon(Icons.flash_on, size: 16, color: Color(0xFFFFDE59)),
        title: Text(
          sfx.text,
          style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          controller.selectSfx(sfx.id);
          onElementSelected?.call();
        },
      ),
    );
  }

  Widget _buildPanelTile(ComicPanel panel, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E2833) : const Color(0xFF262626),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? const Color(0xFF5AC8FA) : const Color(0xFF383838), width: isSelected ? 1.5 : 1.0),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: const Icon(Icons.crop_square, size: 16, color: Color(0xFF5AC8FA)),
        title: Text(
          'Viñeta ${index + 1}',
          style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: panel.drawingPngBase64 != null
            ? const Icon(Icons.brush, size: 12, color: Color(0xFF39FF14))
            : null,
        onTap: () {
          controller.selectPanel(panel.id);
          onElementSelected?.call();
        },
      ),
    );
  }
}
