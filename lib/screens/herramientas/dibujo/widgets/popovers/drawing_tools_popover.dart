import 'package:flutter/material.dart';
import '../../controllers/drawing_controller.dart';
import '../../models/drawing_symmetry_mode.dart';
import '../../models/drawing_tool_type.dart';

/// Popover de Herramientas de Infinite Painter (Screenshot 1)
class DrawingToolsPopover extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback onResetZoom;
  final VoidCallback onClose;

  const DrawingToolsPopover({
    super.key,
    required this.controller,
    required this.onResetZoom,
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
        Wrap(
          spacing: 6,
          runSpacing: 8,
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
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF333333) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF00D4FF) : Colors.white70, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00D4FF) : Colors.white70,
                fontSize: 10,
              ),
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
            // Herramientas
            _buildSection('Herramientas', [
              _buildItem(
                icon: Icons.gesture,
                label: 'Lazo',
                isSelected: controller.selectedTool == DrawingToolType.lasso,
                onTap: () {
                  controller.toggleTool(DrawingToolType.lasso);
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.format_paint,
                label: 'Rellenar',
                isSelected: controller.selectedTool == DrawingToolType.bucketFill,
                onTap: () {
                  controller.toggleTool(DrawingToolType.bucketFill);
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.gradient,
                label: 'Degradado',
                isSelected: controller.selectedTool == DrawingToolType.gradient,
                onTap: () {
                  controller.toggleTool(DrawingToolType.gradient);
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.texture,
                label: 'Trama Manga',
                isSelected: controller.selectedTool == DrawingToolType.screentone,
                onTap: () {
                  controller.toggleTool(DrawingToolType.screentone);
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.copy_all,
                label: 'Clonar Capa',
                onTap: () { controller.duplicateActiveLayer(); onClose(); },
              ),
            ]),

            // Formas
            _buildSection('Formas', [
              _buildItem(
                icon: Icons.horizontal_rule,
                label: 'Línea',
                isSelected: controller.selectedTool == DrawingToolType.line,
                onTap: () {
                  controller.toggleTool(DrawingToolType.line);
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.crop_square,
                label: 'Rectángulo',
                isSelected: controller.selectedTool == DrawingToolType.rectangle,
                onTap: () {
                  controller.toggleTool(DrawingToolType.rectangle);
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.radio_button_unchecked,
                label: 'Círculo',
                isSelected: controller.selectedTool == DrawingToolType.circle,
                onTap: () {
                  controller.toggleTool(DrawingToolType.circle);
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.timeline,
                label: 'Trayectoria',
                isSelected: controller.selectedTool == DrawingToolType.trajectory,
                onTap: () {
                  controller.toggleTool(DrawingToolType.trajectory);
                  onClose();
                },
              ),
            ]),

            // Simetría
            _buildSection('Simetría', [
              _buildItem(
                icon: Icons.vertical_split,
                label: 'Vertical',
                isSelected: controller.symmetryMode == DrawingSymmetryMode.vertical,
                onTap: () {
                  controller.setSymmetryMode(
                    controller.symmetryMode == DrawingSymmetryMode.vertical
                        ? DrawingSymmetryMode.none
                        : DrawingSymmetryMode.vertical,
                  );
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.horizontal_split,
                label: 'Horizontal',
                isSelected: controller.symmetryMode == DrawingSymmetryMode.horizontal,
                onTap: () {
                  controller.setSymmetryMode(
                    controller.symmetryMode == DrawingSymmetryMode.horizontal
                        ? DrawingSymmetryMode.none
                        : DrawingSymmetryMode.horizontal,
                  );
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.auto_awesome,
                label: 'Radial',
                isSelected: controller.symmetryMode == DrawingSymmetryMode.radial4,
                onTap: () {
                  controller.setSymmetryMode(
                    controller.symmetryMode == DrawingSymmetryMode.radial4
                        ? DrawingSymmetryMode.none
                        : DrawingSymmetryMode.radial4,
                  );
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.flare,
                label: 'Caleidoscopio',
                isSelected: controller.symmetryMode == DrawingSymmetryMode.kaleidoscope,
                onTap: () {
                  controller.setSymmetryMode(
                    controller.symmetryMode == DrawingSymmetryMode.kaleidoscope
                        ? DrawingSymmetryMode.none
                        : DrawingSymmetryMode.kaleidoscope,
                  );
                  onClose();
                },
              ),
            ]),

            // Cámara
            _buildSection('Cámara', [
              _buildItem(
                icon: Icons.fit_screen,
                label: 'Encajar',
                onTap: () {
                  onResetZoom();
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.flip,
                label: 'Voltear',
                isSelected: controller.isFlippedHorizontal,
                onTap: () {
                  controller.flipCanvasHorizontal();
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.lock_outline,
                label: 'Bloquear',
                isSelected: controller.isRotationLocked,
                onTap: () {
                  controller.toggleRotationLock();
                  onClose();
                },
              ),
              _buildItem(
                icon: Icons.explore_outlined,
                label: 'Centrar',
                onTap: () {
                  onResetZoom();
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
