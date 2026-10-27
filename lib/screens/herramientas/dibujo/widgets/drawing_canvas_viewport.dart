import 'package:flutter/material.dart';
import '../../comic/models/comic_panel.dart';
import '../controllers/drawing_controller.dart';
import 'drawing_canvas_paper.dart';
import 'drawing_viewport_gesture_coordinator.dart';
import 'drawing_viewport_math.dart';

/// Viewport interactivo del lienzo de dibujo estilo Procreate / Infinite Painter:
/// - 1 dedo: Trazo fluido de dibujo instantáneo con retícula de tamaño de pincel en vivo.
/// - 2 o más dedos: Zoom y paneo suave diferencial alrededor del centro exacto de los dedos,
///   sin saltos, sin descolocarse y sin alterar la posición al soltar los dedos.
/// - Rueda del ratón (desktop): Zoom progresivo continuo enfocado en el cursor.
class DrawingCanvasViewport extends StatefulWidget {
  final DrawingController controller;
  final TransformationController transformController;
  final Size canvasSize;
  final ComicPanelShape? panelGuideShape;
  final List<Offset>? panelGuidePolygon;
  final double panelGuideBorderRadius;
  final bool showPanelGuide;

  const DrawingCanvasViewport({
    super.key,
    required this.controller,
    required this.transformController,
    this.canvasSize = const Size(2000, 2000),
    this.panelGuideShape,
    this.panelGuidePolygon,
    this.panelGuideBorderRadius = 0.0,
    this.showPanelGuide = true,
  });

  @override
  State<DrawingCanvasViewport> createState() => _DrawingCanvasViewportState();
}

class _DrawingCanvasViewportState extends State<DrawingCanvasViewport> {
  final GlobalKey _canvasKey = GlobalKey();
  late final DrawingViewportGestureCoordinator _gestureCoordinator;

  Offset? _cursorPosition;
  bool _isCursorVisible = false;
  double _currentPressure = 1.0;
  bool _initializedFit = false;

  @override
  void initState() {
    super.initState();
    _gestureCoordinator = DrawingViewportGestureCoordinator(
      controller: widget.controller,
      transformController: widget.transformController,
      canvasKey: _canvasKey,
      getContext: () => context,
      onCursorUpdate: (cursor, pressure, visible) {
        if (mounted) {
          setState(() {
            _cursorPosition = cursor;
            _currentPressure = pressure;
            _isCursorVisible = visible;
          });
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanvasSize(widget.canvasSize);
    });
  }

  @override
  void didUpdateWidget(DrawingCanvasViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canvasSize != widget.canvasSize) {
      widget.controller.setCanvasSize(widget.canvasSize);
    }
  }

  void fitToScreen(Size viewportSize) {
    DrawingViewportMath.fitToScreen(
      viewportSize: viewportSize,
      canvasSize: widget.canvasSize,
      transformController: widget.transformController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_initializedFit && constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          _initializedFit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) fitToScreen(Size(constraints.maxWidth, constraints.maxHeight));
          });
        }

        return MouseRegion(
          onExit: (_) {
            if (!_gestureCoordinator.hasActivePointers && _isCursorVisible) {
              setState(() {
                _isCursorVisible = false;
                _cursorPosition = null;
              });
            }
          },
          child: Listener(
            onPointerDown: (e) => _gestureCoordinator.handlePointerDown(e, widget.canvasSize),
            onPointerMove: (e) => _gestureCoordinator.handlePointerMove(e, widget.canvasSize),
            onPointerUp: _gestureCoordinator.handlePointerUpOrCancel,
            onPointerCancel: _gestureCoordinator.handlePointerUpOrCancel,
            onPointerSignal: _gestureCoordinator.handlePointerSignal,
            onPointerHover: (event) {
              if (!_gestureCoordinator.hasActivePointers && widget.controller.showBrushCursor) {
                setState(() {
                  _cursorPosition = _gestureCoordinator.toCanvasCoordinates(event.position, widget.canvasSize);
                  _currentPressure = 1.0;
                  _isCursorVisible = true;
                });
              }
            },
            behavior: HitTestBehavior.opaque,
            child: InteractiveViewer(
              transformationController: widget.transformController,
              boundaryMargin: const EdgeInsets.all(10000),
              minScale: 0.02,
              maxScale: 40.0,
              constrained: false,
              panEnabled: false,
              scaleEnabled: false,
              child: DrawingCanvasPaper(
                canvasKey: _canvasKey,
                controller: widget.controller,
                canvasSize: widget.canvasSize,
                panelGuideShape: widget.panelGuideShape,
                panelGuidePolygon: widget.panelGuidePolygon,
                panelGuideBorderRadius: widget.panelGuideBorderRadius,
                showPanelGuide: widget.showPanelGuide,
                cursorPosition: _cursorPosition,
                isCursorVisible: _isCursorVisible,
                currentPressure: _currentPressure,
              ),
            ),
          ),
        );
      },
    );
  }
}
