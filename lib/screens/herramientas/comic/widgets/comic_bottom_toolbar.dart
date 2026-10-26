import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../../widgets/creative_icon.dart';

/// Barra flotante inferior de herramientas de cómic:
/// Diseño no invasivo, compacto, sólo iconos sin texto y acceso inmediato.
class ComicBottomToolbar extends StatelessWidget {
  final ComicController controller;
  final VoidCallback onToggleBubble;
  final VoidCallback onToggleSfx;
  final VoidCallback onToggleTemplates;

  const ComicBottomToolbar({
    super.key,
    required this.controller,
    required this.onToggleBubble,
    required this.onToggleSfx,
    required this.onToggleTemplates,
  });

  Widget _buildIconButton({
    String? asset,
    IconData? icon,
    required Color color,
    VoidCallback? onTap,
    Color bg = const Color(0xFF222222),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: asset != null
            ? CreativeIcon(asset, color: color, size: 18, fallback: icon)
            : Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _confirmDeletePage(BuildContext context) {
    if (controller.project.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El cómic debe tener al menos una página.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar Página?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Se eliminará la página ${controller.activePageIndex + 1} y todas sus viñetas.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              controller.removePage(controller.activePageIndex);
              Navigator.of(ctx).pop();
            },
            child: const Text('ELIMINAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF181818).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Plantillas
          _buildIconButton(
            icon: Icons.grid_view_rounded,
            color: const Color(0xFFFFDE59),
            onTap: onToggleTemplates,
          ),
          const SizedBox(width: 8),

          // Bocadillos / Globos
          _buildIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFF5AC8FA),
            onTap: onToggleBubble,
          ),
          const SizedBox(width: 8),

          // Efectos SFX
          _buildIconButton(
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFF9500),
            onTap: onToggleSfx,
          ),
          if (controller.project.pages.length > 1) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: Colors.white12),
            const SizedBox(width: 8),
            _buildIconButton(
              icon: Icons.delete_outline,
              color: const Color(0xFFFF453A),
              bg: const Color(0xFF281717),
              onTap: () => _confirmDeletePage(context),
            ),
          ],
        ],
      ),
    );
  }
}
