import 'package:flutter/material.dart';
import '../../comic/models/comic_panel.dart';
import '../controllers/drawing_controller.dart';
import '../models/drawing_symmetry_mode.dart';
import '../painters/drawing_canvas_painter.dart';
import '../painters/drawing_cursor_painter.dart';
import '../painters/drawing_panel_guide_painter.dart';

/// Widget de renderizado de la hoja de lienzo de dibujo digital:
/// - Fondo blanco con sombra de elevación
/// - Inversión horizontal/vertical reactiva
/// - Renderizado multicapa con trazado vectorial
/// - Retícula en vivo de tamaño de pincel (Brush cursor)
/// - Guía vectorial de panel de cómic opcional
class DrawingCanvasPaper extends StatelessWidget {
  final GlobalKey canvasKey;
  final DrawingController controller;
  final Size canvasSize;
  final ComicPanelShape? panelGuideShape;
  final List<Offset>? panelGuidePolygon;
  final double panelGuideBorderRadius;
  final bool showPanelGuide;
  final Offset? cursorPosition;
  final bool isCursorVisible;
  final double currentPressure;

  const DrawingCanvasPaper({
    super.key,
    required this.canvasKey,
    required this.controller,
    required this.canvasSize,
    this.panelGuideShape,
    this.panelGuidePolygon,
    this.panelGuideBorderRadius = 0.0,
    this.showPanelGuide = true,
    this.cursorPosition,
    this.isCursorVisible = false,
    this.currentPressure = 1.0,
  });

  List<Offset> _getMirroredPositions(Offset? pt) {
    if (pt == null || controller.symmetryMode == DrawingSymmetryMode.none) {
      return const [];
    }
    final projected = controller.symmetryMode.projectPoints([pt], canvasSize);
    return projected.expand((e) => e).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: canvasKey,
      width: canvasSize.width,
      height: canvasSize.height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(
                controller.isFlippedHorizontal ? -1.0 : 1.0,
                controller.isFlippedVertical ? -1.0 : 1.0,
                1.0,
              ),
              child: CustomPaint(
                size: canvasSize,
                painter: DrawingCanvasPainter(
                  layers: controller.layers,
                  activeLayerIndex: controller.activeLayerIndex,
                  activeStroke: controller.activeStroke,
                  activeMirroredStrokes: controller.activeMirroredStrokes,
                  backgroundType: controller.backgroundType,
                  symmetryMode: controller.symmetryMode,
                  activeSelection: controller.activeSelection,
                ),
                foregroundPainter: DrawingCursorPainter(
                  cursorPosition: cursorPosition,
                  mirroredPositions: _getMirroredPositions(cursorPosition),
                  strokeWidth: controller.strokeWidth,
                  tool: controller.selectedTool,
                  color: controller.selectedColor,
                  pressure: currentPressure,
                  visible: isCursorVisible &&
                      controller.showBrushCursor &&
                      controller.selectedTool.showsBrushCursor,
                ),
                child: CustomPaint(
                  size: canvasSize,
                  painter: DrawingPanelGuidePainter(
                    shape: panelGuideShape,
                    polygonPoints: panelGuidePolygon,
                    borderRadius: panelGuideBorderRadius,
                    visible: showPanelGuide,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
