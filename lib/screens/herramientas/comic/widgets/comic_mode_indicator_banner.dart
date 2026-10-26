import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_interaction_mode.dart';

/// Banner flotante indicador del modo de interacción activo (trazar viñeta o cortar panel)
class ComicModeIndicatorBanner extends StatelessWidget {
  final ComicController controller;

  const ComicModeIndicatorBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.interactionMode == ComicInteractionMode.normal) {
      return const SizedBox.shrink();
    }

    final mode = controller.interactionMode;
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
  }
}
