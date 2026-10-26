import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import 'drawing_floating_brush_popover.dart';
import 'drawing_floating_color_popover.dart';
import 'popovers/drawing_edit_popover.dart';
import 'popovers/drawing_options_popover.dart';
import 'popovers/drawing_tools_popover.dart';

/// Capa flotante con los popovers contextuales de la barra superior, selector de color y pinceles.
class DrawingScreenPopovers extends StatelessWidget {
  final DrawingController controller;
  final bool showTools;
  final bool showEdit;
  final bool showOptions;
  final bool showColor;
  final bool showBrush;
  final VoidCallback onResetZoom;
  final VoidCallback onOpenProjects;
  final VoidCallback onExport;
  final VoidCallback onCloseAll;
  final VoidCallback onCloseColor;
  final VoidCallback onCloseBrush;

  const DrawingScreenPopovers({
    super.key,
    required this.controller,
    required this.showTools,
    required this.showEdit,
    required this.showOptions,
    required this.showColor,
    this.showBrush = false,
    required this.onResetZoom,
    required this.onOpenProjects,
    required this.onExport,
    required this.onCloseAll,
    required this.onCloseColor,
    required this.onCloseBrush,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showTools)
          Positioned(
            top: 54,
            right: 120,
            child: DrawingToolsPopover(
              controller: controller,
              onResetZoom: onResetZoom,
              onClose: onCloseAll,
            ),
          ),
        if (showEdit)
          Positioned(
            top: 54,
            right: 70,
            child: DrawingEditPopover(
              controller: controller,
              onClose: onCloseAll,
            ),
          ),
        if (showOptions)
          Positioned(
            top: 54,
            right: 12,
            child: DrawingOptionsPopover(
              controller: controller,
              onOpenProjects: onOpenProjects,
              onExport: onExport,
              onClose: onCloseAll,
            ),
          ),
        if (showColor)
          Positioned(
            left: 66,
            bottom: 40,
            child: DrawingFloatingColorPopover(
              controller: controller,
              onClose: onCloseColor,
            ),
          ),
        if (showBrush)
          Positioned(
            left: 66,
            top: 80,
            bottom: 40,
            child: DrawingFloatingBrushPopover(
              controller: controller,
              onClose: onCloseBrush,
            ),
          ),
      ],
    );
  }
}
