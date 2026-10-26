import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_alignment_guide.dart';
import '../models/comic_bubble.dart';
import '../models/comic_interaction_mode.dart';
import '../models/comic_panel.dart';
import '../models/comic_sticker.dart';
import '../painters/comic_draw_guide_painter.dart';
import '../painters/comic_page_painter.dart';
import 'comic_editor_gesture_helper.dart';
import 'comic_selection_handles.dart';
import 'comic_transform_resolver.dart';

/// Canvas interactivo del cómic con soporte de trazado libre de viñetas con los dedos,
/// manipulación táctil directa de globos, SFX y viñetas (mover, rotar y escalar por 8 mangos).
class ComicPageEditorWidget extends StatefulWidget {
  final ComicController controller;
  final ValueChanged<ComicPanel> onPanelTap;
  final ValueChanged<ComicBubble> onBubbleTap;
  final ValueChanged<ComicSticker>? onSfxTap;
  final ValueChanged<ComicBubble>? onBubbleDoubleTap;
  final ValueChanged<ComicSticker>? onSfxDoubleTap;
  final VoidCallback? onDeselect;

  const ComicPageEditorWidget({
    super.key,
    required this.controller,
    required this.onPanelTap,
    required this.onBubbleTap,
    this.onSfxTap,
    this.onBubbleDoubleTap,
    this.onSfxDoubleTap,
    this.onDeselect,
  });

  @override
  State<ComicPageEditorWidget> createState() => _ComicPageEditorWidgetState();
}

class _ComicPageEditorWidgetState extends State<ComicPageEditorWidget> {
  final TransformationController _transformController = TransformationController();
  ComicDragMode _activeMode = ComicDragMode.none;
  List<ComicAlignmentGuide> _activeGuides = const [];
  double _initialDist = 1.0, _initialScale = 1.0, _initialW = 100.0, _initialH = 100.0;
  Offset? _drawStart, _drawCurrent, _sliceStart, _sliceCurrent;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  ComicElementTransform? _getActiveTransform(Size pageSize) =>
      ComicTransformResolver.resolve(widget.controller, pageSize);

  void _handlePanDown(Offset localPos, Size pageSize) {
    if (widget.controller.interactionMode != ComicInteractionMode.normal) return;

    final t = _getActiveTransform(pageSize);
    if (t != null) {
      final hit = t.hitTest(localPos);
      if (hit == ComicHandleType.rotate) {
        _activeMode = ComicDragMode.rotate;
        return;
      }
      if (hit.isCorner) {
        _activeMode = ComicDragMode.scale;
        _initialDist = math.max(10.0, (localPos - t.center).distance);
        _initialScale = widget.controller.selectedSfx?.scale ?? 1.0;
        _initialW = t.halfW * 2;
        _initialH = t.halfH * 2;
        return;
      }
      if (hit.isEdge) {
        _activeMode = switch (hit) {
          ComicHandleType.edgeTop => ComicDragMode.resizeTop,
          ComicHandleType.edgeBottom => ComicDragMode.resizeBottom,
          ComicHandleType.edgeLeft => ComicDragMode.resizeLeft,
          ComicHandleType.edgeRight => ComicDragMode.resizeRight,
          _ => ComicDragMode.none,
        };
        _initialW = t.halfW * 2;
        _initialH = t.halfH * 2;
        return;
      }
    }

    // Prioridad de toques directos: Globos > SFX > Viñeta de fondo
    final b = ComicTransformResolver.findTappedBubble(widget.controller, localPos, pageSize);
    if (b != null) {
      widget.controller.selectBubble(b.id);
      widget.onBubbleTap(b);
      _activeMode = ComicDragMode.move;
      return;
    }

    final sfx = ComicTransformResolver.findTappedSfx(widget.controller, localPos, pageSize);
    if (sfx != null) {
      widget.controller.selectSfx(sfx.id);
      widget.onSfxTap?.call(sfx);
      _activeMode = ComicDragMode.move;
      return;
    }

    if (t != null && t.hitTest(localPos) == ComicHandleType.body) {
      _activeMode = ComicDragMode.move;
      return;
    }

    final p = ComicTransformResolver.findTappedPanel(widget.controller, localPos, pageSize);
    if (p != null) {
      widget.controller.selectPanel(p.id);
      widget.onPanelTap(p);
      _activeMode = ComicDragMode.move;
      return;
    }

    _activeMode = ComicDragMode.none;
  }

