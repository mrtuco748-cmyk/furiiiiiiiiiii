import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../models/drawing_tool_type.dart';
import '../../widgets/creative_icon.dart';

/// Barra flotante inferior de herramientas de dibujo:
/// Diseño no invasivo, compacto, sólo iconos sin texto y acceso inmediato.
class DrawingBottomToolbar extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback onToggleColorPopover;
  final VoidCallback onToggleLayersCard;

  const DrawingBottomToolbar({
    super.key,
    required this.controller,
    required this.onToggleColorPopover,
    required this.onToggleLayersCard,
  });

  Widget _buildToolItem({
    required DrawingToolType tool,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color bg = const Color(0xFF222222);
    Color fg = Colors.white70;

    if (isSelected) {
      bg = const Color(0xFF00D4FF);
      fg = Colors.black;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: CreativeIcon(
          tool.svgAsset,
          size: 18,
          color: fg,
          fallback: tool.icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF181818).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector horizontal de herramientas (Iconos solos, cero texto)
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DrawingToolType.pen,
                      DrawingToolType.pencil,
                      DrawingToolType.marker,
                      DrawingToolType.highlighter,
                      DrawingToolType.airbrush,
                      DrawingToolType.line,
                      DrawingToolType.eraser,
                    ].map((tool) {
                      final isSelected = controller.selectedTool == tool;
                      return _buildToolItem(
                        tool: tool,
                        isSelected: isSelected,
                        onTap: () => (tool.isEraser || tool.isShape || tool.isLasso || tool.isFill)
                            ? controller.toggleTool(tool)
                            : controller.selectTool(tool),
                      );
                    }).toList(),
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: const Color(0xFF333333),
              ),

              // Botón Color Activo
              GestureDetector(
                onTap: onToggleColorPopover,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: controller.selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botón Capas (Layers)
              GestureDetector(
                onTap: onToggleLayersCard,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const CreativeIcon(
                    'layers',
                    color: Color(0xFF00D4FF),
                    size: 18,
                    fallback: Icons.layers,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
