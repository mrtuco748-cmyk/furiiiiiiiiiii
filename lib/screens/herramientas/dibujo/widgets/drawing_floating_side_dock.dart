import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../../widgets/creative_icon.dart';

/// Dock flotante lateral estilo Procreate:
/// Control inmediato de grosor y opacidad de pincel, y botones de deshacer/rehacer.
/// Cero popups invasivos, interacción fluida al borde del lienzo.
class DrawingFloatingSideDock extends StatefulWidget {
  final DrawingController controller;
  final VoidCallback onResetZoom;

  const DrawingFloatingSideDock({
    super.key,
    required this.controller,
    required this.onResetZoom,
  });

  @override
  State<DrawingFloatingSideDock> createState() => _DrawingFloatingSideDockState();
}

class _DrawingFloatingSideDockState extends State<DrawingFloatingSideDock> {
  bool _isDraggingWidth = false;
  bool _isDraggingOpacity = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;

        return Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Deshacer
              _buildActionButton(
                icon: Icons.undo,
                color: c.canUndo ? Colors.white : Colors.white24,
                onTap: c.canUndo ? c.undo : null,
              ),
              const SizedBox(height: 6),

              // Botón Rehacer
              _buildActionButton(
                icon: Icons.redo,
                color: c.canRedo ? Colors.white : Colors.white24,
                onTap: c.canRedo ? c.redo : null,
              ),
              const SizedBox(height: 6),

              // Botón Ajustar Lienzo al Centro
              _buildActionButton(
                asset: 'canvas_fit',
                fallback: Icons.fit_screen,
                color: const Color(0xFF00D4FF),
                onTap: widget.onResetZoom,
              ),
              const SizedBox(height: 12),

              // Slider vertical de Grosor (Pincel)
              _buildVerticalSlider(
                value: c.strokeWidth,
                min: 1.0,
                max: 60.0,
                iconAsset: 'slider_size',
                fallbackIcon: Icons.line_weight,
                isDragging: _isDraggingWidth,
                activeColor: const Color(0xFF00D4FF),
                onDragStart: () => setState(() => _isDraggingWidth = true),
                onDragEnd: () => setState(() => _isDraggingWidth = false),
                onChanged: (val) => c.setStrokeWidth(val),
              ),
              const SizedBox(height: 12),

              // Slider vertical de Opacidad
              _buildVerticalSlider(
                value: c.strokeOpacity,
                min: 0.05,
                max: 1.0,
                fallbackIcon: Icons.opacity,
                isDragging: _isDraggingOpacity,
                activeColor: const Color(0xFFFF00FF),
                onDragStart: () => setState(() => _isDraggingOpacity = true),
                onDragEnd: () => setState(() => _isDraggingOpacity = false),
                onChanged: (val) => c.setStrokeOpacity(val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    String? asset,
    IconData? fallback,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: asset != null
            ? CreativeIcon(asset, color: color, size: 18, fallback: fallback)
            : Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildVerticalSlider({
    required double value,
    required double min,
    required double max,
    String? iconAsset,
    required IconData fallbackIcon,
    required bool isDragging,
    required Color activeColor,
    required VoidCallback onDragStart,
    required VoidCallback onDragEnd,
    required ValueChanged<double> onChanged,
  }) {
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
    const height = 110.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Indicador emergente lateral cuando se arrastra
        if (isDragging)
          Positioned(
            left: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: max == 60 ? (value / 2).clamp(4.0, 24.0) : 12,
                    height: max == 60 ? (value / 2).clamp(4.0, 24.0) : 12,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: max == 1.0 ? value : 1.0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    max == 1.0 ? '${(value * 100).toInt()}%' : '${value.toInt()}px',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // Barra vertical interactiva
        GestureDetector(
          onVerticalDragStart: (_) => onDragStart(),
          onVerticalDragEnd: (_) => onDragEnd(),
          onVerticalDragUpdate: (details) {
            final dy = details.localPosition.dy;
            // invertido: arriba = más, abajo = menos
            final fraction = (1.0 - (dy / height)).clamp(0.0, 1.0);
            final newValue = min + fraction * (max - min);
            onChanged(newValue);
          },
          child: Container(
            width: 38,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Relleno activo
                Container(
                  height: height * normalized,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Icono representativo
                Positioned(
                  top: 8,
                  child: iconAsset != null
                      ? CreativeIcon(iconAsset, color: Colors.white70, size: 16, fallback: fallbackIcon)
                      : Icon(fallbackIcon, color: Colors.white70, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
