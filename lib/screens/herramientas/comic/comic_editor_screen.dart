import 'dart:async';
import 'package:flutter/material.dart';
import 'controllers/comic_controller.dart';
import 'helpers/comic_editor_actions.dart';
import 'models/comic_bubble.dart';
import 'models/comic_project.dart';
import 'models/comic_sticker.dart';
import 'services/comic_storage_service.dart';
import 'widgets/comic_add_drawer.dart';
import 'widgets/comic_bottom_toolbar.dart';
import 'widgets/comic_editor_overlays.dart';
import 'widgets/comic_mode_indicator_banner.dart';
import 'widgets/comic_page_editor_widget.dart';
import 'widgets/comic_projects_sheet.dart';
import 'widgets/comic_top_bar.dart';

/// Pantalla principal del taller de cómics con autoguardado,
/// herramientas flotantes no invasivas y edición libre de viñetas, globos y SFX.
class ComicEditorScreen extends StatefulWidget {
  final ComicProject? initialProject;

  const ComicEditorScreen({super.key, this.initialProject});

  @override
  State<ComicEditorScreen> createState() => _ComicEditorScreenState();
}

class _ComicEditorScreenState extends State<ComicEditorScreen> {
  late final ComicController _controller;
  Timer? _autoSaveTimer;

  bool _showBubbleBar = false;
  bool _showSfxBar = false;
  bool _showSfxEditor = false;
  bool _showPanelCustomizer = false;
  bool _showTemplateBar = false;
  bool _showLayersDock = false;
  bool _isImmersive = false;

  ComicBubble? _editingBubble;
  ComicSticker? _editingSfx;

