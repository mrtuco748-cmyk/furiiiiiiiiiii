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
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.undo,
                  size: 24,
                  color: controller.canUndo ? Colors.white : Colors.white24,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: controller.canRedo ? controller.redo : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.redo,
                  size: 24,
                  color: controller.canRedo ? Colors.white : Colors.white24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
