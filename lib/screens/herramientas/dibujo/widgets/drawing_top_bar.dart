import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';

/// Barra superior flotante estilo Infinite Painter (Screenshots 1, 2, 3, 4, 5):
/// Botón Home/Atrás a la izquierda, título de proyecto editable en el centro,
/// y herramientas, edición, capas y opciones a la derecha.
class DrawingTopBar extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback onToggleTools;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleLayers;
  final VoidCallback onToggleOptions;
  final VoidCallback onOpenProjects;
  final VoidCallback onExport;
  final VoidCallback onToggleImmersive;
  final VoidCallback? onBack;
  final bool isImmersive;
  final bool isLayersOpen;

  const DrawingTopBar({
    super.key,
    required this.controller,
    required this.onToggleTools,
    required this.onToggleEdit,
    required this.onToggleLayers,
    required this.onToggleOptions,
    required this.onOpenProjects,
    required this.onExport,
    required this.onToggleImmersive,
    this.onBack,
    this.isImmersive = false,
    this.isLayersOpen = false,
  });

  Future<void> _showRenameDialog(BuildContext context) async {
    final textController = TextEditingController(text: controller.projectTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF00D4FF), size: 20),
            SizedBox(width: 8),
            Text('Nombre del Proyecto', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Ej. Mi nuevo dibujo',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF282828),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final trimmed = textController.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(ctx).pop(trimmed);
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      controller.setTitle(newTitle);
    }
  }

  Widget _buildTopButton({
    required Widget child,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Botón Home (extremo izquierdo)
            _buildTopButton(
              child: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
              onTap: onBack ?? () => Navigator.of(context).pop(),
            ),

            const SizedBox(width: 8),

            // Badge interactivo para ver y renombrar el proyecto directamente
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => _showRenameDialog(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              controller.projectTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit, size: 12, color: Color(0xFF00D4FF)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 1. Icono Compás / Herramientas
            _buildTopButton(
              child: const Icon(Icons.architecture, color: Colors.white, size: 22),
              onTap: onToggleTools,
            ),
            const SizedBox(width: 8),

            // 2. Icono Transformar / Editar
            _buildTopButton(
              child: const Icon(Icons.crop_free, color: Colors.white, size: 22),
              onTap: onToggleEdit,
            ),
            const SizedBox(width: 8),

            // 3. Icono Capas
            _buildTopButton(
              isSelected: isLayersOpen,
              child: Icon(
                Icons.layers,
                color: isLayersOpen ? const Color(0xFF00D4FF) : Colors.white,
                size: 22,
              ),
              onTap: onToggleLayers,
            ),
            const SizedBox(width: 8),

            // 4. Más Opciones
            _buildTopButton(
              child: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
              onTap: onToggleOptions,
            ),
          ],
        ),
      ),
    );
  }
}
