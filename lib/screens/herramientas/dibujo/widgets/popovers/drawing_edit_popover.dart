import 'package:flutter/material.dart';
import '../../controllers/drawing_controller.dart';

/// Popover de Transformar y Selección de Infinite Painter (Screenshot 2)
class DrawingEditPopover extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback onClose;

  const DrawingEditPopover({
    super.key,
    required this.controller,
    required this.onClose,
  });

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Transformar
            _buildSection('Transformar', [
              _buildItem(
                icon: Icons.flip,
                label: 'Voltear H',
                onTap: () {
                  controller.flipCanvasHorizontal();
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.swap_vert,
                label: 'Voltear V',
                onTap: () {
                  controller.flipCanvasVertical();
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.rotate_right,
                label: 'Rotar 90°',
                onTap: () {
                  controller.rotateActiveLayer90();
                  onClose();
                },
              ),
              _buildItem(
                icon: controller.isRotationLocked ? Icons.screen_lock_rotation : Icons.screen_rotation,
                label: controller.isRotationLocked ? 'Giro Fijo' : 'Giro Libre',
                onTap: () {
                  controller.toggleRotationLock();
                  onClose();
                },
              ),
            ]),

            // Editar Capa
            _buildSection('Editar Capa', [
              _buildItem(
                icon: Icons.layers_clear,
                label: 'Limpiar',
                onTap: () {
                  controller.clearActiveLayer();
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.copy_all,
                label: 'Duplicar',
                onTap: () {
                  controller.duplicateActiveLayer();
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.invert_colors,
                label: 'Invertir',
                onTap: () {
                  controller.invertActiveLayerColors();
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.delete_outline,
                label: 'Borrar Capa',
                onTap: () {
                  controller.removeLayer(controller.activeLayerIndex);
                  onClose();
                },
              ),
            ]),

            // Lienzo
            _buildSection('Lienzo', [
              _buildItem(
                icon: Icons.aspect_ratio,
                label: 'Hoja Manga',
                onTap: () {
                  controller.setCanvasSize(const Size(1200, 1697));
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.crop_square,
                label: 'Cuadrado',
                onTap: () {
                  controller.setCanvasSize(const Size(1080, 1080));
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.stay_current_portrait,
                label: 'Webtoon',
                onTap: () {
                  controller.setCanvasSize(const Size(1080, 1920));
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.fit_screen,
                label: 'HD 16:9',
                onTap: () {
                  controller.setCanvasSize(const Size(1920, 1080));
                  onClose();
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
