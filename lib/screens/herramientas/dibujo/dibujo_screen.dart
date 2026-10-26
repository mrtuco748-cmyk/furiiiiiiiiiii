import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../comic/models/comic_panel.dart';
import 'controllers/drawing_controller.dart';
import 'models/drawing_project.dart';
import 'models/drawing_tool_type.dart';
import 'services/drawing_storage_service.dart';
import 'widgets/drawing_canvas_viewport.dart';
import 'widgets/drawing_export_dialog.dart';
import 'widgets/drawing_infinite_dock.dart';
import 'widgets/drawing_lasso_action_bar.dart';
import 'widgets/drawing_layers_dock.dart';
import 'widgets/drawing_projects_sheet.dart';
import 'widgets/drawing_screen_popovers.dart';
import 'widgets/drawing_top_bar.dart';
import 'widgets/drawing_undo_redo_buttons.dart';

/// Pantalla profesional de dibujo digital con UI fiel a Infinite Painter y soporte de guías de cómic.
class DibujoScreen extends StatefulWidget {
  final DrawingProject? project;
  final Size? canvasSize;
  final ComicPanelShape? panelGuideShape;
  final List<Offset>? panelGuidePolygon;
  final double panelGuideBorderRadius;
  final void Function(DrawingProject project, Uint8List? pngBytes)? onSaveAndReturn;

  const DibujoScreen({
    super.key,
    this.project,
    this.canvasSize,
    this.panelGuideShape,
    this.panelGuidePolygon,
    this.panelGuideBorderRadius = 0.0,
    this.onSaveAndReturn,
  });

  @override
  State<DibujoScreen> createState() => _DibujoScreenState();
}

class _DibujoScreenState extends State<DibujoScreen> {
  late final DrawingController _controller;
  late final TransformationController _transformController;
  Timer? _autoSaveTimer;

  bool _showColorPopover = false;
  bool _showBrushPopover = false;
  bool _showToolsPopover = false;
  bool _showEditPopover = false;
  bool _showLayersDock = false;
  bool _showOptionsPopover = false;
  bool _isImmersive = false;
  final bool _showPanelGuide = true;

