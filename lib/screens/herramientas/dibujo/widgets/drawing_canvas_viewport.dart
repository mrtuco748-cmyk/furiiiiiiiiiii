import 'package:flutter/material.dart';
import '../../comic/models/comic_panel.dart';
import '../controllers/drawing_controller.dart';
import '../models/drawing_symmetry_mode.dart';
import '../painters/drawing_canvas_painter.dart';
import '../painters/drawing_cursor_painter.dart';
import '../painters/drawing_panel_guide_painter.dart';
import 'drawing_viewport_math.dart';

/// Viewport interactivo del lienzo estilo Procreate con retícula de trazo en vivo:
/// - 1 dedo: Trazo fluido de dibujo con retícula circular del grosor exacto del pincel o goma.
/// - 2 dedos: Navegación continua con zoom (pinch) y paneo (pan) suave alrededor del punto focal.
/// - Puntero/Hover: Guía visual interactiva de tamaño previo al contacto.
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
  final Map<int, Offset> _activePointers = {};
  bool _isMultiTouch = false;
  bool _isDraggingSelection = false;
  Offset? _lastSelectionPoint;
  Offset? _initialFocalPoint;
  double? _initialDistance;
  Matrix4? _initialTransform;
  bool _initializedFit = false;

  // Guía visual en vivo (Brush Cursor)
  Offset? _cursorPosition;
  bool _isCursorVisible = false;
  double _currentPressure = 1.0;

  @override
  void initState() {
    super.initState();
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

  Offset _toCanvasCoordinates(Offset globalPosition) {
    return DrawingViewportMath.toCanvasCoordinates(
      globalPosition: globalPosition,
      canvasKey: _canvasKey,
      context: context,
      transformController: widget.transformController,
      canvasSize: widget.canvasSize,
      isFlippedHorizontal: widget.controller.isFlippedHorizontal,
      isFlippedVertical: widget.controller.isFlippedVertical,
    );
  }

  List<Offset> _getMirroredPositions(Offset? pt) {
    if (pt == null || widget.controller.symmetryMode == DrawingSymmetryMode.none) {
      return const [];
    }
    final projected = widget.controller.symmetryMode.projectPoints([pt], widget.canvasSize);
    return projected.expand((e) => e).toList();
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;

    if (_activePointers.length == 1) {
      _isMultiTouch = false;
      final canvasPoint = _toCanvasCoordinates(event.position);
      _cursorPosition = canvasPoint;
      _currentPressure = event.pressure > 0 ? event.pressure : 1.0;
      _isCursorVisible = true;

      if (widget.controller.hasSelection && widget.controller.activeSelection!.containsPoint(canvasPoint)) {
        _isDraggingSelection = true;
        _lastSelectionPoint = canvasPoint;
        return;
      }
      if (widget.controller.hasSelection) {
        widget.controller.clearSelection();
      }

      widget.controller.startStroke(canvasPoint, _currentPressure);
    } else if (_activePointers.length >= 2) {
      _isMultiTouch = true;
      _isDraggingSelection = false;
      _lastSelectionPoint = null;
      _isCursorVisible = false;
      _cursorPosition = null;

      if (widget.controller.activeStroke != null) {
        widget.controller.cancelActiveStroke();
      }
      _initialFocalPoint = DrawingViewportMath.calculateFocalPoint(_activePointers.values);
      _initialDistance = DrawingViewportMath.calculateDistance(_activePointers.values);
      _initialTransform = Matrix4.copy(widget.transformController.value);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _activePointers[event.pointer] = event.position;

    if (_isMultiTouch || _activePointers.length >= 2) {
      _isCursorVisible = false;
      _cursorPosition = null;
      final newMatrix = DrawingViewportMath.calculateTwoFingerTransform(
        initialFocalPoint: _initialFocalPoint,
        initialDistance: _initialDistance,
        initialTransform: _initialTransform,
        activePointers: _activePointers.values,
      );
      if (newMatrix != null) {
        widget.transformController.value = newMatrix;
      }
    } else if (_activePointers.length == 1) {
      final canvasPoint = _toCanvasCoordinates(event.position);
      _cursorPosition = canvasPoint;
      _currentPressure = event.pressure > 0 ? event.pressure : 1.0;
      _isCursorVisible = true;

      if (_isDraggingSelection && _lastSelectionPoint != null) {
        final delta = canvasPoint - _lastSelectionPoint!;
        _lastSelectionPoint = canvasPoint;
        widget.controller.moveSelection(delta);
        return;
      }
      widget.controller.updateStroke(canvasPoint, _currentPressure);
    }
  }

  void _finishPointer(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty) {
      setState(() {
        _isCursorVisible = false;
        _cursorPosition = null;
      });
      if (_isDraggingSelection) {
        _isDraggingSelection = false;
        _lastSelectionPoint = null;
      } else if (!_isMultiTouch) {
        widget.controller.endStroke();
      }
      _isMultiTouch = false;
      _initialFocalPoint = null;
      _initialDistance = null;
      _initialTransform = null;
    }
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
          onExit: (event) {
            if (_activePointers.isEmpty && _isCursorVisible) {
              setState(() {
                _isCursorVisible = false;
                _cursorPosition = null;
              });
            }
          },
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _finishPointer,
            onPointerCancel: _finishPointer,
            onPointerHover: (event) {
              if (_activePointers.isEmpty && widget.controller.showBrushCursor) {
                setState(() {
                  _cursorPosition = _toCanvasCoordinates(event.position);
                  _currentPressure = 1.0;
                  _isCursorVisible = true;
                });
              }
            },
            behavior: HitTestBehavior.opaque,
            child: InteractiveViewer(
            transformationController: widget.transformController,
            boundaryMargin: const EdgeInsets.all(2000),
            minScale: 0.1,
            maxScale: 8.0,
            constrained: false,
            panEnabled: false,
            scaleEnabled: false,
            child: Container(
              key: _canvasKey,
              width: widget.canvasSize.width,
              height: widget.canvasSize.height,
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
                  listenable: widget.controller,
                  builder: (context, _) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                        widget.controller.isFlippedHorizontal ? -1.0 : 1.0,
                        widget.controller.isFlippedVertical ? -1.0 : 1.0,
                        1.0,
                      ),
                      child: CustomPaint(
                        size: widget.canvasSize,
                        painter: DrawingCanvasPainter(
                          layers: widget.controller.layers,
                          activeLayerIndex: widget.controller.activeLayerIndex,
                          activeStroke: widget.controller.activeStroke,
                          activeMirroredStrokes: widget.controller.activeMirroredStrokes,
                          backgroundType: widget.controller.backgroundType,
                          symmetryMode: widget.controller.symmetryMode,
                          activeSelection: widget.controller.activeSelection,
                        ),
                        foregroundPainter: DrawingCursorPainter(
                          cursorPosition: _cursorPosition,
                          mirroredPositions: _getMirroredPositions(_cursorPosition),
                          strokeWidth: widget.controller.strokeWidth,
                          tool: widget.controller.selectedTool,
                          color: widget.controller.selectedColor,
                          pressure: _currentPressure,
                          visible: _isCursorVisible &&
                              widget.controller.showBrushCursor &&
                              widget.controller.selectedTool.showsBrushCursor,
                        ),
                        child: CustomPaint(
                          size: widget.canvasSize,
                          painter: DrawingPanelGuidePainter(
                            shape: widget.panelGuideShape,
                            polygonPoints: widget.panelGuidePolygon,
                            borderRadius: widget.panelGuideBorderRadius,
                            visible: widget.showPanelGuide,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
}