  @visibleForTesting
  ComicController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = ComicController(initialProject: widget.initialProject, blankPage: true);
    _controller.addListener(_onControllerChange);
    if (widget.initialProject == null) _loadLatestProject();
  }

  Future<void> _loadLatestProject() async {
    final list = await ComicStorageService.listProjects();
    if (list.isNotEmpty && mounted) _controller.loadProject(list.first);
  }

  void _openProjects() {
    _closeAllOverlays();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ComicProjectsSheet(controller: _controller),
    );
  }

  void _onControllerChange() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), _performAutoSave);
  }

  Future<void> _performAutoSave() async {
    try {
      await ComicStorageService.saveProject(_controller.project);
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _performAutoSave();
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _toggleOverlay({
    bool bubble = false,
    bool sfx = false,
    bool sfxEditor = false,
    bool panel = false,
    bool template = false,
    ComicBubble? bubbleItem,
    ComicSticker? sfxItem,
  }) {
    setState(() {
      _showLayersDock = false;
      _showBubbleBar = bubble;
      _showSfxBar = sfx;
      _showSfxEditor = sfxEditor;
      _showPanelCustomizer = panel;
      _showTemplateBar = template;
      _editingBubble = bubbleItem ?? _controller.selectedBubble;
      _editingSfx = sfxItem ?? _controller.selectedSfx;
      if (bubble || sfx || template) _controller.selectPanel(null);
    });
  }

  void _closeAllOverlays() {
    _toggleOverlay();
    _showLayersDock = false;
    _controller.deselectAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final activePanel = _controller.selectedPanel;
          return Stack(
            children: [
              // Canvas de la página de cómic
              Positioned.fill(
                child: ComicPageEditorWidget(
                  controller: _controller,
                  isImmersive: _isImmersive,
                  onExitImmersive: () => setState(() => _isImmersive = false),
                  onPanelTap: (_) => _toggleOverlay(),
                  onBubbleTap: (bubble) => _toggleOverlay(bubble: true, bubbleItem: bubble),
                  onSfxTap: (sfx) => _toggleOverlay(sfxEditor: true, sfxItem: sfx),
                  onBubbleDoubleTap: (bubble) => _toggleOverlay(bubble: true, bubbleItem: bubble),
                  onSfxDoubleTap: (sfx) => _toggleOverlay(sfxEditor: true, sfxItem: sfx),
                  onDeselect: _closeAllOverlays,
                ),
              ),

              // Barra Superior Flotante con Undo / Redo
              if (!_isImmersive)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ComicTopBar(
                    controller: _controller,
                    onOpenProjects: _openProjects,
                    onOpenReader: () {
                      _closeAllOverlays();
                      ComicEditorActions.openReader(context, _controller);
                    },
                    onOpenExport: () {
                      _closeAllOverlays();
                      ComicEditorActions.openExport(context, _controller);
                    },
                    isImmersive: _isImmersive,
                    onToggleImmersive: () => setState(() => _isImmersive = !_isImmersive),
                    isLayersOpen: _showLayersDock,
                    onToggleLayers: () => setState(() {
                      final willOpen = !_showLayersDock;
                      _closeAllOverlays();
                      _showLayersDock = willOpen;
                    }),
                  ),
                ),

              // Píldora visible para Salir de Modo Inmersivo
              if (_isImmersive)
                Positioned(
                  top: 14,
                  left: 20,
                  right: 20,
                  child: SafeArea(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _isImmersive = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00D4FF), width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility, color: Color(0xFF00D4FF), size: 16),
                              SizedBox(width: 8),
                              Text('VISTA LIMPIA • TOCA PARA VOLVER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              SizedBox(width: 8),
                              Icon(Icons.close, color: Colors.white54, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Banner flotante de modo activo (Trazar viñeta / Cortar)
              ComicModeIndicatorBanner(controller: _controller),

              // Capas de edición flotantes no invasivas
              ComicEditorOverlays(
                controller: _controller,
                activePanel: activePanel,
                editingBubble: _editingBubble,
                editingSfx: _editingSfx,
                showBubbleBar: _showBubbleBar,
                showSfxBar: _showSfxBar,
                showSfxEditor: _showSfxEditor,
                showPanelCustomizer: _showPanelCustomizer,
                showTemplateBar: _showTemplateBar,
                showLayersDock: _showLayersDock,
                onCloseLayersDock: () => setState(() => _showLayersDock = false),
                isImmersive: _isImmersive,
                onDrawInPanel: () { _closeAllOverlays(); ComicEditorActions.drawInPanel(context: context, controller: _controller, panel: activePanel!); },
                onInsertDrawing: () => ComicEditorActions.insertDrawing(context: context, controller: _controller, panel: activePanel!),
                onPickGalleryImage: () => ComicEditorActions.pickImageFromGallery(context: context, controller: _controller, panel: activePanel!),
                onOpenPanelCustomizer: () => setState(() => _showPanelCustomizer = true),
                onClosePanelCustomizer: () => setState(() => _showPanelCustomizer = false),
                onSaveBubble: (savedBubble) {
                  if (_controller.selectedBubbleId != null || _editingBubble != null) {
                    _controller.updateBubble(savedBubble);
                  } else {
                    _controller.addBubble(bubble: savedBubble);
                  }
                  _editingBubble = savedBubble;
                },
                onDeleteBubble: (id) { _controller.deleteBubble(id); _toggleOverlay(); },
                onCloseBubble: () { _controller.selectBubble(null); _toggleOverlay(); },
                onUpdateSfx: (updated) => _controller.updateSfx(updated),
                onDeleteSfx: () {
                  final id = _controller.selectedSfxId ?? _editingSfx?.id;
                  if (id != null) _controller.deleteSfx(id);
                  _toggleOverlay();
                },
                onCloseSfxEditor: () { _controller.selectSfx(null); _toggleOverlay(); },
                onStampSfx: (text, color) { _controller.addSfx(text, color: color); _toggleOverlay(); },
                onCloseSfxBar: () => _toggleOverlay(),
                onCloseTemplateBar: () => _toggleOverlay(),
              ),

              // Paginador de páginas inferior izquierdo
              if (!_isImmersive)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: SafeArea(
                    top: false,
                    child: ComicBottomToolbar(
                      controller: _controller,
                      onToggleBubble: () => _toggleOverlay(bubble: !_showBubbleBar),
                      onToggleSfx: () => _toggleOverlay(sfx: !_showSfxBar),
                      onToggleTemplates: () => _toggleOverlay(template: !_showTemplateBar),
                    ),
                  ),
                ),

              // Botón Flotante "+" abajo a la derecha para agregar Viñetas, Globos y SFX
              if (!_isImmersive)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      onTap: () {
                        _closeAllOverlays();
                        ComicAddDrawer.show(context, _controller);
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00D4FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.black, size: 28),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