  @override
  void initState() {
    super.initState();
    _controller = DrawingController(initialProject: widget.project);
    _transformController = TransformationController();
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), _performAutoSave);
  }

  Future<void> _performAutoSave() async {
    try {
      String? thumb = _controller.project.thumbnailBase64;
      if (thumb == null || thumb.isEmpty) {
        final png = await _controller.exportToPng(size: const Size(200, 200));
        if (png != null) thumb = base64Encode(png);
      }
      await DrawingStorageService.saveProject(_controller.toProject(thumbnailBase64: thumb));
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.removeListener(_onControllerChange);
    DrawingStorageService.saveProject(_controller.toProject());
    _controller.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    final media = MediaQuery.of(context).size;
    final cSize = widget.canvasSize ?? _controller.canvasSize;
    final s = math.min((media.width * 0.90) / cSize.width, (media.height * 0.76) / cSize.height).clamp(0.12, 3.0);
    setState(() {
      _transformController.value = Matrix4.identity()
        ..translateByDouble((media.width - cSize.width * s) / 2, (media.height - cSize.height * s) / 2, 0.0, 1.0)
        ..scaleByDouble(s, s, 1.0, 1.0);
    });
  }

  void _closeFloatingPanels() {
    if (_showColorPopover || _showToolsPopover || _showEditPopover || _showOptionsPopover || _showBrushPopover) {
      setState(() => _showColorPopover = _showToolsPopover = _showEditPopover = _showOptionsPopover = _showBrushPopover = false);
    }
  }

  void _togglePopover({bool tools = false, bool edit = false, bool options = false, bool color = false, bool brush = false}) {
    setState(() {
      _showToolsPopover = tools && !_showToolsPopover;
      _showEditPopover = edit && !_showEditPopover;
      _showOptionsPopover = options && !_showOptionsPopover;
      _showColorPopover = color && !_showColorPopover;
      _showBrushPopover = brush && !_showBrushPopover;
    });
  }

  void _openProjects() {
    _closeFloatingPanels();
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => DrawingProjectsSheet(controller: _controller));
  }

  Future<void> _handleBack() async {
    _closeFloatingPanels();
    if (widget.onSaveAndReturn != null) {
      final exportSize = widget.canvasSize ?? Size(widget.project?.canvasWidth ?? 1200, widget.project?.canvasHeight ?? 1200);
      final png = await _controller.exportToPng(size: exportSize);
      widget.onSaveAndReturn!(_controller.toProject(thumbnailBase64: png != null ? base64Encode(png) : null), png);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openExport() async {
    _closeFloatingPanels();
    if (widget.onSaveAndReturn != null) return _handleBack();
    showDialog(context: context, builder: (_) => DrawingExportDialog(controller: _controller));
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCanvasSize = widget.canvasSize ?? _controller.canvasSize;
    final hasActiveShapeOrTool = _controller.selectedTool.isShape ||
        _controller.selectedTool == DrawingToolType.bucketFill ||
        _controller.selectedTool == DrawingToolType.gradient ||
        _controller.selectedTool == DrawingToolType.lasso;

    return PopScope(
      canPop: widget.onSaveAndReturn == null,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && widget.onSaveAndReturn != null) {
          await _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF141414),
        body: Stack(
          children: [
            // Viewport del lienzo infinito con soporte de máscara de viñeta
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (_) => _closeFloatingPanels(),
                child: DrawingCanvasViewport(
                  controller: _controller,
                  transformController: _transformController,
                  canvasSize: effectiveCanvasSize,
                  panelGuideShape: widget.panelGuideShape,
                  panelGuidePolygon: widget.panelGuidePolygon,
                  panelGuideBorderRadius: widget.panelGuideBorderRadius,
                  showPanelGuide: _showPanelGuide,
                ),
              ),
            ),

            // Dock lateral Infinite Painter
            if (!_isImmersive)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: DrawingInfiniteDock(
                    controller: _controller,
                    onToggleColorPopover: () => _togglePopover(color: true),
                    onToggleBrushPopover: () => _togglePopover(brush: true),
                  ),
                ),
              ),

            // Barra superior estilo Infinite Painter
            if (!_isImmersive)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DrawingTopBar(
                  controller: _controller,
                  onToggleTools: () => _togglePopover(tools: true),
                  onToggleEdit: () => _togglePopover(edit: true),
                  onToggleLayers: () {
                    _closeFloatingPanels();
                    setState(() => _showLayersDock = !_showLayersDock);
                  },
                  onToggleOptions: () => _togglePopover(options: true),
                  onOpenProjects: _openProjects,
                  onExport: _openExport,
                  onBack: _handleBack,
                  isImmersive: _isImmersive,
                  isLayersOpen: _showLayersDock,
                  onToggleImmersive: () => setState(() => _isImmersive = !_isImmersive),
                ),
              ),

            // Chip de deselección rápida de herramienta de forma o relleno (Volver a Pincel)
            if (!_isImmersive && hasActiveShapeOrTool)
              Positioned(
                top: 54,
                left: 0,
                right: 0,
                child: Center(
                  child: ActionChip(
                    backgroundColor: const Color(0xFF00D4FF),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    label: Text(
                      '${_controller.selectedTool.displayName} activa',
                      style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    avatar: const Icon(Icons.close, size: 14, color: Colors.black),
                    onPressed: () => setState(() => _controller.selectTool(_controller.previousDrawingTool)),
                  ),
                ),
              ),

            // Botón Deshacer y Rehacer
            if (!_isImmersive)
              Positioned(
                bottom: 20,
                left: 14,
                child: DrawingUndoRedoButtons(controller: _controller),
              ),

            // Dock vertical de Capas
            if (_showLayersDock && !_isImmersive)
              Positioned(
                top: 54,
                bottom: 20,
                right: 0,
                child: DrawingLayersDock(
                  controller: _controller,
                  onClose: () => setState(() => _showLayersDock = false),
                ),
              ),

            // Barra de acciones de Lazo activa
            if (!_isImmersive && _controller.hasSelection)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: DrawingLassoActionBar(controller: _controller),
                ),
              ),

            // Popovers contextuales
            if (!_isImmersive)
              DrawingScreenPopovers(
                controller: _controller,
                showTools: _showToolsPopover,
                showEdit: _showEditPopover,
                showOptions: _showOptionsPopover,
                showColor: _showColorPopover,
                showBrush: _showBrushPopover,
                onResetZoom: _resetZoom,
                onOpenProjects: _openProjects,
                onExport: _openExport,
                onCloseAll: _closeFloatingPanels,
                onCloseColor: () => setState(() => _showColorPopover = false),
                onCloseBrush: () => setState(() => _showBrushPopover = false),
              ),
          ],
        ),
      ),
    );
  }
}