  void _handlePanStart(Offset localPos, Size pageSize) {
    if (widget.controller.interactionMode == ComicInteractionMode.drawPanel) {
      return setState(() { _drawStart = localPos; _drawCurrent = localPos; });
    }
    if (widget.controller.interactionMode == ComicInteractionMode.slicePanel) {
      return setState(() { _sliceStart = localPos; _sliceCurrent = localPos; });
    }
    if (widget.controller.interactionMode == ComicInteractionMode.frameContent) {
      _activeMode = ComicDragMode.frameContent;
      widget.controller.recordHistory();
      return;
    }
    if (_activeMode != ComicDragMode.none) {
      widget.controller.recordHistory();
      return;
    }
    _handlePanDown(localPos, pageSize);
    if (_activeMode != ComicDragMode.none) {
      widget.controller.recordHistory();
      return;
    }
    widget.controller.deselectAll();
    widget.onDeselect?.call();
  }

  void _handlePanUpdate(DragUpdateDetails details, Size pageSize) {
    if (widget.controller.interactionMode == ComicInteractionMode.drawPanel) {
      setState(() => _drawCurrent = details.localPosition);
      return;
    }
    if (widget.controller.interactionMode == ComicInteractionMode.slicePanel) {
      setState(() => _sliceCurrent = details.localPosition);
      return;
    }
    if (_activeMode == ComicDragMode.frameContent) {
      ComicEditorGestureHelper.applyFramePan(controller: widget.controller, details: details);
      return;
    }

    final c = widget.controller;
    final t = _getActiveTransform(pageSize);
    if (t == null || _activeMode == ComicDragMode.none) return;

    final pos = details.localPosition;
    if (_activeMode == ComicDragMode.rotate) {
      final angle = math.atan2(pos.dy - t.center.dy, pos.dx - t.center.dx) + (math.pi / 2);
      if (c.selectedBubble != null) c.updateBubble(c.selectedBubble!.copyWith(rotation: angle));
      if (c.selectedSfx != null) c.updateSfx(c.selectedSfx!.copyWith(rotation: angle));
      if (c.selectedPanel != null) c.updatePanel(c.selectedPanel!.copyWith(rotation: angle));
    } else if (_activeMode == ComicDragMode.scale) {
      ComicEditorGestureHelper.applyCornerScale(
        controller: c, transform: t, pos: pos, initialDist: _initialDist,
        initialScale: _initialScale, initialW: _initialW, initialH: _initialH, pageSize: pageSize,
      );
    } else if (_activeMode == ComicDragMode.move) {
      _activeGuides = ComicEditorGestureHelper.applyMoveWithSnap(controller: c, details: details, pageSize: pageSize);
      setState(() {});
    } else if (_activeMode == ComicDragMode.resizeTop || _activeMode == ComicDragMode.resizeBottom ||
               _activeMode == ComicDragMode.resizeLeft || _activeMode == ComicDragMode.resizeRight) {
      if (c.selectedBubble != null) {
        ComicEditorGestureHelper.applyBubbleEdgeResize(controller: c, mode: _activeMode, details: details, bubble: c.selectedBubble!);
      } else if (c.selectedPanel != null) {
        ComicEditorGestureHelper.applyEdgeResize(controller: c, mode: _activeMode, details: details, pageSize: pageSize, panel: c.selectedPanel!);
      }
    }
  }

  void _handlePanEnd(Size pageSize) {
    if (widget.controller.interactionMode == ComicInteractionMode.drawPanel) {
      ComicEditorGestureHelper.finishDrawPanel(controller: widget.controller, start: _drawStart, current: _drawCurrent, pageSize: pageSize);
      return setState(() { _drawStart = _drawCurrent = null; _activeMode = ComicDragMode.none; _activeGuides = const []; });
    }
    if (widget.controller.interactionMode == ComicInteractionMode.slicePanel) {
      ComicEditorGestureHelper.finishSlicePanel(controller: widget.controller, start: _sliceStart, current: _sliceCurrent, pageSize: pageSize);
      return setState(() { _sliceStart = _sliceCurrent = null; _activeMode = ComicDragMode.none; _activeGuides = const []; });
    }
    setState(() {
      _activeMode = ComicDragMode.none;
      _activeGuides = const [];
    });
  }

