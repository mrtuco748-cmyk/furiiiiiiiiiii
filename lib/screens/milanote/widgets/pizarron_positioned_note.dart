import 'package:flutter/material.dart';
import '../../../models/board_element.dart';
import '../../../providers/board_data_provider.dart';
import '../models/note_style_config.dart';
import 'pizarron_note_widget.dart';

/// Elemento posicionado en coordenadas de mundo dentro del lienzo infinito.
class PizarronPositionedNote extends StatelessWidget {
  final BoardElement el;
  final bool isEditing;
  final double cameraScale;
  final ActiveTextTarget activeTextTarget;
  final BoardDataProvider provider;
  final void Function(ActiveTextTarget target) onActiveTargetChanged;
  final void Function(ActiveTextTarget target) onFocusAndEdit;

  const PizarronPositionedNote({
    super.key,
    required this.el,
    required this.isEditing,
    required this.cameraScale,
    required this.activeTextTarget,
    required this.provider,
    required this.onActiveTargetChanged,
    required this.onFocusAndEdit,
  });

  @override
  Widget build(BuildContext context) {
    final styleConfig = NoteStyleConfig.fromElement(
      fallbackColor: el.color,
      data: el.data,
    );

    return Positioned(
      key: ValueKey('pizarron_el_${el.id}'),
      left: el.x,
      top: el.y,
      width: el.width,
      height: el.height,
      child: RepaintBoundary(
        child: PizarronNoteWidget(
          element: el,
          styleConfig: styleConfig,
          isEditing: isEditing,
          getCurrentCanvasScale: () => cameraScale,
          activeTarget: isEditing
              ? activeTextTarget
              : const ActiveTextTarget.bodyDefault(),
          onActiveTargetChanged: (target) {
            if (isEditing) onActiveTargetChanged(target);
          },
          onTapNote: () {
            if (!isEditing) onFocusAndEdit(const ActiveTextTarget.bodyDefault());
          },
          onTapWithTarget: (target) {
            if (!isEditing) {
              onFocusAndEdit(target);
            } else {
              onActiveTargetChanged(target);
            }
          },
          onDragNote: (dx, dy) {
            if (el.id != null) {
              provider.updatePositionLocal(el.id!, el.x + dx, el.y + dy);
            }
          },
          onResizeNote: (dw, dh) {
            if (el.id != null) {
              provider.updateGeometryLocal(
                el.id!,
                width: (el.width + dw).clamp(130.0, 950.0),
                height: (el.height + dh).clamp(110.0, 950.0),
              );
            }
          },
          onPinchScaleNote: (scaleFactor, focalWorld) {},
          onTextChanged: (newTitle, newContent) {
            provider.updateElement(
              el.copyWith(title: newTitle, content: newContent),
            );
          },
          onStyleChanged: (updatedCfg) {
            provider.updateElement(
              el.copyWith(
                color: updatedCfg.solidColor,
                data: updatedCfg.toDataMap(),
              ),
            );
          },
        ),
      ),
    );
  }
}
