import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../models/canvas_background_type.dart';
import 'drawing_layer_options_sheet.dart';

/// Dock lateral vertical de capas estilo Infinite Painter / Procreate:
/// Cómodo y táctil para celular, con arrastre directo por manija (ReorderableDragStartListener),
/// selección de capa activa, visor de opacidad, visibilidad y modal de opciones completas.
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
          width: 164,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            border: Border.all(color: const Color(0xFF333333), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: SafeArea(
            top: true,
            bottom: true,
            left: false,
            right: false,
            child: Column(
              children: [
                // Cabecera: Botón Agregar Capa + Título + Botón Cerrar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      // Botón "+" para agregar capa
                      GestureDetector(
                        onTap: () => controller.addLayer(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, color: Color(0xFF00D4FF), size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'CAPAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Botón cerrar dock
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF282828),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.close, color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0xFF333333), height: 1),

                // Lista reordenable vertical de capas con arrastre directo por manija táctil
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: layers.length,
                    buildDefaultDragHandles: false,
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      controller.reorderLayers(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final reverseIndex = layers.length - 1 - index;
                      final layer = layers[reverseIndex];
                      final isActive = activeIndex == reverseIndex;
                      final opacityPct = (layer.opacity * 100).round();

                      return Container(
                        key: ValueKey(layer.id),
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF1B2E35) : const Color(0xFF262626),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? const Color(0xFF00D4FF) : const Color(0xFF383838),
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Indicador lateral cian de capa activa
                            Container(
                              width: 3,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF00D4FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Badge identificador C1, C2...
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF00D4FF) : const Color(0xFF333333),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'C${reverseIndex + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.black : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Área de selección y nombre de la capa
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => controller.setActiveLayer(reverseIndex),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        layer.name.isNotEmpty ? layer.name : 'Capa ${reverseIndex + 1}',
                                        style: TextStyle(
                                          color: isActive ? Colors.white : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$opacityPct%',
                                        style: TextStyle(
                                          color: isActive ? const Color(0xFF00D4FF) : Colors.white38,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Ojo: toggle visibilidad
                            GestureDetector(
                              onTap: () => controller.toggleLayerVisibility(reverseIndex),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  layer.isVisible ? Icons.visibility : Icons.visibility_off,
                                  size: 16,
                                  color: layer.isVisible ? Colors.white70 : Colors.white30,
                                ),
                              ),
                            ),
                            // Opciones de capa (opacidad, duplicar, fusionar, eliminar)
                            GestureDetector(
                              onTap: () => DrawingLayerOptionsSheet.show(context, controller, reverseIndex),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.tune, size: 16, color: Colors.white70),
                              ),
                            ),
                            // Manija de arrastre táctil directo sin retraso ni long press
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                color: Colors.transparent,
                                child: const Icon(Icons.drag_handle, color: Colors.white54, size: 18),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const Divider(color: Color(0xFF333333), height: 1),

                // Círculo inferior de fondo (Tap cicla el tipo de lienzo)
                GestureDetector(
                  onTap: _cycleBackground,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: controller.backgroundType.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Fondo',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
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
