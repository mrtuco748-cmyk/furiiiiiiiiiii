import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/drawing_controller.dart';

/// Modal para gestionar el sistema de capas del lienzo de dibujo.
class DrawingLayersSheet extends StatelessWidget {
  final DrawingController controller;

  const DrawingLayersSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layers = controller.layers;
        final reversedIndices = List.generate(layers.length, (i) => layers.length - 1 - i);

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle superior
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Encabezado
                Row(
                  children: [
                    Text(
                      'CAPAS (${layers.length})',
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => controller.addLayer(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, size: 18, color: Color(0xFF111111)),
                            const SizedBox(width: 4),
                            Text(
                              'NUEVA',
                              style: GoogleFonts.bangers(
                                color: const Color(0xFF111111),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Lista de capas (la de arriba en la pantalla es la superior en el lienzo)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: reversedIndices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final originalIndex = reversedIndices[i];
                      final layer = layers[originalIndex];
                      final isActive = controller.activeLayerIndex == originalIndex;

                      return GestureDetector(
                        onTap: () => controller.setActiveLayer(originalIndex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Ojito Visibilidad
                                  GestureDetector(
                                    onTap: () => controller.toggleLayerVisibility(originalIndex),
                                    child: Icon(
                                      layer.isVisible ? Icons.visibility : Icons.visibility_off,
                                      size: 20,
                                      color: layer.isVisible ? const Color(0xFF00D4FF) : const Color(0xFF555555),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      layer.name,
                                      style: TextStyle(
                                        color: layer.isVisible ? Colors.white : Colors.white38,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  // Trazo count badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141414),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${layer.strokes.length} trazos',
                                      style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Botón Borrar capa
                                  if (layers.length > 1)
                                    GestureDetector(
                                      onTap: () => controller.removeLayer(originalIndex),
                                      child: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Color(0xFFFF5252),
                                      ),
                                    ),
                                ],
                              ),
                              // Slider de Opacidad de la Capa
                              Row(
                                children: [
                                  const Text(
                                    'Opacidad:',
                                    style: TextStyle(color: Color(0xFF777777), fontSize: 12),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: const Color(0xFF00D4FF),
                                        inactiveTrackColor: const Color(0xFF333333),
                                        thumbColor: Colors.white,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                      ),
                                      child: Slider(
                                        value: layer.opacity.clamp(0.0, 1.0),
                                        min: 0.0,
                                        max: 1.0,
                                        onChanged: (val) => controller.setLayerOpacity(originalIndex, val),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(layer.opacity * 100).toInt()}%',
                                    style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
