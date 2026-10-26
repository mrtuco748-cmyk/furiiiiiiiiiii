import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../../widgets/creative_icon.dart';

/// Panel flotante compacto y no invasivo para gestión de capas.
class DrawingFloatingLayersCard extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback onClose;

  const DrawingFloatingLayersCard({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final layers = controller.layers;

    return Container(
      width: 210,
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera con añadir capa y cerrar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  CreativeIcon('layers', color: Color(0xFF00D4FF), size: 16),
                  SizedBox(width: 6),
                  Text('CAPAS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.addLayer(),
                    child: const Icon(Icons.add, color: Color(0xFF39FF14), size: 18),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Lista de capas
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: layers.length,
              itemBuilder: (context, index) {
                // Invertido para que la capa superior aparezca arriba
                final reversedIndex = layers.length - 1 - index;
                final layer = layers[reversedIndex];
                final isActive = controller.activeLayerIndex == reversedIndex;

                return GestureDetector(
                  onTap: () => controller.setActiveLayer(reversedIndex),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2C2C2E) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Visibilidad
                        GestureDetector(
                          onTap: () => controller.toggleLayerVisibility(reversedIndex),
                          child: Icon(
                            layer.isVisible ? Icons.visibility : Icons.visibility_off,
                            color: layer.isVisible ? const Color(0xFF00D4FF) : Colors.white24,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nombre
                        Expanded(
                          child: Text(
                            layer.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white70,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Eliminar si hay más de 1 capa
                        if (layers.length > 1)
                          GestureDetector(
                            onTap: () => controller.removeLayer(reversedIndex),
                            child: const Icon(Icons.delete_outline, color: Color(0xFFFF453A), size: 16),
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
    );
  }
}
