import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models/note_style_config.dart';
import '../painters/note_card_painter.dart';
import '../painters/note_shape_utils.dart';
import 'pizarron_resize_handle.dart';

/// Marco vectorial y visual multicapa de una tarjeta de nota en el Pizarrón.
class PizarronCardFrame extends StatelessWidget {
  final Size size;
  final NoteStyleConfig cfg;
  final bool isEditing;
  final Uint8List? cachedBgBytes;
  final AnimationController shineController;
  final Widget child;
  final double Function() getCurrentCanvasScale;
  final void Function(double dwWorld, double dhWorld) onResizeNote;

  const PizarronCardFrame({
    super.key,
    required this.size,
    required this.cfg,
    required this.isEditing,
    required this.cachedBgBytes,
    required this.shineController,
    required this.child,
    required this.getCurrentCanvasScale,
    required this.onResizeNote,
  });

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;
    final contentPadding =
        NoteShapeUtils.getContentPadding(cfg.shapeType, size);
    final handleCenter =
        NoteShapeUtils.getResizeHandleCenter(cfg.shapeType, size);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (cfg.baseMode == 'image' && cachedBgBytes != null)
            Positioned.fill(
              child: ClipPath(
                clipper: NoteShapeClipper(cfg.shapeType),
                child: Opacity(
                  opacity: cfg.bgImageOpacity.clamp(0.1, 1.0),
                  child: Image.memory(
                    cachedBgBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: shineController,
              builder: (context, childWidget) {
                return CustomPaint(
                  painter: NoteCardPainter(
                    config: cfg,
                    shineProgress: shineController.value,
                    isEditing: isEditing,
                  ),
                  child: childWidget,
                );
              },
              child: ClipPath(
                clipper: NoteShapeClipper(
                  cfg.shapeType,
                  inset: cfg.borderType == NoteBorderType.none
                      ? 2.0
                      : cfg.borderWidth + 2.0,
                ),
                child: Padding(
                  padding: contentPadding,
                  child: child,
                ),
              ),
            ),
          ),
          Positioned(
            left: handleCenter.dx - 16,
            top: handleCenter.dy - 16,
            width: 32,
            height: 32,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                final scale = getCurrentCanvasScale();
                final safeScale = scale <= 0.001 ? 1.0 : scale;
                onResizeNote(
                  details.delta.dx / safeScale,
                  details.delta.dy / safeScale,
                );
              },
              child: CustomPaint(
                painter: PizarronAdaptiveResizeCornerPainter(
                  color: PizarronPalette.parseHex(cfg.titleColor)
                      .withValues(alpha: 0.55),
                  shape: cfg.shapeType,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
