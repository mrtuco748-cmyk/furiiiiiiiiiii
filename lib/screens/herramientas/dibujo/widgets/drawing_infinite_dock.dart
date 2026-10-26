import 'package:flutter/material.dart';
import '../../widgets/creative_icon.dart';
import '../controllers/drawing_controller.dart';
import '../models/drawing_tool_type.dart';

/// Dock flotante lateral estilo Infinite Painter:
/// Pincel, Dedo (Difuminar), Borrador, Círculo de Grosor, Círculo de Color y Círculo de Opacidad.
class DrawingInfiniteDock extends StatefulWidget {
  final DrawingController controller;
  final VoidCallback onToggleColorPopover;
  final VoidCallback? onToggleBrushPopover;

  const DrawingInfiniteDock({
    super.key,
    required this.controller,
    required this.onToggleColorPopover,
    this.onToggleBrushPopover,
  });

  @override
  State<DrawingInfiniteDock> createState() => _DrawingInfiniteDockState();
}

class _DrawingInfiniteDockState extends State<DrawingInfiniteDock> {
  bool _isDraggingSize = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final isBrush = !c.selectedTool.isEraser;
        final isEraser = c.selectedTool.isEraser;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            // Pastilla vertical flotante Infinite Painter (docked to left edge)
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Pincel
                  _buildToolButton(
                    icon: Icons.brush,
                    isActive: isBrush,
                    tooltip: c.selectedTool.displayName,
                    onTap: () {
                      if (!isBrush) {
                        c.selectTool(c.previousDrawingTool);
                      } else {
                        widget.onToggleBrushPopover?.call();
                      }
                    },
                    onLongPress: widget.onToggleBrushPopover,
                  ),
                  const SizedBox(height: 8),

                  // 2. Borrador
                  _buildToolButton(
                    customIcon: CreativeIcon(
                      'eraser',
                      color: isEraser ? Colors.white : Colors.white54,
                      size: 20,
                      fallback: Icons.cleaning_services,
                    ),
                    isActive: isEraser,
                    tooltip: 'Borrador',
                    onTap: () => c.toggleTool(DrawingToolType.eraser),
                  ),
                  const SizedBox(height: 10),

                  // 3. Círculo Indicador de Grosor
                  _buildSizeCircle(c),
                  const SizedBox(height: 8),

                  // 4. Círculo Indicador de Color
                  _buildColorCircle(c),
                ],
              ),
            ),

            // Burbuja emergente de tamaño mientras se arrastra
            if (_isDraggingSize)
              Positioned(
                left: 68,
                top: 130,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: (c.strokeWidth / 2).clamp(4.0, 24.0),
                        height: (c.strokeWidth / 2).clamp(4.0, 24.0),
                        decoration: BoxDecoration(
                          color: c.selectedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${c.strokeWidth.toStringAsFixed(1)} px',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildToolButton({
    IconData? icon,
    Widget? customIcon,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    String? tooltip,
  }) {
    Widget btn = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF333333) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: customIcon ??
              (icon != null
                  ? Icon(
                      icon,
                      size: 20,
                      color: isActive ? Colors.white : Colors.white54,
                    )
                  : const SizedBox.shrink()),
        ),
      ),
    );
    if (tooltip != null) {
      btn = Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }

  Widget _buildSizeCircle(DrawingController c) {
    return GestureDetector(
      onVerticalDragStart: (_) => setState(() => _isDraggingSize = true),
      onVerticalDragEnd: (_) => setState(() => _isDraggingSize = false),
      onVerticalDragUpdate: (d) {
        final newWidth = (c.strokeWidth - d.delta.dy * 0.4).clamp(1.0, 60.0);
        c.setStrokeWidth(newWidth);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: (c.strokeWidth * 0.5).clamp(4.0, 24.0),
            height: (c.strokeWidth * 0.5).clamp(4.0, 24.0),
            decoration: const BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorCircle(DrawingController c) {
    return GestureDetector(
      onTap: widget.onToggleColorPopover,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: c.selectedColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
