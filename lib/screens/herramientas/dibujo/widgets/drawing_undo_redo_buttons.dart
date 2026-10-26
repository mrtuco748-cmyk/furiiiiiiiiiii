import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';

/// Botones flotantes de Deshacer y Rehacer en la esquina inferior izquierda (Screenshot 4).
class DrawingUndoRedoButtons extends StatelessWidget {
  final DrawingController controller;

  const DrawingUndoRedoButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: controller.canUndo ? controller.undo : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: controller.canUndo ? const Color(0xFF262626) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.undo,
                  size: 20,
                  color: controller.canUndo ? const Color(0xFFE5E5E5) : const Color(0xFF555555),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: controller.canRedo ? controller.redo : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: controller.canRedo ? const Color(0xFF262626) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.redo,
                  size: 20,
                  color: controller.canRedo ? const Color(0xFFE5E5E5) : const Color(0xFF555555),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
