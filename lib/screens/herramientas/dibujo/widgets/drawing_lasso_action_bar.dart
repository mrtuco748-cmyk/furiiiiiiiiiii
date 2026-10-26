import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';

/// Barra flotante de acciones para la herramienta de Lazo.
/// Provee acciones directas: Mover, Duplicar, Rellenar, Voltear H, Borrar y Deseleccionar.
class DrawingLassoActionBar extends StatelessWidget {
  final DrawingController controller;

  const DrawingLassoActionBar({
    super.key,
    required this.controller,
  });

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sel = controller.activeSelection;
    if (sel == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de arrastre / mover
          _buildActionButton(
            icon: Icons.open_with,
            label: 'Mover',
            color: const Color(0xFF00D4FF),
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Arrastrá con un dedo dentro de la selección para moverla'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.copy_all,
            label: 'Duplicar',
            onTap: controller.duplicateSelection,
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.format_paint,
            label: 'Rellenar',
            onTap: controller.fillSelection,
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.flip,
            label: 'Voltear H',
            onTap: controller.flipSelectionHorizontal,
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Borrar',
            color: const Color(0xFFFF453A),
            onTap: controller.deleteSelection,
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.close,
            label: 'Listo',
            color: const Color(0xFF30D158),
            onTap: controller.clearSelection,
          ),
        ],
      ),
    );
  }
}