  bool _selectElementAt(Offset localPos, Size pageSize) {
    final b = ComicTransformResolver.findTappedBubble(widget.controller, localPos, pageSize);
    if (b != null) { widget.controller.selectBubble(b.id); widget.onBubbleTap(b); return true; }
    final sfx = ComicTransformResolver.findTappedSfx(widget.controller, localPos, pageSize);
    if (sfx != null) { widget.controller.selectSfx(sfx.id); widget.onSfxTap?.call(sfx); return true; }
    final p = ComicTransformResolver.findTappedPanel(widget.controller, localPos, pageSize);
    if (p != null) { widget.controller.selectPanel(p.id); widget.onPanelTap(p); return true; }
    return false;
  }

  void _handlePageTap(Offset localPos, Size pageSize) {
    if (!_selectElementAt(localPos, pageSize)) { widget.controller.deselectAll(); widget.onDeselect?.call(); }
  }

  void _handleDoubleTap(Offset localPos, Size pageSize) {
    final sfx = ComicTransformResolver.findTappedSfx(widget.controller, localPos, pageSize);
    if (sfx != null) { widget.controller.selectSfx(sfx.id); widget.onSfxDoubleTap?.call(sfx); return; }
    final b = ComicTransformResolver.findTappedBubble(widget.controller, localPos, pageSize);
    if (b != null) { widget.controller.selectBubble(b.id); widget.onBubbleDoubleTap?.call(b); }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const pageAspect = 1.0 / 1.414;
        double targetWidth = constraints.maxWidth * 0.95;
        double targetHeight = targetWidth / pageAspect;
        if (targetHeight > constraints.maxHeight * 0.95) {
          targetHeight = constraints.maxHeight * 0.95;
          targetWidth = targetHeight * pageAspect;
        }
        final pageSize = Size(targetWidth, targetHeight);
        final activeTransform = _getActiveTransform(pageSize);

        final foregroundPainter = switch (widget.controller.interactionMode) {
          ComicInteractionMode.drawPanel when _drawStart != null && _drawCurrent != null =>
            ComicDrawGuidePainter(drawRect: Rect.fromPoints(_drawStart!, _drawCurrent!)),
          ComicInteractionMode.slicePanel when _sliceStart != null && _sliceCurrent != null =>
            ComicDrawGuidePainter(sliceStart: _sliceStart, sliceEnd: _sliceCurrent),
          ComicInteractionMode.frameContent => null,
          _ => activeTransform != null
              ? ComicSelectionBoxPainter(transform: activeTransform, guides: _activeGuides)
              : null,
        };

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.controller.deselectAll();
            widget.onDeselect?.call();
          },
          child: Center(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.8,
              maxScale: 3.5,
              panEnabled: false,
              child: Container(
                width: pageSize.width,
                height: pageSize.height,
                decoration: BoxDecoration(
                  color: widget.controller.activePage.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (d) => _handlePanDown(d.localPosition, pageSize),
                  onTapUp: (d) => _handlePageTap(d.localPosition, pageSize),
                  onPanStart: (d) => _handlePanStart(d.localPosition, pageSize),
                  onPanUpdate: (d) => _handlePanUpdate(d, pageSize),
                  onPanEnd: (_) => _handlePanEnd(pageSize),
                  onDoubleTapDown: (d) => _handleDoubleTap(d.localPosition, pageSize),
                  child: CustomPaint(
                    size: pageSize,
                    painter: ComicPagePainter(
                      page: widget.controller.activePage,
                      panelImages: widget.controller.panelImages,
                      selectedPanelId: widget.controller.selectedPanelId,
                      selectedBubbleId: widget.controller.selectedBubbleId,
                      selectedSfxId: widget.controller.selectedSfxId,
                    ),
                    foregroundPainter: foregroundPainter,
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
