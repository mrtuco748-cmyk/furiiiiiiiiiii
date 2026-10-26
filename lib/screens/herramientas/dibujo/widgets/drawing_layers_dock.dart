import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../models/canvas_background_type.dart';

/// Dock lateral vertical de capas estilo Infinite Painter (Screenshot 5):
/// Botón +, lista de miniaturas de capas con ojo y porcentaje de opacidad, y selector de fondo inferior.
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

  void _showLayerOptions(BuildContext context, int index) {
    final layer = controller.layers[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(layer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFFF453A)),
              title: const Text('Eliminar Capa', style: TextStyle(color: Color(0xFFFF453A))),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.removeLayer(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layers = controller.layers;
        final activeIndex = controller.activeLayerIndex;

        return Container(
          width: 68,
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

                // 2. Lista vertical de miniaturas de capa
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: layers.length,
                    itemBuilder: (context, index) {
                      // Se muestran de arriba a abajo (las capas superiores primero)
                      final reverseIndex = layers.length - 1 - index;
                      final layer = layers[reverseIndex];
                      final isActive = activeIndex == reverseIndex;
                      final opacityPct = (layer.opacity * 100).round();

                      return GestureDetector(
                        onTap: () => controller.setActiveLayer(reverseIndex),
                        onLongPress: () => _showLayerOptions(context, reverseIndex),
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF00D4FF) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              // Miniatura / Icono de capa estilo papel blanco (Screenshot 5)
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

                              // Porcentaje de opacidad (Esquina inferior izquierda)
                              Positioned(
                                bottom: 2,
                                left: 4,
                                child: Text(
                                  '$opacityPct%',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
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
