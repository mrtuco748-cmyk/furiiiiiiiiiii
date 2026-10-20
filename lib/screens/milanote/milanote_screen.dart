import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/board_element.dart';
import '../../providers/board_data_provider.dart';
import 'models/active_text_target.dart';
import 'models/note_style_config.dart';
import 'painters/board_chalk_painter.dart';
import 'widgets/pizarron_bottom_cluster.dart';
import 'widgets/pizarron_camera_controller.dart';
import 'widgets/pizarron_camera_math.dart';
import 'widgets/pizarron_element_ops.dart';
import 'widgets/pizarron_gesture_coordinator.dart';
import 'widgets/pizarron_positioned_note.dart';
import 'widgets/pizarron_sidebar_overlay.dart';
import 'widgets/unbounded_hit_test_stack.dart';

/// Pantalla del Pizarrón Infinito (Milanote) de F.U.R.I.
class MilanoteScreen extends StatefulWidget {
  final dynamic mode;
  const MilanoteScreen({super.key, this.mode});

  @override
  State<MilanoteScreen> createState() => _MilanoteScreenState();
}

class _MilanoteScreenState extends State<MilanoteScreen>
    with SingleTickerProviderStateMixin {
  final int _boardId = 1;
  late final PizarronCameraController _camera;
  int? _editingElementId;
  ActiveTextTarget _activeTextTarget = const ActiveTextTarget.title();

  bool _plusMenuOpen = false;
  bool _settingsOpen = false;
  bool _chalkMode = false;
  String _chalkColorHex = '#FFFFFF';
  double _chalkStrokeWidth = 4.5;
  final List<Offset> _liveChalkPoints = [];
  final PizarronGestureCoordinator _gestures = PizarronGestureCoordinator();

  @override
  void initState() {
    super.initState();
    _camera = PizarronCameraController(
      vsync: this,
      onTick: () => setState(() {}),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BoardDataProvider>().load();
    });
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _focusAndEditElement(
    BoardElement el,
    Size size, {
    ActiveTextTarget? initialTarget,
  }) {
    // El riel de herramientas derecho ocupa 54px + 12px padding = 66px.
    // Centramos la nota en el punto medio del espacio útil para que quede perfectamente balanceada.
    final railW = size.width > 600 ? 80.0 : 66.0;
    final availW = math.max(200.0, size.width - railW);
    final availH = size.height * 0.82;
    final idealScale = math.min(
      (availW * 0.88) / math.max(120.0, el.width),
      (availH * 0.68) / math.max(100.0, el.height),
    ).clamp(0.90, 1.35);

    final noteCenter = Offset(el.x + el.width / 2, el.y + el.height / 2);
    final screenCenter = Offset(availW * 0.50, size.height * 0.44);
    final targetPan = screenCenter - (noteCenter * idealScale);

    setState(() {
      _editingElementId = el.id;
      _activeTextTarget = initialTarget ??
          (el.title.isEmpty ? const ActiveTextTarget.title() : const ActiveTextTarget.bodyDefault());
      _plusMenuOpen = _settingsOpen = _chalkMode = false;
    });

    _camera.animateTo(targetPan: targetPan, targetScale: idealScale);
  }

  void _closeEditMode() {
    if (_editingElementId == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _editingElementId = null);
  }

  Future<void> _createNew(String type, Size size, BoardDataProvider provider) async {
    final created = await PizarronElementOps.createNewElement(
      boardId: _boardId,
      type: type,
      screenSize: size,
      cameraPan: _camera.cameraPan,
      cameraScale: _camera.cameraScale,
      provider: provider,
    );
    if (!mounted) return;
    _focusAndEditElement(created, size);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = context.watch<BoardDataProvider>();
    final activeChunk = PizarronCameraMath.computeActiveChunkWorldRect(size, _camera.cameraPan, _camera.cameraScale);
    final chunkElements = provider.getInteractiveElementsInChunk(
      _boardId,
      activeChunk,
      alwaysIncludeId: _editingElementId ?? _gestures.touchedNoteId,
    );
    final chunkChalk = provider.getChalkStrokesInChunk(_boardId, activeChunk);
    final boardBgHex = provider.getBoardBackgroundColor(_boardId);
    final boardBgColor = PizarronPalette.parseHex(boardBgHex, fallback: const Color(0xFF141820));

    final idx = _editingElementId == null ? -1 : provider.elements.indexWhere((e) => e.id == _editingElementId);
    final editingElement = idx != -1 ? provider.elements[idx] : null;

    return Scaffold(
      backgroundColor: boardBgColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _gestures.handlePointerDown(
              event: e,
              visibleElements: chunkElements,
              cameraPan: _camera.cameraPan,
              cameraScale: _camera.cameraScale,
              chalkMode: _chalkMode,
              editingElementId: _editingElementId,
              provider: provider,
              onStopCameraAnim: () => _camera.animController.stop(),
              onAddLiveChalkPoint: (pt) => setState(() => _liveChalkPoints..clear()..add(pt)),
            ),
            onPointerMove: (e) => _gestures.handlePointerMove(
              event: e,
              screenSize: size,
              cameraPan: _camera.cameraPan,
              cameraScale: _camera.cameraScale,
              minScale: PizarronCameraController.minScale,
              maxScale: PizarronCameraController.maxScale,
              chalkMode: _chalkMode,
              editingElementId: _editingElementId,
              provider: provider,
              onCameraUpdated: (p, s) => setState(() {
                _camera.cameraPan = p;
                _camera.cameraScale = s;
              }),
              onCameraPanBy: (d) => setState(() => _camera.cameraPan += d),
              onAddLiveChalkPoint: (pt) => setState(() => _liveChalkPoints.add(pt)),
            ),
            onPointerUp: (e) => _handlePointerUp(e, size, provider),
            onPointerCancel: (e) => _handlePointerUp(e, size, provider),
            onPointerSignal: _camera.handlePointerSignal,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: BoardChalkBackgroundPainter(
                      worldToScreenMatrix: PizarronCameraMath.worldToScreenMatrix(_camera.cameraPan, _camera.cameraScale),
                      activeWorldChunkRect: activeChunk,
                      boardBackgroundColor: boardBgColor,
                      activeChalkStrokes: chunkChalk,
                      currentLiveStroke: _liveChalkPoints,
                      currentChalkColorHex: _chalkColorHex,
                      currentChalkWidth: _chalkStrokeWidth,
                    ),
                    size: Size.infinite,
                  ),
                ),
                Transform(
                  transform: PizarronCameraMath.worldToScreenMatrix(_camera.cameraPan, _camera.cameraScale),
                  alignment: Alignment.topLeft,
                  child: UnboundedHitTestStack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final el in chunkElements)
                        PizarronPositionedNote(
                          el: el,
                          isEditing: _editingElementId != null && _editingElementId == el.id,
                          cameraScale: _camera.cameraScale,
                          activeTextTarget: _activeTextTarget,
                          provider: provider,
                          onActiveTargetChanged: (t) => setState(() => _activeTextTarget = t),
                          onFocusAndEdit: (t) => _focusAndEditElement(el, size, initialTarget: t),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (editingElement != null)
            Align(
              alignment: Alignment.centerRight,
              child: PizarronSidebarOverlay(
                config: NoteStyleConfig.fromElement(fallbackColor: editingElement.color, data: editingElement.data),
                activeTarget: _activeTextTarget,
                onTargetChanged: (t) => setState(() => _activeTextTarget = t),
                onConfigChanged: (c) => provider.updateElement(
                  editingElement.copyWith(color: c.solidColor, data: c.toDataMap()),
                ),
                onPickBackgroundImage: () => PizarronElementOps.pickAndApplyImage(
                  isBackground: true,
                  element: editingElement,
                  provider: provider,
                ),
                onPickInlineImage: () => PizarronElementOps.pickAndApplyImage(
                  isBackground: false,
                  element: editingElement,
                  provider: provider,
                ),
                onDuplicate: () async {
                  final copy = await provider.duplicateElement(editingElement.id!);
                  if (copy != null && mounted) _focusAndEditElement(copy, size);
                },
                onDelete: () async {
                  final id = editingElement.id;
                  _closeEditMode();
                  if (id != null) await provider.deleteElement(id);
                },
                onCloseEdit: _closeEditMode,
              ),
            ),
          if (editingElement == null)
            Positioned(
              right: 20,
              bottom: 24,
              child: PizarronBottomCluster(
                boardId: _boardId,
                plusMenuOpen: _plusMenuOpen,
                settingsOpen: _settingsOpen,
                chalkMode: _chalkMode,
                chalkColorHex: _chalkColorHex,
                chalkStrokeWidth: _chalkStrokeWidth,
                currentBoardBgHex: boardBgHex,
                provider: provider,
                onTogglePlus: () => setState(() {
                  _chalkMode ? _chalkMode = _settingsOpen = _plusMenuOpen = false : _plusMenuOpen = !_plusMenuOpen;
                  if (!_plusMenuOpen) _settingsOpen = false;
                }),
                onToggleSettings: () => setState(() {
                  _settingsOpen = !_settingsOpen;
                  if (!_settingsOpen) _chalkMode = false;
                }),
                onToggleChalk: () => setState(() => _chalkMode = !_chalkMode),
                onChalkColorChanged: (hex) => setState(() => _chalkColorHex = hex),
                onChalkWidthChanged: (v) => setState(() => _chalkStrokeWidth = v),
                onCreateNote: () => _createNew('note', size, provider),
                onCreateChecklist: () => _createNew('checklist', size, provider),
              ),
            ),
        ],
      ),
    );
  }

  void _handlePointerUp(PointerEvent e, Size size, BoardDataProvider provider) {
    _gestures.handlePointerUpOrCancel(
      event: e,
      screenSize: size,
      cameraPan: _camera.cameraPan,
      cameraScale: _camera.cameraScale,
      editingElementId: _editingElementId,
      provider: provider,
      onChalkStrokeCompleted: () {
        if (_chalkMode && _liveChalkPoints.isNotEmpty) {
          final pts = List<Offset>.from(_liveChalkPoints);
          setState(() => _liveChalkPoints.clear());
          provider.addChalkStroke(
            boardId: _boardId,
            points: pts,
            colorHex: _chalkColorHex,
            strokeWidth: _chalkStrokeWidth,
          );
        }
      },
      onEditNote: (el, target) => _focusAndEditElement(el, size, initialTarget: target),
      onActiveTargetChanged: (target) => setState(() => _activeTextTarget = target),
      onCloseEditMode: _closeEditMode,
      onCloseMenus: () {
        if (_plusMenuOpen || _settingsOpen) setState(() => _plusMenuOpen = _settingsOpen = false);
      },
    );
  }
}
