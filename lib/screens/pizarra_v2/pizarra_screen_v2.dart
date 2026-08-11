import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/board_provider_v2.dart';
import '../../models/board_element_v2.dart';
import '../../models/board_element_data.dart';
import '../../app_state.dart';
import 'widgets/board_canvas.dart';
import 'widgets/board_header.dart';
import 'widgets/board_tools_menu.dart';
import 'widgets/board_search_panel.dart';
import 'widgets/board_element_panel.dart';
import 'widgets/board_activity_panel.dart';
import 'widgets/board_list_view.dart';
import 'widgets/board_timeline_view.dart';
import 'widgets/board_archived_view.dart';
import 'widgets/board_tag_manager.dart';
import 'editors/board_drawing_editor.dart';
import 'editors/board_audio_editor.dart';
import 'editors/board_video_search.dart';

enum BoardViewMode { canvas, list, timeline, archived }

const _boardBg = Color(0xFF0A0A0A);

class PizarraScreenV2 extends StatefulWidget {
  const PizarraScreenV2({super.key});

  @override
  State<PizarraScreenV2> createState() => _PizarraScreenV2State();
}

class _PizarraScreenV2State extends State<PizarraScreenV2> {
  final _transformController = TransformationController();
  int? _selectedId;
  bool _searchOpen = false;
  String _searchText = '';
  bool _showActivity = false;
  bool _showVideoSearch = false;
  bool _showTagManager = false;
  bool _showDrawingEditor = false;
  bool _showAudioEditor = false;
  BoardViewMode _viewMode = BoardViewMode.canvas;
  final _visibleRect = ValueNotifier<Rect>(Rect.zero);
  bool _connectorMode = false;
  int? _connectorFromId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final provider = context.read<BoardProviderV2>();
        provider.load();
        provider.loadActivity();
      }
    });
    _transformController.addListener(_onTransformChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToCenter());
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
      topLeft.dx,
      topLeft.dy,
      bottomRight.dx,
      bottomRight.dy,
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
    final s = MediaQuery.of(context).size;
    _transformController.value =
        Matrix4.translationValues(s.width / 2, s.height / 2, 0);
  }

  Offset _screenCenterToWorld() {
    final s = MediaQuery.of(context).size;
    final center = Offset(s.width / 2, s.height / 2);
    final inverse = Matrix4.inverted(_transformController.value);
    return MatrixUtils.transformPoint(inverse, center);
  }

  BoardProviderV2 get _pv => context.read<BoardProviderV2>();

  void _createNoteAtCenter() {
    HapticFeedback.heavyImpact();
    final center = _screenCenterToWorld();
    _pv.add(BoardElementV2.newNote(
      x: center.dx - 90,
      y: center.dy - 30,
      userId: AppState.myId,
    ));
  }

  void _selectElement(int? id) {
    setState(() {
      _selectedId = id;
      if (id != null) {
        _pv.markAsSeen(id);
      }
    });
  }

  void _createAndEdit(String type) {
    if (type == BoardElementType.connector) {
      setState(() {
        _connectorMode = true;
        _connectorFromId = null;
        _selectedId = null;
      });
      HapticFeedback.heavyImpact();
      return;
    }
    final center = _screenCenterToWorld();
    _pv.add(BoardElementV2(
      type: type,
      title: _defaultTitle(type),
      content: '',
      x: center.dx - 90,
      y: center.dy - 30,
      userId: AppState.myId,
      isNew: true,
    ));
    setState(() {
      if (type == BoardElementType.drawing) {
        _showDrawingEditor = true;
      } else if (type == BoardElementType.audio) {
        _showAudioEditor = true;
      }
    });
  }

  void _handleConnectorSelect(int? id, BoardProviderV2 pv) {
    if (id == null) {
      setState(() {
        _connectorMode = false;
        _connectorFromId = null;
      });
      return;
    }
    if (_connectorFromId == null) {
      setState(() => _connectorFromId = id);
      HapticFeedback.selectionClick();
    } else if (_connectorFromId != id) {
      final fromEl = pv.elements.firstWhere((e) => e.id == _connectorFromId);
      final toEl = pv.elements.firstWhere((e) => e.id == id);
      final center = _screenCenterToWorld();
      pv.add(BoardElementV2(
        type: BoardElementType.connector,
        title: 'Conector',
        content: '',
        x: center.dx,
        y: center.dy,
        userId: AppState.myId,
        isNew: true,
        data: ConnectorData(
          fromId: fromEl.id,
          toId: toEl.id,
        ).toMap(),
      ));
      HapticFeedback.heavyImpact();
      setState(() {
        _connectorMode = false;
        _connectorFromId = null;
      });
    } else {
      setState(() => _connectorFromId = null);
    }
  }

  String _defaultTitle(String type) {
    switch (type) {
      case BoardElementType.note:
        return 'Nueva nota';
      case BoardElementType.checklist:
        return 'Nueva checklist';
      case BoardElementType.drawing:
        return 'Nuevo dibujo';
      case BoardElementType.video:
        return 'Nuevo video';
      case BoardElementType.audio:
        return 'Nuevo audio';
      case BoardElementType.connector:
        return 'Conector';
      default:
        return 'Nuevo elemento';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _boardBg,
      body: Consumer<BoardProviderV2>(
        builder: (context, pv, _) => Stack(
          children: [
            // Main content based on view mode
            if (_viewMode == BoardViewMode.canvas)
              BoardCanvas(
                transformController: _transformController,
                visibleRect: _visibleRect,
                provider: pv,
                selectedId: _selectedId,
                onSelectElement: _connectorMode
                    ? (id) => _handleConnectorSelect(id, pv)
                    : _selectElement,
                onDoubleTapEmpty: _createNoteAtCenter,
                connectorMode: _connectorMode,
                connectorFromId: _connectorFromId,
              )
            else if (_viewMode == BoardViewMode.list)
              BoardListView(
                provider: pv,
                onGoToElement: (el) {
                  _goToElement(el);
                  _selectElement(el.id);
                  setState(() => _viewMode = BoardViewMode.canvas);
                },
              )
            else if (_viewMode == BoardViewMode.timeline)
              BoardTimelineView(
                provider: pv,
                onGoToElement: (el) {
                  _goToElement(el);
                  _selectElement(el.id);
                  setState(() => _viewMode = BoardViewMode.canvas);
                },
              )
            else if (_viewMode == BoardViewMode.archived)
              BoardArchivedView(
                provider: pv,
                onRestore: (el) => pv.toggleArchive(el.id!),
              ),
            // Overlays
            BoardHeader(
              provider: pv,
              searchOpen: _searchOpen,
              onToggleSearch: () =>
                  setState(() => _searchOpen = !_searchOpen),
              onToggleActivity: () =>
                  setState(() => _showActivity = !_showActivity),
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              onToggleTagManager: () =>
                  setState(() => _showTagManager = !_showTagManager),
              currentViewMode: _viewMode,
            ),
            if (_searchOpen)
              BoardSearchPanel(
                elements: pv.elements,
                searchText: _searchText,
                onSearchChanged: (v) => setState(() => _searchText = v),
                onClose: () => setState(() {
                  _searchOpen = false;
                  _searchText = '';
                }),
                onGoToElement: (el) {
                  _goToElement(el);
                  _selectElement(el.id);
                },
              ),
            if (_showActivity)
              BoardActivityPanel(
                activity: pv.activity,
                onClose: () => setState(() => _showActivity = false),
              ),
            if (_selectedId != null && !_connectorMode)
              BoardElementPanel(
                element: pv.elements.firstWhere(
                  (e) => e.id == _selectedId,
                  orElse: () => pv.elements.first,
                ),
                provider: pv,
                onClose: () => _selectElement(null),
              ),
            BoardToolsMenu(
              onCreateNote: () => _createNoteAtCenter(),
              onCreateChecklist: () => _createAndEdit(BoardElementType.checklist),
              onCreateDrawing: () => _createAndEdit(BoardElementType.drawing),
              onCreateVideo: () => setState(() => _showVideoSearch = true),
              onCreateAudio: () => _createAndEdit(BoardElementType.audio),
              onCreateConnector: () => _createAndEdit(BoardElementType.connector),
            ),
            if (_showTagManager)
              BoardTagManager(
                provider: pv,
                onClose: () => setState(() => _showTagManager = false),
              ),
            if (_showVideoSearch)
              BoardVideoSearchDialog(
                provider: pv,
                onClose: () => setState(() => _showVideoSearch = false),
              ),
            if (_showDrawingEditor)
              BoardDrawingEditor(
                provider: pv,
                onClose: () => setState(() => _showDrawingEditor = false),
              ),
            if (_showAudioEditor)
              BoardAudioEditor(
                provider: pv,
                onClose: () => setState(() => _showAudioEditor = false),
              ),
            if (_connectorMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.timeline, color: const Color(0xFF00F0FF), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectorFromId == null
                                ? 'Tocá el elemento de origen'
                                : 'Tocá el elemento de destino',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _connectorMode = false;
                            _connectorFromId = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5757),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFF0A0A0A),
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _goToElement(BoardElementV2 el) {
    final size = MediaQuery.of(context).size;
    final w = el.width ?? 180;
    final h = el.height ?? 110;
    final px = size.width / 2 - (el.x + w / 2);
    final py = size.height / 2 - (el.y + h / 2);
    _transformController.value = Matrix4.translationValues(px, py, 0);
  }
}
