import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_interaction_mode.dart';
import '../models/comic_panel.dart';

/// Pestaña de Viñetas / Paneles individuales para ComicAddDrawer
class ComicAddPanelsTab extends StatelessWidget {
  final ComicController controller;

  const ComicAddPanelsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Opción destacada principal: Trazar viñeta directamente en la pantalla con el dedo
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: GestureDetector(
            onTap: () {
              controller.setInteractionMode(ComicInteractionMode.drawPanel);
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gesture, color: Colors.black, size: 22),
                  SizedBox(width: 8),
                  Text(
                    '✏️ Trazar Viñeta en Pantalla',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Grilla de formas dinámicas y proporciones rápidas
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemCount: ComicPanelShape.values.length,
            itemBuilder: (context, index) {
              final shape = ComicPanelShape.values[index];
              return GestureDetector(
                onTap: () {
                  controller.addPanel(shape: shape);
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(shape.icon, color: const Color(0xFF00D4FF), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shape.displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
