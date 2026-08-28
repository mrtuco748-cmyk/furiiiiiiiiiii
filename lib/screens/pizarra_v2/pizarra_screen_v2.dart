import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/board_provider_v2.dart';
import '../../models/board_element_v2.dart';
import '../../models/board_element_data.dart';
import '../../app_state.dart';
import 'note/note_card_modal.dart';
import 'widgets/board_tools_menu.dart';
import 'widgets/board_header.dart';
import 'widgets/board_list_view.dart';
import 'widgets/board_timeline_view.dart';
import 'widgets/board_archived_view.dart';
import 'widgets/board_search_panel.dart';
import 'widgets/board_activity_panel.dart';
import 'widgets/board_element_options.dart';
import 'renderers/board_checklist_renderer.dart';
import 'renderers/board_drawing_renderer.dart';
import 'renderers/board_video_renderer.dart';
import 'renderers/board_audio_renderer.dart';
import 'renderers/board_connector_renderer.dart';
import 'editors/board_drawing_editor.dart';
import 'editors/board_audio_editor.dart';
import 'editors/board_video_search.dart';

enum BoardViewMode { canvas, list, timeline, archived }

const _boardBg = Color(0xFF0A0A0A);
const _dotColor = Color(0xFF333333);
const _accentCyan = Color(0xFF00F0FF);
const _dangerRed = Color(0xFFFF5757);

class PizarraScreenV2 extends StatefulWidget {
  const PizarraScreenV2({super.key});

  @override
  State<PizarraScreenV2> createState() => _PizarraScreenV2State();
}

class _PizarraScreenV2State extends State<PizarraScreenV2> {
  final _transformController = TransformationController();
  final _visibleRect = ValueNotifier<Rect>(Rect.zero);

  bool _showNote = false;
  int? _editingNoteId;
  double _newNoteX = 200;
  double _newNoteY = 200;
  bool _isDraggingElement = false;

  bool _showDrawingEditor = false;
  int? _drawingTargetId;
  bool _showAudioEditor = false;
  int? _audioTargetId;
  bool _showVideoDialog = false;
  int? _videoEditId;

  bool _connectorMode = false;
  int? _connectorFromId;

