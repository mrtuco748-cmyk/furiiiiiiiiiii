import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../../widgets/creative_icon.dart';

/// Barra superior flotante y no invasiva para el creador de cómics:
/// Título de cómic editable, indicadores de página, Deshacer/Rehacer y accesos rápidos.
class ComicTopBar extends StatelessWidget {
  final ComicController controller;
  final VoidCallback onOpenProjects;
  final VoidCallback onOpenReader;
  final VoidCallback onOpenExport;
  final VoidCallback onToggleImmersive;
  final VoidCallback? onToggleLayers;
  final bool isLayersOpen;
  final bool isImmersive;

  const ComicTopBar({
    super.key,
    required this.controller,
    required this.onOpenProjects,
    required this.onOpenReader,
    required this.onOpenExport,
    required this.onToggleImmersive,
    this.onToggleLayers,
    this.isLayersOpen = false,
    this.isImmersive = false,
  });

  Future<void> _showRenameDialog(BuildContext context) async {
    final textController = TextEditingController(text: controller.project.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFFFFDE59), size: 20),
            SizedBox(width: 8),
            Text('Nombre del Cómic', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Ej. Mi Historieta Manga',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF282828),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final t = textController.text.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
            child: const Text('Guardar', style: TextStyle(color: Color(0xFFFFDE59), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      controller.setTitle(newTitle);
    }
  }

  Widget _buildIconButton({
    String? asset,
    IconData? icon,
    required Color color,
    required VoidCallback onTap,
    Color bg = const Color(0xFF1E1E1E),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: asset != null
            ? CreativeIcon(asset, color: color, size: 18, fallback: icon)
            : Icon(icon, color: color, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = controller.project.pages.length;
    final currentPage = controller.activePageIndex + 1;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _buildIconButton(
              icon: Icons.arrow_back,
              color: Colors.white,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),

            // Botón Mis Cómics
            _buildIconButton(
              icon: Icons.folder_open,
              color: const Color(0xFFFFDE59),
              onTap: onOpenProjects,
            ),
            const SizedBox(width: 8),

            // Control Integrado de Páginas (Arriba, sin duplicar indicador)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: controller.activePageIndex > 0
                        ? () => controller.goToPage(controller.activePageIndex - 1)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: controller.activePageIndex > 0 ? Colors.white : Colors.white24,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$currentPage / $totalPages',
                      style: const TextStyle(
                        color: Color(0xFFFFDE59),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.activePageIndex < totalPages - 1
                        ? () => controller.goToPage(controller.activePageIndex + 1)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: controller.activePageIndex < totalPages - 1 ? Colors.white : Colors.white24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.addPage(blank: true),
                    child: Container(
                      margin: const EdgeInsets.only(left: 2),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF39FF14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add, size: 14, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Título editable del cómic
            Flexible(
              child: GestureDetector(
                onTap: () => _showRenameDialog(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            controller.project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 11, color: Color(0xFFFFDE59)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Botón Deshacer
            _buildIconButton(
              icon: Icons.undo,
              color: controller.canUndo ? Colors.white : Colors.white24,
              onTap: controller.canUndo ? controller.undo : () {},
            ),
            const SizedBox(width: 6),

            // Botón Rehacer
            _buildIconButton(
              icon: Icons.redo,
              color: controller.canRedo ? Colors.white : Colors.white24,
              onTap: controller.canRedo ? controller.redo : () {},
            ),
            const Spacer(),

            // Capas de la Página
            if (onToggleLayers != null) ...[
              _buildIconButton(
                icon: Icons.layers,
                color: isLayersOpen ? const Color(0xFF00D4FF) : Colors.white70,
                onTap: onToggleLayers!,
                bg: isLayersOpen ? const Color(0xFF1B2E35) : const Color(0xFF222222),
              ),
              const SizedBox(width: 8),
            ],

            // Modo Lector Manga
            _buildIconButton(
              asset: 'reader_manga',
              icon: Icons.auto_stories,
              color: const Color(0xFF39FF14),
              onTap: onOpenReader,
            ),
            const SizedBox(width: 8),

            // Exportar Cómic
            _buildIconButton(
              icon: Icons.ios_share,
              color: const Color(0xFF00D4FF),
              onTap: onOpenExport,
            ),
            const SizedBox(width: 8),

            // Modo Inmersivo
            _buildIconButton(
              icon: isImmersive ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
              onTap: onToggleImmersive,
            ),
          ],
        ),
      ),
    );
  }
}
