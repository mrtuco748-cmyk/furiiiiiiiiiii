import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../models/canvas_background_type.dart';
import 'drawing_layer_options_sheet.dart';

/// Dock lateral vertical de capas estilo Infinite Painter:
/// Botón +, lista reordenable de capas por arrastre, opciones completas de opacidad y fondo.
class DrawingLayersDock extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback onClose;

  const DrawingLayersDock({
    super.key,
    required this.controller,
    required this.onClose,
  });

  void _cycleBackground() {
    final values = CanvasBackgroundType.values;
    final currentIndex = values.indexOf(controller.backgroundType);
    final nextIndex = (currentIndex + 1) % values.length;
    controller.setBackgroundType(values[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layers = controller.layers;
        final activeIndex = controller.activeLayerIndex;

        return Container(
          width: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          child: SafeArea(
            top: true,
            bottom: true,
            child: Column(
              children: [
                // 0. Botón cerrar dock
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 4, right: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, color: Colors.white70, size: 16),
                    ),
                  ),
                ),

                // 1. Botón superior "+" para agregar capa
                GestureDetector(
                  onTap: () => controller.addLayer(),
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),

                const Divider(color: Color(0xFF333333), height: 1),

                // 2. Lista reordenable vertical de miniaturas de capa (arrastre con dedo)
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: layers.length,
                    buildDefaultDragHandles: true,
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      final dataOldIndex = layers.length - 1 - oldIndex;
                      final dataNewIndex = layers.length - newIndex;
                      controller.reorderLayers(dataOldIndex, dataNewIndex);
                    },
                    itemBuilder: (context, index) {
                      final reverseIndex = layers.length - 1 - index;
                      final layer = layers[reverseIndex];
                      final isActive = activeIndex == reverseIndex;
                      final opacityPct = (layer.opacity * 100).round();

                      return Container(
                        key: ValueKey(layer.id),
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF00D4FF) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GestureDetector(
                          onTap: () => controller.setActiveLayer(reverseIndex),
                          onDoubleTap: () => DrawingLayerOptionsSheet.show(context, controller, reverseIndex),
                          onLongPress: () => DrawingLayerOptionsSheet.show(context, controller, reverseIndex),
                          child: Stack(
                            children: [
                              // Miniatura / Icono de capa estilo papel
                              Center(
                                child: Text(
                                  'C${reverseIndex + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.black : Colors.black38,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Candado si está bloqueada
                              if (layer.isLocked)
                                const Positioned(
                                  top: 3,
                                  left: 3,
                                  child: Icon(Icons.lock, size: 11, color: Colors.black45),
                                ),

                              // Toggle visibilidad (Ojo en la esquina superior derecha)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => controller.toggleLayerVisibility(reverseIndex),
                                  child: Icon(
                                    layer.isVisible ? Icons.visibility : Icons.visibility_off,
                                    size: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),

                              // Porcentaje de opacidad (Esquina inferior izquierda - tap abre opciones)
                              Positioned(
                                bottom: 2,
                                left: 4,
                                child: GestureDetector(
                                  onTap: () => DrawingLayerOptionsSheet.show(context, controller, reverseIndex),
                                  child: Text(
                                    '$opacityPct%',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(color: Color(0xFF333333), height: 1),

                // 3. Círculo inferior de fondo (Tap cicla el tipo de lienzo)
                GestureDetector(
                  onTap: _cycleBackground,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: controller.backgroundType.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
