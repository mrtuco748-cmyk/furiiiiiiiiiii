import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_interaction_mode.dart';

/// Banner flotante indicador del modo de interacción activo (trazar viñeta, cortar panel o encuadrar lienzo)
class ComicModeIndicatorBanner extends StatelessWidget {
  final ComicController controller;

  const ComicModeIndicatorBanner({super.key, required this.controller});

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 15, color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.interactionMode == ComicInteractionMode.normal) {
          return const SizedBox.shrink();
        }

        final mode = controller.interactionMode;

        // Barra de herramientas táctil dedicada para Encuadre de Viñeta
        if (mode == ComicInteractionMode.frameContent && controller.selectedPanel != null) {
          final p = controller.selectedPanel!;
          return Positioned(
            top: 60,
            left: 10,
            right: 10,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF00FF),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.crop, size: 16, color: Colors.black),
                      const SizedBox(width: 6),
                      const Text('Encuadre', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      _buildCircleBtn(Icons.remove, () {
                        controller.setPanelTransform(p.id, scale: (p.scale - 0.15).clamp(0.2, 5.0));
                      }),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => controller.setPanelTransform(p.id, scale: 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(6)),
                          child: Text('${(p.scale * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildCircleBtn(Icons.add, () {
                        controller.setPanelTransform(p.id, scale: (p.scale + 0.15).clamp(0.2, 5.0));
                      }),
                      const SizedBox(width: 6),
                      _buildCircleBtn(Icons.filter_center_focus, () {
                        controller.setPanelTransform(p.id, dx: 0, dy: 0);
                      }),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => controller.setInteractionMode(ComicInteractionMode.normal),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 13, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Listo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final (bgColor, text, icon) = switch (mode) {
          ComicInteractionMode.drawPanel => (
            const Color(0xFF00D4FF),
            'Arrastrá con el dedo para trazar la viñeta',
            Icons.gesture,
          ),
          ComicInteractionMode.slicePanel => (
            const Color(0xFFFF453A),
            'Trazá una línea para cortar la viñeta',
            Icons.content_cut,
          ),
          ComicInteractionMode.frameContent => (
            const Color(0xFFFF00FF),
            'Encuadre: Arrastrá para mover, pellizcá para zoom',
            Icons.crop,
          ),
          _ => (const Color(0xFF00D4FF), '', Icons.info),
        };

        return Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.setInteractionMode(ComicInteractionMode.normal),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        mode.isFrameContent ? Icons.check : Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