  BoardViewMode _viewMode = BoardViewMode.canvas;
  bool _searchOpen = false;
  String _searchText = '';
  bool _activityOpen = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToCenter();
      context.read<BoardProviderV2>().load();
    });
  }

  void _onTransformChanged() {
    final matrix = _transformController.value;
    final inverse = Matrix4.inverted(matrix);
    final screenSize = MediaQuery.of(context).size;
    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(screenSize.width, screenSize.height),
    );
    _visibleRect.value = Rect.fromLTRB(
      topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy,
    );
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _visibleRect.dispose();
    super.dispose();
  }

  void _goToCenter() {
    if (!mounted) return;
    final s = MediaQuery.of(context).size;
    _transformController.value =
        Matrix4.translationValues(s.width / 2, s.height / 2, 0);
  }

  Offset _screenCenterToWorld() {
    final s = MediaQuery.of(context).size;
    final inverse = Matrix4.inverted(_transformController.value);
    return MatrixUtils.transformPoint(
      inverse,
      Offset(s.width / 2 - 100, s.height / 2 - 60),
    );
  }

  // ▸▸▸ Creación de elementos ▸▸▸

  void _createNote() {
    final p = _screenCenterToWorld();
    setState(() {
      _editingNoteId = null;
      _newNoteX = p.dx;
      _newNoteY = p.dy;
      _showNote = true;
    });
    HapticFeedback.heavyImpact();
  }

  void _createChecklist() {
    final p = _screenCenterToWorld();
    context.read<BoardProviderV2>().add(BoardElementV2(
          type: BoardElementType.checklist,
          title: 'Checklist',
          x: p.dx,
          y: p.dy,
          color: '#7B2D8E',
          userId: AppState.myId,
          isNew: true,
          data: ChecklistData(items: [
            ChecklistItem(id: '1', text: 'Nuevo item'),
          ]).toMap(),
        ));
    HapticFeedback.heavyImpact();
  }

  void _createDrawing() {
    final p = _screenCenterToWorld();
    context.read<BoardProviderV2>().add(BoardElementV2(
          type: BoardElementType.drawing,
          title: 'Dibujo',
          x: p.dx,
          y: p.dy,
          width: 300,
          height: 200,
          userId: AppState.myId,
          isNew: true,
          data: DrawingData().toMap(),
        ));
    setState(() {
      _drawingTargetId = null;
      _showDrawingEditor = true;
    });
    HapticFeedback.heavyImpact();
  }

  void _createAudio() {
    final p = _screenCenterToWorld();
    context.read<BoardProviderV2>().add(BoardElementV2(
          type: BoardElementType.audio,
          title: 'Audio',
          x: p.dx,
          y: p.dy,
          width: 280,
          height: 80,
          userId: AppState.myId,
          isNew: true,
          data: AudioData().toMap(),
        ));
    setState(() {
      _audioTargetId = null;
      _showAudioEditor = true;
    });
    HapticFeedback.heavyImpact();
  }

  void _createVideo() {
    setState(() {
      _showVideoDialog = true;
      _videoEditId = null;
    });
    HapticFeedback.heavyImpact();
  }

  void _editVideo(BoardElementV2 el) {
    setState(() {
      _showVideoDialog = true;
      _videoEditId = el.id;
    });
    HapticFeedback.selectionClick();
  }

  void _enterConnectorMode() {
    setState(() {
      _connectorMode = true;
      _connectorFromId = null;
    });
    HapticFeedback.heavyImpact();
  }

  Future<void> _createSubBoard() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            hintText: 'Nombre del tablero...',
            hintStyle: TextStyle(color: Colors.white54, fontFamily: 'monospace'),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Crear',
                style: TextStyle(color: Color(0xFF4FC3F7))),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final p = _screenCenterToWorld();
    if (!mounted) return;
    final pv = context.read<BoardProviderV2>();
    final boardId = await pv.createBoard(name, pv.boardId);
    if (boardId == null) return;

    await pv.add(BoardElementV2(
      type: BoardElementType.subBoard,
      title: name,
      x: p.dx,
      y: p.dy,
      width: 160,
      height: 100,
      color: '#2D3A5C',
      userId: AppState.myId,
      isNew: true,
      data: SubBoardData(boardId: boardId).toMap(),
    ));
    HapticFeedback.heavyImpact();
  }

  void _createSeparator() {
    final p = _screenCenterToWorld();
    context.read<BoardProviderV2>().add(BoardElementV2(
          type: BoardElementType.separator,
          title: '',
          x: p.dx,
          y: p.dy,
          width: 300,
          height: 2,
          userId: AppState.myId,
          isNew: true,
          data: SeparatorData(orientation: 'horizontal').toMap(),
        ));
    HapticFeedback.heavyImpact();
  }

  void _openSubBoard(BoardElementV2 el) {
    final data = SubBoardData.fromMap(el.data);
    final targetId = data.boardId;
    if (targetId == null) return;
    final pv = context.read<BoardProviderV2>();
    pv.setBoard(targetId);
    _goToCenter();
    HapticFeedback.heavyImpact();
  }

  void _toggleSeparator(BoardElementV2 el) {
    final pv = context.read<BoardProviderV2>();
    final data = SeparatorData.fromMap(el.data);
    final horizontal = data.orientation != 'vertical';
    final live = _liveElement(pv, el);
    pv.update(live.copyWith(
      width: horizontal ? (live.width ?? 300) : 2,
      height: horizontal ? 2 : (live.height ?? 200),
      data: SeparatorData(orientation: horizontal ? 'vertical' : 'horizontal')
          .toMap(),
    ));
    HapticFeedback.selectionClick();
  }

  void _cancelConnectorMode() {
    setState(() {
      _connectorMode = false;
      _connectorFromId = null;
    });
  }

  // ▸▸▸ Interacción con elementos ▸▸▸

  void _onElementTap(BoardElementV2 el) {
    if (_connectorMode) {
      _handleConnectorSelect(el);
      return;
    }
    if (el.isNew && el.id != null) {
      context.read<BoardProviderV2>().markAsSeen(el.id!);
    }
    switch (el.type) {
      case BoardElementType.note:
        _openExistingNote(el.id ?? 0);
        break;
      case BoardElementType.drawing:
        setState(() {
          _drawingTargetId = el.id;
          _showDrawingEditor = true;
        });
        break;
      case BoardElementType.video:
        _openVideo(el);
        break;
      case BoardElementType.audio:
        break;
      case BoardElementType.checklist:
        break;
      case BoardElementType.subBoard:
        _openSubBoard(el);
        break;
      case BoardElementType.separator:
        _toggleSeparator(el);
        break;
      default:
        break;
    }
  }

  void _handleConnectorSelect(BoardElementV2 el) {
    if (el.id == null) return;
    if (_connectorFromId == null) {
      setState(() => _connectorFromId = el.id);
      HapticFeedback.selectionClick();
    } else if (el.id == _connectorFromId) {
      setState(() => _connectorFromId = null);
    } else {
      context.read<BoardProviderV2>().add(BoardElementV2(
            type: BoardElementType.connector,
            title: '',
            x: 0,
            y: 0,
            userId: AppState.myId,
            isNew: true,
            data: ConnectorData(
              fromId: _connectorFromId,
              toId: el.id,
              style: 'bezier',
            ).toMap(),
          ));
      setState(() {
        _connectorMode = false;
        _connectorFromId = null;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _openExistingNote(int id) {
    setState(() {
      _editingNoteId = id;
      _showNote = true;
    });
    HapticFeedback.selectionClick();
  }

  // Doble-tap = editar. Para video abre el editor de URL; para nota el modal.
  void _onElementDoubleTap(BoardElementV2 el) {
    if (_connectorMode) return;
    switch (el.type) {
      case BoardElementType.video:
        _editVideo(el);
        break;
      case BoardElementType.note:
        _openExistingNote(el.id ?? 0);
        break;
      default:
        break;
    }
  }

  Future<void> _openVideo(BoardElementV2 el) async {
    final data = VideoData.fromMap(el.data);
    if (data.url.isEmpty) return;
    final uri = Uri.tryParse(data.url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ▸▸▸ Build ▸▸▸

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _boardBg,
      body: Consumer<BoardProviderV2>(
        builder: (context, pv, _) {
          final world = _worldBounds(pv.allElements);
          return Stack(
            children: [
            ValueListenableBuilder<Rect>(
              valueListenable: _visibleRect,
              builder: (context, rect, _) => CustomPaint(
                painter: _GridPainter(transform: _transformController.value),
                size: MediaQuery.of(context).size,
              ),
            ),
            if (_viewMode == BoardViewMode.canvas) ...[
              // BUG USUARIO: El mundo es el bounding box de los elementos
              // (+padding), no un SizedBox fijo. Así las notas arrastradas a
              // cualquier distancia siguen dentro del área de hit test y del
              // pan del InteractiveViewer (antes: quedaban muertas >10000px).
              InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(0),
                constrained: false,
                minScale: 0.1,
                maxScale: 5.0,
                panEnabled: !_isDraggingElement,
                child: SizedBox(
                  width: world.width,
                  height: world.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (!pv.loading)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // Long-press sobre una línea de conector = borrar.
                          onLongPressStart: (d) => _onConnectorLongPress(
                              pv, d.localPosition, world),
                          child: Transform.translate(
                            offset: Offset(-world.left, -world.top),
                            child: CustomPaint(
                              painter: MultiConnectorPainter(
                                connectors: pv.allElements
                                    .where((e) =>
                                        e.type == BoardElementType.connector)
                                    .toList(),
                                allElements: pv.allElements,
                                visibleRect: _visibleRect.value,
                              ),
                              size: world.size,
                            ),
                          ),
                        ),
                      if (!pv.loading)
                        // Virtualización: solo se construyen los elementos
                        // dentro (o cerca) del viewport actual.
                        ValueListenableBuilder<Rect>(
                          valueListenable: _visibleRect,
                          builder: (context, visible, _) => Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final el in pv.elements.where((e) =>
                                  e.type != BoardElementType.connector))
                                if (_elementVisible(el, visible))
                                  Positioned(
                                    left: el.x - world.left,
                                    top: el.y - world.top,
                                    child: _buildElementCard(pv, el),
                                  ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (_viewMode == BoardViewMode.list)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: BoardListView(
                    provider: pv,
                    onGoToElement: _goToElement,
                  ),
                ),
              ),
            if (_viewMode == BoardViewMode.timeline)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: BoardTimelineView(
                    provider: pv,
                    onGoToElement: _goToElement,
                  ),
                ),
              ),
            if (_viewMode == BoardViewMode.archived)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: BoardArchivedView(
                    provider: pv,
                    onRestore: _restoreElement,
                  ),
                ),
              ),
            if (pv.hasError && _viewMode == BoardViewMode.canvas)
              _buildErrorBanner(pv),
            if (_connectorMode) _buildConnectorBanner(),
            BoardHeader(
              provider: pv,
              searchOpen: _searchOpen,
              onToggleSearch: () =>
                  setState(() => _searchOpen = !_searchOpen),
              onToggleActivity: _toggleActivity,
              onViewModeChanged: (mode) => setState(() {
                _viewMode = mode;
                _connectorMode = false;
                _connectorFromId = null;
                _searchOpen = false;
              }),
              currentViewMode: _viewMode,
            ),
            if (_viewMode == BoardViewMode.canvas && pv.parentBoardId != null)
              Positioned(
                left: 12,
                top: 64,
                child: GestureDetector(
                  onTap: () {
                    pv.goBackBoard();
                    _goToCenter();
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF1A1A1A), width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back,
                            color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Volver',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_viewMode == BoardViewMode.canvas)
              BoardToolsMenu(
                onCreateNote: _createNote,
                onCreateChecklist: _createChecklist,
                onCreateDrawing: _createDrawing,
                onCreateVideo: _createVideo,
                onCreateAudio: _createAudio,
                onCreateConnector: _enterConnectorMode,
                onCreateSubBoard: _createSubBoard,
                onCreateSeparator: _createSeparator,
              ),
            if (pv.loading)
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF39FF14))),
            if (_searchOpen)
              BoardSearchPanel(
                provider: pv,
                searchText: _searchText,
                onSearchChanged: (v) => setState(() => _searchText = v),
                onClose: () => setState(() => _searchOpen = false),
                onGoToElement: _goToElement,
              ),
            if (_activityOpen)
              BoardActivityPanel(
                activity: pv.activity,
                onClose: () => setState(() => _activityOpen = false),
              ),
            if (_showVideoDialog)
              BoardVideoSearchDialog(
                provider: pv,
                onClose: () => setState(() => _showVideoDialog = false),
                spawnX: _screenCenterToWorld().dx,
                spawnY: _screenCenterToWorld().dy,
                editElementId: _videoEditId,
              ),
            if (_showDrawingEditor)
              BoardDrawingEditor(
                provider: pv,
                targetId: _drawingTargetId,
                onClose: () => setState(() => _showDrawingEditor = false),
              ),
            if (_showAudioEditor)
              BoardAudioEditor(
                provider: pv,
                targetId: _audioTargetId,
                onClose: () => setState(() => _showAudioEditor = false),
              ),
            if (_showNote)
              NoteCardModal(
                noteId: _editingNoteId,
                initialX: _newNoteX,
                initialY: _newNoteY,
                onClose: () => setState(() => _showNote = false),
              ),
          ],
          );
        },
      ),
    );
  }

  void _toggleActivity() {
    if (!_activityOpen) {
      context.read<BoardProviderV2>().loadActivity();
    }
    setState(() => _activityOpen = !_activityOpen);
  }

  void _restoreElement(BoardElementV2 el) {
    if (el.id == null) return;
    context.read<BoardProviderV2>().toggleArchive(el.id!);
    HapticFeedback.selectionClick();
  }

  void _goToElement(BoardElementV2 el) {
    final pv = context.read<BoardProviderV2>();
    setState(() {
      _viewMode = BoardViewMode.canvas;
      _searchOpen = false;
      _searchText = '';
    });
    HapticFeedback.selectionClick();
    // BUG 8: Si el elemento está en otro tablero, cambiar al tablero.
    if (el.boardId != pv.boardId) {
      pv.setBoard(el.boardId);
    }
    final s = MediaQuery.of(context).size;
    final targetX = el.x + (el.width ?? 180) / 2;
    final targetY = el.y + (el.height ?? 110) / 2;
    _transformController.value = Matrix4.translationValues(
      s.width / 2 - targetX,
      s.height / 2 - targetY,
      0,
    );
  }

  Widget _buildErrorBanner(BoardProviderV2 pv) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _dangerRed,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _dangerRed, width: 2),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'No se pudo cargar la pizarra',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => pv.load(),
              child: const Icon(Icons.refresh,
                  color: Color(0xFF0A0A0A), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorBanner() {
    final selectingDestination = _connectorFromId != null;
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _accentCyan,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentCyan, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectingDestination
                    ? 'Tocá el elemento de DESTINO'
                    : 'Tocá el elemento de ORIGEN',
                style: const TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: _cancelConnectorMode,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0A0A0A), width: 1.5),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ▸▸▸ Cards de elemento ▸▸▸

  Widget _buildElementCard(BoardProviderV2 pv, BoardElementV2 el) {
    final highlight =
        _connectorMode && (_connectorFromId == el.id || _connectorFromId == null);
    final reactions = BoardSocialData.reactionsOf(el.data);
    return Positioned(
      left: el.x,
      top: el.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onElementTap(el),
        onDoubleTap: () => _onElementDoubleTap(el),
        onLongPress: () => showElementOptionsSheet(context, pv, el),
        onPanStart: (_) => setState(() => _isDraggingElement = true),
        onPanUpdate: (d) {
          // BUG 4: Usar la posición del elemento vivo, no el snapshot del build.
          final live = _liveElement(pv, el);
          pv.moveLocal(live, live.x + d.delta.dx, live.y + d.delta.dy);
        },
        onPanEnd: (_) => setState(() => _isDraggingElement = false),
        onPanCancel: () => setState(() => _isDraggingElement = false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: highlight
                      ? BoxDecoration(
                          border: Border.all(color: _accentCyan, width: 2),
                          borderRadius: BorderRadius.circular(18),
                        )
                      : null,
                  padding: highlight ? const EdgeInsets.all(3) : EdgeInsets.zero,
                  child: _elementBody(pv, el),
                ),
                if (reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        for (final entry in reactions.entries)
                          Builder(builder: (inner) {
                            final mine =
                                entry.value.contains(AppState.myId);
                            final chipColor = mine
                                ? _accentCyan
                                : const Color(0xFF2A2A2A);
                            final textColor = mine
                                ? const Color(0xFF0A0A0A)
                                : Colors.white;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: chipColor, width: 1),
                              ),
                              child: Text(
                                entry.value.length > 1
                                    ? '${entry.key} ${entry.value.length}'
                                    : entry.key,
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: mine
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
              ],
            ),
            if (el.isNew)
              Positioned(
                top: -10,
                left: -10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFF39FF14), width: 1.5),
                  ),
                  child: const Text(
                    'NUEVO',
                    style: TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _authorColor(el.userId ?? ''),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                ),
                child: Center(
                  child: Text(
                    el.authorInitial,
                    style: const TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _authorColor(String uid) {
    final u = uid.toLowerCase();
    if (u.contains('facu')) return const Color(0xFF4FC3F7);
    if (u.contains('rocio')) return const Color(0xFFCE93D8);
    return const Color(0xFF4FC3F7);
  }

  Widget _elementBody(BoardProviderV2 pv, BoardElementV2 el) {
    switch (el.type) {
      case BoardElementType.note:
        return _noteBody(el);
      case BoardElementType.checklist:
        return BoardChecklistRenderer(
          element: el,
          onDataChanged: (data) =>
              pv.update(_liveElement(pv, el).copyWith(data: data.toMap())),
        );
      case BoardElementType.drawing:
        return BoardDrawingRenderer(element: el);
      case BoardElementType.video:
        return BoardVideoRenderer(element: el);
      case BoardElementType.audio:
        return BoardAudioRenderer(element: el);
      case BoardElementType.subBoard:
        return _subBoardBody(el);
      case BoardElementType.separator:
        return _separatorBody(el);
      default:
        return _noteBody(el);
    }
  }

  Widget _subBoardBody(BoardElementV2 el) {
    final bg = _parseColor(el.color) ?? const Color(0xFF2D3A5C);
    final title = el.title.isNotEmpty ? el.title : 'Sub-tablero';
    return Container(
      width: el.width ?? 160,
      height: el.height ?? 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bg, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.white70, size: 22),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _separatorBody(BoardElementV2 el) {
    final color = _parseColor(el.color) ?? const Color(0xFF9D00FF);
    final data = SeparatorData.fromMap(el.data);
    final horizontal = data.orientation != 'vertical';
    final w = horizontal ? (el.width ?? 300) : (el.height ?? 2);
    final h = horizontal ? (el.height ?? 2) : (el.width ?? 200);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color, width: 1),
      ),
    );
  }

  Widget _noteBody(BoardElementV2 el) {
    final color = _parseColor(el.color) ?? const Color(0xFF5C2D91);
    final shape = (el.data['shape'] as String?) ?? 'Rectángulo';
    final preview =
        el.content.length > 120 ? '${el.content.substring(0, 120)}...' : el.content;
    final title = el.title.isNotEmpty ? el.title : 'Sin título';
    final bgState = el.data['bgState'] as Map? ?? {};
    final borderState = el.data['borderState'] as Map? ?? {};
    final gradientType = (bgState['gradientType'] as String?) ?? 'Liso';

    // Patrón (misma configuración que en el editor de fondo del modal).
    final patternEnabled = (bgState['patternEnabled'] as bool?) ?? false;
    final selectedPattern = (bgState['selectedPattern'] as String?) ?? 'Puntos';
    final patternThickness = (bgState['patternThickness'] as num?)?.toDouble() ?? 1.5;
    final patternAngle = (bgState['patternAngle'] as num?)?.toDouble() ?? 0.0;
    final patternSize = (bgState['patternSize'] as num?)?.toDouble() ?? 40.0;
    final patternOpacity = (bgState['patternOpacity'] as num?)?.toDouble() ?? 0.25;
    final patternSpacing = (bgState['patternSpacing'] as num?)?.toDouble() ?? 24.0;
    final patternSaturation = (bgState['patternSaturation'] as num?)?.toDouble() ?? 1.0;
    final customPattern = bgState['customPattern'] as String?;

    // Borde (misma configuración que en el editor de borde del modal).
    final borderOn = (borderState['borderEnabled'] as bool?) ?? false;
    final borderColor = _parseDynamicColor(borderState['borderColor']) ?? color;
    final borderW = (borderState['borderWidth'] as num?)?.toDouble() ?? 2.0;
    final borderType = (borderState['borderType'] as String?)?.toLowerCase() ?? 'sólido';
    final borderSpacing = (borderState['borderSpacing'] as num?)?.toDouble() ?? 4.0;

    // Aplicar el estilo real de la nota (fuente, tamaño, color, alineación),
    // como en el modal de edición.
    final fontFamily = el.fontFamily ?? 'monospace';
    final Color textColor;
    if (el.textColor is int) {
      textColor = Color(el.textColor as int);
    } else {
      textColor = _textColorForBg(color);
    }
    final fontScale = (el.fontSize ?? 14) / 14.0;
    final titleSize = (12 * fontScale).clamp(11.0, 26.0);
    final bodySize = (10 * fontScale).clamp(9.0, 20.0);
    final align = el.textAlign is TextAlign
        ? el.textAlign as TextAlign
        : TextAlign.left;
    final imagePath = el.data['imagePath'] as String?;

    BoxDecoration decoration = BoxDecoration(
        color: color, borderRadius: _noteCardRadius(shape));

    if (gradientType == 'Lineal') {
      final gs = _parseDynamicColor(bgState['gradientStart']) ?? color;
      final gm = _parseDynamicColor(bgState['gradientMid']) ?? color;
      final ge = _parseDynamicColor(bgState['gradientEnd']) ?? color;
      decoration = decoration.copyWith(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gs, gm, ge]),
      );
    } else if (gradientType == 'Radial') {
      final gs = _parseDynamicColor(bgState['gradientStart']) ?? color;
      final gm = _parseDynamicColor(bgState['gradientMid']) ?? color;
      final ge = _parseDynamicColor(bgState['gradientEnd']) ?? color;
      decoration = decoration.copyWith(
        gradient: RadialGradient(
            center: Alignment.center, radius: 1.0, colors: [gs, gm, ge]),
      );
    }

    final card = Container(
      width: (el.width ?? 200),
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(10),
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null && imagePath.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: align,
              style: TextStyle(
                  color: textColor,
                  fontFamily: fontFamily,
                  fontSize: titleSize,
                  height: 1.1,
                  fontWeight: el.isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: el.isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration:
                      el.isUnderline ? TextDecoration.underline : null)),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(preview,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                textAlign: align,
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontFamily: fontFamily,
                    fontSize: bodySize,
                    height: 1.25)),
          ],
        ],
      ),
    );

    return ClipPath(
      clipper: _MiniShapeClipper(shape, _noteCardRadius(shape)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          if (patternEnabled)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BoardPatternPainter(
                    pattern: selectedPattern,
                    thickness: patternThickness,
                    angle: patternAngle,
                    dotSize: patternSize,
                    opacity: patternOpacity,
                    spacing: patternSpacing,
                    saturation: patternSaturation,
                    customText: customPattern,
                  ),
                ),
              ),
            ),
          if (borderOn)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BoardCardBorderPainter(
                    color: borderColor,
                    width: borderW,
                    type: borderType,
                    spacing: borderSpacing,
                    shape: shape,
                    radius: _noteCardRadius(shape),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ▸▸▸ Helpers ▸▸▸

  Color? _parseDynamicColor(dynamic val) {
    if (val is Color) return val;
    if (val is int) return Color(val);
    if (val is String) return _parseColor(val);
    return null;
  }

  BoardElementV2 _liveElement(BoardProviderV2 pv, BoardElementV2 el) {
    for (final e in pv.elements) {
      if (e.id == el.id) return e;
    }
    for (final e in pv.elements) {
      if (e.createdAt == el.createdAt) return e;
    }
    return el;
  }

  // ▸▸▸ Mundo dinámico (bounding box) ▸▸▸

  /// Rect que contiene todos los elementos del tablero actual + padding.
  /// Clampada a [-50000, 50000] para no crear capas gigantes de pintura.
  Rect _worldBounds(List<BoardElementV2> els) {
    const pad = 800.0;
    var minX = 0.0, minY = 0.0, maxX = 2000.0, maxY = 2000.0;
    for (final e in els) {
      final w = e.width ?? 180.0;
      final h = e.height ?? 110.0;
      minX = math.min(minX, e.x);
      minY = math.min(minY, e.y);
      maxX = math.max(maxX, e.x + w);
      maxY = math.max(maxY, e.y + h);
    }
    minX = math.max(minX, -50000);
    minY = math.max(minY, -50000);
    maxX = math.min(maxX, 50000);
    maxY = math.min(maxY, 50000);
    return Rect.fromLTRB(minX - pad, minY - pad, maxX + pad, maxY + pad);
  }

  /// Virtualización: true si el rect del elemento intersecta el viewport.
  bool _elementVisible(BoardElementV2 el, Rect viewport) {
    final r = Rect.fromLTWH(
        el.x, el.y, el.width ?? 180, el.height ?? 110);
    return r.overlaps(viewport.inflate(400));
  }

  /// Long-press en la capa de conectores: busca la línea más cercana al
  /// punto y ofrece eliminarla (con confirmación).
  void _onConnectorLongPress(
      BoardProviderV2 pv, Offset local, Rect world) {
    for (final c in pv.allElements) {
      if (c.type != BoardElementType.connector || c.id == null) continue;
      final data = ConnectorData.fromMap(c.data);
      final fromEl = _findById(pv.allElements, data.fromId);
      final toEl = _findById(pv.allElements, data.toId);
      if (fromEl == null || toEl == null) continue;
      final a = Offset(
        fromEl.x - world.left + (fromEl.width ?? 180) / 2,
        fromEl.y - world.top + (fromEl.height ?? 110) / 2,
      );
      final b = Offset(
        toEl.x - world.left + (toEl.width ?? 180) / 2,
        toEl.y - world.top + (toEl.height ?? 110) / 2,
      );
      if (_distanceToSegment(local, a, b) < 20) {
        _confirmDeleteConnector(c.id!);
        HapticFeedback.heavyImpact();
        return;
      }
    }
  }

  BoardElementV2? _findById(List<BoardElementV2> els, int? id) {
    if (id == null) return null;
    for (final e in els) {
      if (e.id == id) return e;
    }
    return null;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  void _confirmDeleteConnector(int id) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Eliminar conector?',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF2A2A2A), width: 1.5),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      context.read<BoardProviderV2>().delete(id);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5757),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFF5757), width: 1.5),
                      ),
                      child: const Text('Eliminar',
                          style: TextStyle(
                              color: Color(0xFF0A0A0A),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _textColorForBg(Color bg) {
    final lum = (0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b);
    return lum > 0.55 ? const Color(0xFF0A0A0A) : Colors.white;
  }

  BorderRadius _noteCardRadius(String shape) {
    switch (shape) {
      case 'Cuadrado':
        return BorderRadius.circular(4);
      case 'Círculo':
        return BorderRadius.circular(200);
      case 'Óvalo':
        return BorderRadius.circular(80);
      default:
        return BorderRadius.circular(14);
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      final intVal = int.tryParse('FF$cleaned', radix: 16);
      return intVal != null ? Color(intVal) : null;
    }
    if (cleaned.length == 8) {
      final intVal = int.tryParse(cleaned, radix: 16);
      return intVal != null ? Color(intVal) : null;
    }
    return null;
  }
}

class _GridPainter extends CustomPainter {
  final Matrix4 transform;
  _GridPainter({Matrix4? transform})
      : transform = transform ?? Matrix4.identity();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _dotColor
      ..strokeWidth = 1.5;
    const spacing = 30.0;
    final inv = Matrix4.inverted(transform);
    final tl = MatrixUtils.transformPoint(inv, Offset.zero);
    final br = MatrixUtils.transformPoint(
      inv,
      Offset(size.width, size.height),
    );
    final startX = (tl.dx / spacing).floor() * spacing;
    final startY = (tl.dy / spacing).floor() * spacing;
    final endX = (br.dx / spacing).ceil() * spacing;
    final endY = (br.dy / spacing).ceil() * spacing;
    for (double x = startX; x <= endX; x += spacing) {
      for (double y = startY; y <= endY; y += spacing) {
        final p = MatrixUtils.transformPoint(transform, Offset(x, y));
        canvas.drawCircle(p, 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.transform != transform;
}

class _MiniShapeClipper extends CustomClipper<Path> {
  final String shape;
  final BorderRadius radius;
  _MiniShapeClipper(this.shape, this.radius);

  @override
  Path getClip(Size size) {
    final r = (size.width < size.height ? size.width : size.height) / 2;
    switch (shape) {
      case 'Círculo':
      case 'Óvalo':
        return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
      case 'Diamante':
        return Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
      case 'Hexágono':
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60 - 30) * math.pi / 180;
          final x = size.width / 2 + r * math.cos(angle);
          final y = size.height / 2 + r * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        return path;
      default:
        return Path()
          ..addRRect(
              RRect.fromRectAndRadius(Offset.zero & size, radius.topLeft));
    }
  }

  @override
  bool shouldReclip(covariant _MiniShapeClipper old) =>
      old.shape != shape || old.radius != radius;
}

class _BoardPatternPainter extends CustomPainter {
  final String pattern;
  final double thickness;
  final double angle;
  final double dotSize;
  final double opacity;
  final double spacing;
  final double saturation;
  final String? customText;

  _BoardPatternPainter({
    required this.pattern,
    this.thickness = 1.5,
    this.angle = 0,
    this.dotSize = 40,
    this.opacity = 0.25,
    this.spacing = 24,
    this.saturation = 1.0,
    this.customText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final spacingUse = spacing > 0 ? spacing : dotSize;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle * math.pi / 180);

    switch (pattern) {
      case 'Puntos':
        _drawDots(canvas, size, paint, spacingUse);
      case 'Líneas H':
        _drawHLines(canvas, size, paint, spacingUse);
      case 'Líneas V':
        _drawVLines(canvas, size, paint, spacingUse);
      case 'Cuadrícula':
        _drawHLines(canvas, size, paint, spacingUse);
        _drawVLines(canvas, size, paint, spacingUse);
      case 'Diagonales':
        _drawHLines(canvas, size, paint, spacingUse);
        _drawDiagonals(canvas, size, paint, spacingUse);
      case 'Zigzag':
        _drawZigzag(canvas, size, paint, spacingUse);
      case 'Diamantes':
        _drawDiamonds(canvas, size, paint, spacingUse);
      case 'Ondas':
        _drawWaves(canvas, size, paint, spacingUse);
      case 'Círculos':
        _drawCircles(canvas, size, paint, spacingUse);
      case 'Triángulos':
        _drawTriangles(canvas, size, paint, spacingUse);
      case 'Rayas':
        _drawHLines(canvas, size, paint, spacingUse * 2);
      case 'Panal':
        _drawHexagons(canvas, size, paint, spacingUse);
      default:
        if (customText != null && customText!.isNotEmpty) {
          _drawCustom(canvas, size, customText!, opacity);
        }
    }
    canvas.restore();
  }

  void _drawDots(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    final h = size.width + size.height;
    for (double x = -w / 2; x < w / 2; x += sp) {
      for (double y = -h / 2; y < h / 2; y += sp) {
        canvas.drawCircle(Offset(x, y), dotSize / 8,
            Paint()..color = paint.color..style = PaintingStyle.fill);
      }
    }
  }

  void _drawHLines(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    for (double y = -w / 2; y < w / 2; y += sp) {
      canvas.drawLine(Offset(-w / 2, y), Offset(w / 2, y), paint);
    }
  }

  void _drawVLines(Canvas canvas, Size size, Paint paint, double sp) {
    final h = size.width + size.height;
    for (double x = -h / 2; x < h / 2; x += sp) {
      canvas.drawLine(Offset(x, -h / 2), Offset(x, h / 2), paint);
    }
  }

  void _drawZigzag(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    for (double y = -w / 2; y < w / 2; y += sp * 2) {
      final path = Path();
      path.moveTo(-w / 2, y);
      for (double x = -w / 2; x < w / 2; x += sp) {
        final dy = (x / sp).floor().isEven ? sp / 2 : -sp / 2;
        path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawDiamonds(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    final fillPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    for (double x = -w / 2; x < w / 2; x += sp) {
      for (double y = -w / 2; y < w / 2; y += sp) {
        final path = Path()
          ..moveTo(x, y - dotSize / 4)
          ..lineTo(x + dotSize / 4, y)
          ..lineTo(x, y + dotSize / 4)
          ..lineTo(x - dotSize / 4, y)
          ..close();
        canvas.drawPath(path, fillPaint);
      }
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    for (double y = -w / 2; y < w / 2; y += sp * 1.5) {
      final path = Path();
      path.moveTo(-w / 2, y);
      for (double x = -w / 2; x <= w / 2; x += 2) {
        path.lineTo(x, y + math.sin(x / sp) * sp / 3);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawCustom(Canvas canvas, Size size, String text, double op) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: Colors.white.withValues(alpha: op), fontSize: dotSize),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: size.width + size.height);
    final w = size.width + size.height;
    final h = size.width + size.height;
    for (double x = -w / 2; x < w / 2; x += spacing * 2) {
      for (double y = -h / 2; y < h / 2; y += spacing * 2) {
        tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      }
    }
  }

  void _drawDiagonals(Canvas canvas, Size size, Paint paint, double sp) {
    final d = size.width + size.height;
    for (double off = -d; off < d * 2; off += sp * 2) {
      canvas.drawLine(Offset(off, -d), Offset(off + d, d), paint);
    }
  }

  void _drawCircles(Canvas canvas, Size size, Paint paint, double sp) {
    final d = size.width + size.height;
    for (double x = -d / 2; x < d / 2; x += sp * 2) {
      for (double y = -d / 2; y < d / 2; y += sp * 2) {
        canvas.drawCircle(Offset(x, y), dotSize / 3, paint);
      }
    }
  }

  void _drawTriangles(Canvas canvas, Size size, Paint paint, double sp) {
    final fillPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    final d = size.width + size.height;
    for (double x = -d / 2; x < d / 2; x += sp * 1.5) {
      for (double y = -d / 2; y < d / 2; y += sp * 1.5) {
        final path = Path()
          ..moveTo(x, y - dotSize / 3)
          ..lineTo(x + dotSize / 3, y + dotSize / 4)
          ..lineTo(x - dotSize / 3, y + dotSize / 4)
          ..close();
        canvas.drawPath(path, fillPaint);
      }
    }
  }

  void _drawHexagons(Canvas canvas, Size size, Paint paint, double sp) {
    final strokePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke;
    final d = size.width + size.height;
    for (double cx = -d / 2; cx < d / 2; cx += sp * 1.8) {
      for (double cy = -d / 2; cy < d / 2; cy += sp * 1.6) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (i * 60 - 30) * math.pi / 180;
          final px = cx + dotSize / 3 * math.cos(a);
          final py = cy + dotSize / 3 * math.sin(a);
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPatternPainter old) =>
      pattern != old.pattern ||
      thickness != old.thickness ||
      angle != old.angle ||
      dotSize != old.dotSize ||
      opacity != old.opacity ||
      spacing != old.spacing ||
      saturation != old.saturation ||
      customText != old.customText;
}

class _BoardCardBorderPainter extends CustomPainter {
  final Color color;
  final double width;
  final String type;
  final double spacing;
  final String shape;
  final BorderRadius radius;

  _BoardCardBorderPainter({
    required this.color,
    required this.width,
    required this.type,
    required this.spacing,
    required this.shape,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;

    final rect = RRect.fromRectAndRadius(Offset.zero & size, radius.topLeft);

    switch (type) {
      case 'punteado':
        _drawDotted(canvas, rect, paint);
        break;
      case 'dashed':
        _drawDashed(canvas, rect, paint);
        break;
      case 'doble':
        _drawDouble(canvas, rect, paint);
        break;
      case 'ondulado':
        _drawWavyBorder(canvas, rect, paint);
        break;
      case 'relieve':
        _drawRelief(canvas, rect, paint);
        break;
      default:
        _drawSolid(canvas, rect, paint);
    }
  }

  void _drawSolid(Canvas canvas, RRect rect, Paint paint) {
    canvas.drawRRect(rect, paint);
  }

  void _drawDotted(Canvas canvas, RRect rect, Paint paint) {
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final perim = _perimeter(rect);
    final dotCount = (perim / spacing).round().clamp(8, 200);
    for (int i = 0; i < dotCount; i++) {
      final p = _pointOnRRect(rect, i / dotCount);
      canvas.drawCircle(p, width * 0.6, dotPaint);
    }
  }

  void _drawDashed(Canvas canvas, RRect rect, Paint paint) {
    final perim = _perimeter(rect);
    final dashLen = spacing * 2;
    final segCount = (perim / (dashLen + spacing)).round().clamp(4, 100);
    for (int i = 0; i < segCount; i++) {
      final tStart = i / segCount;
      final tEnd = i / segCount + dashLen / perim;
      for (double t = tStart; t < tEnd && t <= 1.0; t += 0.002) {
        final p = _pointOnRRect(rect, t);
        canvas.drawCircle(p, width * 0.3,
            Paint()..color = color..style = PaintingStyle.fill);
      }
    }
  }

  void _drawDouble(Canvas canvas, RRect rect, Paint paint) {
    final inner = rect.deflate(width);
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(
        inner,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.5);
  }

  void _drawWavyBorder(Canvas canvas, RRect rect, Paint paint) {
    final path = Path();
    for (double t = 0; t <= 1.0; t += 0.001) {
      final p = _pointOnRRect(rect, t);
      final n = _normalAt(rect, t);
      final offset = math.sin(t * 20 * math.pi) * width;
      final wp = Offset(p.dx + n.dx * offset, p.dy + n.dy * offset);
      if (t == 0) {
        path.moveTo(wp.dx, wp.dy);
      } else {
        path.lineTo(wp.dx, wp.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRelief(Canvas canvas, RRect rect, Paint paint) {
    final inner = rect.deflate(width * 1.5);
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(
        inner,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.6);
  }

  double _perimeter(RRect rect) {
    final w = rect.width, h = rect.height, r = rect.tlRadius.x;
    return 2 * (w + h) - (8 - 2 * math.pi) * r;
  }

  Offset _pointOnRRect(RRect rect, double t) {
    t = t % 1.0;
    final w = rect.width, h = rect.height, r = rect.tlRadius.x;
    final cornerArc = (math.pi / 2) * r;
    final sideL = w - 2 * r, sideR = h - 2 * r;
    final perim = 2 * sideL + 2 * sideR + 4 * cornerArc;
    double dist = t * perim;
    double cx, cy, startAngle;

    if (dist < sideL) {
      return Offset(r + dist, 0);
    }
    dist -= sideL;
    if (dist < cornerArc) {
      cx = w - r;
      cy = r;
      startAngle = -math.pi / 2;
      final angle = startAngle + dist / r;
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    dist -= cornerArc;
    if (dist < sideR) {
      return Offset(w, r + dist);
    }
    dist -= sideR;
    if (dist < cornerArc) {
      cx = w - r;
      cy = h - r;
      startAngle = 0;
      final angle = startAngle + dist / r;
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    dist -= cornerArc;
    if (dist < sideL) {
      return Offset(w - r - dist, h);
    }
    dist -= sideL;
    if (dist < cornerArc) {
      cx = r;
      cy = h - r;
      startAngle = math.pi / 2;
      final angle = startAngle + dist / r;
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    dist -= cornerArc;
    cx = r;
    cy = r;
    startAngle = math.pi;
    final angle = startAngle + dist / r;
    return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
  }

  Offset _normalAt(RRect rect, double t) {
    const epsilon = 0.001;
    final p1 = _pointOnRRect(rect, t);
    final p2 = _pointOnRRect(rect, t + epsilon);
    final tangent = Offset(p2.dx - p1.dx, p2.dy - p1.dy);
    return Offset(-tangent.dy, tangent.dx);
  }

  @override
  bool shouldRepaint(covariant _BoardCardBorderPainter old) =>
      color != old.color ||
      width != old.width ||
      type != old.type ||
      spacing != old.spacing ||
      shape != old.shape;
}
