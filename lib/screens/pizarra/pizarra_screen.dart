import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/board_data_provider.dart';
import '../../models/board_element.dart';
import '../../services/board_media_service.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../app_state.dart';

const _c = Color(0xFF39FF14);
const _boardBg = Color(0xFF0D1A0D);
const _boardSize = 20000.0;
const _noteColors = ['#FF5757','#FFDE59','#00FF66','#00F0FF','#FF66C4','#9D00FF','#FF8800','#0088FF'];

enum _Handle { topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left }

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final i in items) {
    if (test(i)) return i;
  }
  return null;
}

class PizarraScreen extends StatefulWidget {
  const PizarraScreen({super.key});
  @override
  State<PizarraScreen> createState() => _PizarraScreenState();
}

class _PizarraScreenState extends State<PizarraScreen> {
  final _rng = Random(7);
  final _transformController = TransformationController();
  int? _selectedId;
  int? _connSourceId;
  bool _searchOpen = false;
  String _searchText = '';
  final _boardStack = <int>[1];
  final _editCtrls = <int, TextEditingController>{};
  final _editing = <int, bool>{};
  final _visibleRect = ValueNotifier<Rect>(Rect.zero);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<BoardDataProvider>().load();
    });
    _transformController.addListener(_onTransformChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToCenter());
  }

  void _onTransformChanged() {
    final matrix = _transformController.value;
    final inverse = Matrix4.inverted(matrix);
    final screenSize = MediaQuery.of(context).size;
    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(inverse, Offset(screenSize.width * 2, screenSize.height * 2));
    _visibleRect.value = Rect.fromLTRB(topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    for (final c in _editCtrls.values) { c.dispose(); }
    _visibleRect.dispose();
    super.dispose();
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return _c;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return _c;
    }
  }

  void _goToCenter() {
    final s = MediaQuery.of(context).size;
    _transformController.value = Matrix4.translationValues(s.width / 2, s.height / 2, 0);
  }

  Iterable<BoardElement> get _searchResults {
    final q = _searchText.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _pv.elements.where((e) =>
        e.type != 'connector' &&
        (e.content.toLowerCase().contains(q) ||
            ((e.data['title'] as String?) ?? '').toLowerCase().contains(q)));
  }

  void _goToElement(BoardElement el) {
    final size = MediaQuery.of(context).size;
    final px = size.width / 2 - el.center.dx;
    final py = size.height / 2 - el.center.dy;
    _transformController.value = Matrix4.translationValues(px, py, 0);
    setState(() {
      _selectedId = el.id;
      _searchOpen = false;
      _searchText = '';
    });
  }

  Offset _screenCenterToWorld() {
    final s = MediaQuery.of(context).size;
    final center = Offset(s.width / 2, s.height / 2);
    final inverse = Matrix4.inverted(_transformController.value);
    return MatrixUtils.transformPoint(inverse, center);
  }

  BoardDataProvider get _pv => context.read<BoardDataProvider>();

  void _spawnAdd(String type, {String content = '', double width = 180, double height = 110, Map<String, dynamic> data = const {}}) {
    HapticFeedback.heavyImpact();
    final isMedia = type == 'image' || type == 'link';
    final center = _screenCenterToWorld();
    _pv.add(BoardElement(
      type: type,
      content: content.isNotEmpty
          ? content
          : (type == 'note' ? 'Doble tap...' : (type == 'task' ? 'Nueva tarea' : '')),
      x: center.dx - width / 2,
      y: center.dy - height / 2,
      width: width,
      height: height,
      rotation: (_rng.nextDouble() - 0.5) * 0.1,
      color: isMedia ? null : _noteColors[_rng.nextInt(_noteColors.length)],
      data: data,
      z: 1,
      userId: AppState.myId,
    ));
  }

  Future<void> _addImageFromPicker() async {
    HapticFeedback.heavyImpact();
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600);
      if (file == null) return;
      final path = await BoardMediaService().uploadImage(file);
      if (!mounted) return;
      _spawnAdd('image', content: path, width: 240, height: 180);
    } catch (e) {
      debugPrint('_addImageFromPicker error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo subir la imagen')),
      );
    }
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    String initial = '',
    TextInputType? keyboardType,
    int? maxLength,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlg) {
          return AlertDialog(
            backgroundColor: const Color(0xFF12331a),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: maxLength,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setDlg(() {}),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF88FF99)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: ctrl.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('Crear', style: TextStyle(color: _c)),
              ),
            ],
          );
        });
      },
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _addLinkFromDialog() async {
    HapticFeedback.heavyImpact();
    final url = await _promptText(
      title: 'Pegar link',
      hint: 'https://...',
      keyboardType: TextInputType.url,
    );
    if (url == null || url.trim().isEmpty) return;
    final trimmed = url.trim();
    final raw = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final host = Uri.tryParse(raw)?.host;
    _spawnAdd(
      'link',
      content: raw,
      width: 260,
      height: 96,
      data: {
        'url': raw,
        'title': (host == null || host.isEmpty) ? trimmed : host,
      },
    );
  }

  void _openBoard(int boardId) {
    if (_boardStack.contains(boardId)) return;
    setState(() {
      _boardStack.add(boardId);
      _selectedId = null;
      _connSourceId = null;
      _searchOpen = false;
      _searchText = '';
    });
    _pv.setBoard(boardId);
    _goToCenter();
  }

  void _goBackBoard() {
    if (_boardStack.length <= 1) return;
    setState(() {
      _boardStack.removeLast();
      _selectedId = null;
      _connSourceId = null;
    });
    _pv.setBoard(_boardStack.last);
    _goToCenter();
  }

  Future<void> _createSubBoard() async {
    HapticFeedback.heavyImpact();
    final name = await _promptText(
      title: 'Nuevo tablero',
      hint: 'Nombre del tablero',
      maxLength: 30,
    );
    if (name == null || name.trim().isEmpty) return;
    final newId = await _pv.createBoard(name.trim(), _pv.boardId);
    if (newId == null || !mounted) return;
    final center = _screenCenterToWorld();
    const w = 240.0;
    const h = 70.0;
    _pv.add(BoardElement(
      type: 'board',
      content: name.trim(),
      x: center.dx - w / 2,
      y: center.dy - h / 2,
      width: w,
      height: h,
      z: 1,
      color: '#39FF14',
      data: {'boardId': newId},
      userId: AppState.myId,
    ));
  }

  void _enterConnectorMode() {
    HapticFeedback.heavyImpact();
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí primero una nota para conectar')),
      );
      return;
    }
    setState(() => _connSourceId = _selectedId);
  }

  void _deleteSelected() {
    final s = _selectedId;
    if (s == null) return;
    HapticFeedback.heavyImpact();
    final el = _resolveSelected(s);
    if (el == null) return;
    if (el.type == 'image' && el.content.isNotEmpty) {
      BoardMediaService().deleteImage(el.content);
    }
    if (el.id != null) {
      _pv.delete(el.id!);
    } else {
      _pv.deleteLocal(el);
    }
    _editCtrls[s]?.dispose();
    _editCtrls.remove(s);
    _editing.remove(s);
    setState(() {
      _selectedId = null;
      _connSourceId = null;
    });
  }

  BoardElement? _resolveSelected(int? sel) {
    if (sel == null) return null;
    return _firstWhereOrNull(_pv.elements, (e) => e.id == sel) ??
        _firstWhereOrNull(
          _pv.elements,
          (e) =>
              e.id == null &&
              (e.createdAt.millisecondsSinceEpoch % 1000000) == sel,
        );
  }

  void _bringToFront() {
    final s = _selectedId;
    if (s == null) return;
    final el = _resolveSelected(s);
    if (el?.id == null) return;
    HapticFeedback.selectionClick();
    _pv.bringToFront(el!.id!);
  }

  void _startEditing(int id, String content) {
    _editCtrls[id]?.dispose();
    _editCtrls[id] = TextEditingController(text: content);
    setState(() => _editing[id] = true);
  }

  void _finishEditing(int id) {
    final text = _editCtrls[id]?.text ?? '';
    final match = _resolveSelected(id);
    if (match != null && text.isNotEmpty) {
      _pv.updateContentLocal(match, text);
    }
    setState(() => _editing[id] = false);
  }

  void _createConnector(int fromId, int toId) {
    if (fromId == toId) {
      setState(() => _connSourceId = null);
      return;
    }
    final from = _firstWhereOrNull(_pv.elements, (e) => e.id == fromId);
    final to = _firstWhereOrNull(_pv.elements, (e) => e.id == toId);
    if (from == null ||
        to == null ||
        from.type == 'connector' ||
        to.type == 'connector') {
      setState(() => _connSourceId = null);
      return;
    }
    // Evita conector duplicado entre el mismo par.
    final exists = _pv.elements.any((e) =>
        e.type == 'connector' &&
        e.data['fromId'] == fromId &&
        e.data['toId'] == toId);
    setState(() => _connSourceId = null);
    if (exists) return;
    _pv.add(BoardElement(
      type: 'connector',
      x: 0,
      y: 0,
      width: 0,
      height: 0,
      z: 0,
      data: {
        'fromId': fromId,
        'toId': toId,
        'stroke': 3.0,
        'dashed': false,
        'arrow': true,
        'color': '#39FF14',
      },
      userId: AppState.myId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _boardBg,
      body: ResponsiveWrapper(
        builder: (context, w, h) => Consumer<BoardDataProvider>(
          builder: (context, pv, _) => Stack(children: [
            _boardCanvas(pv),
            _headerFloating(pv),
            _toolsFloating(),
            if (_searchOpen) _searchPanel(),
            if (_connSourceId != null) _connectorHint(),
            if (pv.hasError) _errorBanner(pv),
          ]),
        ),
      ),
    );
  }

  Widget _errorBanner(BoardDataProvider pv) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF5A1010),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF5A1010), width: 2),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              pv.error ?? 'Error',
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 13),
            ),
          ),
          TapTile(
            onTap: pv.clearError,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ]),
      ),
    );
  }

  Widget _headerFloating(BoardDataProvider pv) {
    return Positioned(left: 12, top: 8, right: 12, height: 48,
      child: Row(children: [
        if (_boardStack.length > 1)
          Padding(padding: const EdgeInsets.only(right: 6),
            child: TapTile(onTap: _goBackBoard, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(14), border: Border.all(color: _c, width: 2)),
              child: const Icon(Icons.arrow_back, color: _c, size: 20)))),
        Padding(padding: const EdgeInsets.only(right: 8),
          child: TapTile(onTap: () => _createSubBoard(), child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(14), border: Border.all(color: _c, width: 2)),
            child: const Icon(Icons.create_new_folder, color: _c, size: 20)))),
        Container(
          width: 150,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(14)),
          child: Text(pv.boardName, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bangers(color: _c, fontSize: 15)),
        ),
        TapTile(onTap: () { HapticFeedback.selectionClick(); setState(() => _searchOpen = !_searchOpen); },
          child: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(14), border: Border.all(color: _c, width: 2)),
            child: const Icon(Icons.search, color: _c, size: 22))),
        const Spacer(),
        if (_selectedId != null) ...[
          Padding(padding: const EdgeInsets.only(right: 8),
            child: TapTile(onTap: () => _openComments(), child: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(14), border: Border.all(color: _c, width: 2)),
              child: const Icon(Icons.mode_comment, color: _c, size: 20)))),
          Padding(padding: const EdgeInsets.only(right: 8),
            child: TapTile(onTap: _bringToFront, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(14), border: Border.all(color: _c, width: 2)),
              child: const Icon(Icons.vertical_align_top, color: _c, size: 20)))),
          Padding(padding: const EdgeInsets.only(right: 8),
            child: TapTile(onTap: _deleteSelected, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFFF5757), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.delete, color: Colors.white, size: 24)))),
        ],
        TapTile(onTap: () => _spawnAdd('note'),
          child: Container(width: 48, height: 48, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add, color: Color(0xFF0D1A0D), size: 24))),
      ]),
    );
  }

  Widget _toolsFloating() {
    final tools = <(IconData, VoidCallback, Color)>[
      (Icons.note_add, () => _spawnAdd('note'), const Color(0xFF00F0FF)),
      (Icons.task_alt, () => _spawnAdd('task', width: 200, height: 70), const Color(0xFF39FF14)),
      (Icons.image, _addImageFromPicker, const Color(0xFF9D00FF)),
      (Icons.link, _addLinkFromDialog, const Color(0xFF0088FF)),
    ];
    return Positioned(right: 12, top: 80,
      child: Column(children: [
        for (final t in tools)
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: TapTile(onTap: t.$2, child: Container(width: 46, height: 46, decoration: BoxDecoration(color: t.$3.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(14), border: Border.all(color: t.$3, width: 2)),
              child: Icon(t.$1, color: t.$3, size: 22)))),
        Padding(padding: const EdgeInsets.only(bottom: 8),
          child: TapTile(onTap: _enterConnectorMode, child: Container(width: 46, height: 46, decoration: BoxDecoration(color: _connSourceId != null ? _c : const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(14), border: Border.all(color: _c, width: 2)),
            child: const Icon(Icons.timeline, color: _c, size: 22)))),
      ]),
    );
  }

  Widget _connectorHint() {
    return Positioned(left: 0, right: 0, bottom: 16,
      child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFF16233a), borderRadius: BorderRadius.circular(14)),
        child: const Text('Toca la nota de destino para conectarla', style: TextStyle(color: _c, fontWeight: FontWeight.bold)))),
    );
  }

  Widget _searchPanel() {
    final results = _searchResults.toList();
    const panel = Color(0xFF12331a);
    return Positioned(
      left: 12,
      right: 12,
      top: 64,
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: panel,
            border: Border.all(color: panel, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _searchText = v),
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Buscar notas, links...',
                hintStyle: const TextStyle(color: Color(0xFF88FF99)),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() { _searchOpen = false; _searchText = ''; }),
                ),
              ),
            ),
            if (results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(shrinkWrap: true, children: [
                  for (final el in results)
                    ListTile(
                      dense: true,
                      leading: Icon(_typeIcon(el.type), color: _c, size: 18),
                      title: Text(el.content.isEmpty ? (el.data['title'] as String? ?? el.type) : el.content,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.bangers(color: Colors.white, fontSize: 13)),
                      onTap: () => _goToElement(el),
                    ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'link':
        return Icons.link;
      case 'task':
        return Icons.task_alt;
      case 'board':
        return Icons.create_new_folder;
      default:
        return Icons.note_add;
    }
  }

  Widget _boardCanvas(BoardDataProvider pv) {
    if (pv.loading) {
      return const Center(child: CircularProgressIndicator(color: _c));
    }
    if (pv.hasError && pv.elements.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF5757), size: 40),
          const SizedBox(height: 12),
          Text(pv.error ?? 'Error',
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          TapTile(
            onTap: () => pv.load(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _c,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _c, width: 2),
              ),
              child: const Icon(Icons.refresh, color: Color(0xFF0D1A0D)),
            ),
          ),
        ]),
      );
    }
    return GestureDetector(
      onTap: () {
        if (_connSourceId != null) {
          setState(() => _connSourceId = null);
        } else {
          setState(() => _selectedId = null);
        }
      },
      child: Stack(children: [
        Positioned.fill(
          child: ValueListenableBuilder<Rect>(
            valueListenable: _visibleRect,
            builder: (context, rect, _) => CustomPaint(
              painter: _GridPainter(transform: _transformController.value),
            ),
          ),
        ),
        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          minScale: 0.1,
          maxScale: 5.0,
          child: SizedBox(
            width: _boardSize,
            height: _boardSize,
            child: ValueListenableBuilder<Rect>(
              valueListenable: _visibleRect,
              builder: (context, rect, _) {
                final all = pv.elements;
                final connectors =
                    all.where((e) => e.type == 'connector').toList();
                final items = all.where((e) => e.type != 'connector').toList()
                  ..sort((a, b) => a.z.compareTo(b.z));
                return Stack(clipBehavior: Clip.none, children: [
                  if (connectors.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ConnectorPainter(
                          elements: all,
                          connectors: connectors,
                        ),
                      ),
                    ),
                  for (final el in items) _buildVisibleElement(el),
                ]);
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildVisibleElement(BoardElement el) {
    final viewport = _visibleRect.value.inflate(500);
    final visible = el.x < viewport.right && el.x + el.width > viewport.left &&
                    el.y < viewport.bottom && el.y + el.height > viewport.top;
    if (!visible) return const SizedBox.shrink();
    final id = el.id ?? (el.createdAt.millisecondsSinceEpoch % 1000000);
    final selected = _selectedId == id;
    final editing = _editing[id] == true;
    return Positioned(left: el.x, top: el.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedId = id;
            if (_connSourceId != null && _connSourceId != id && el.id != null) {
              _createConnector(_connSourceId!, el.id!);
            }
          });
        },
        onDoubleTap: () {
          if (el.type == 'board') {
            final b = el.data['boardId'];
            final boardId = b is int ? b : int.tryParse('$b');
            if (boardId != null) _openBoard(boardId);
          } else if (el.type == 'note' || el.type == 'task') {
            _startEditing(id, el.content);
          } else if (el.type == 'link') {
            _editLink(el);
          }
        },
        onPanUpdate: (d) {
          // Usa la copia actual del provider (no el el stale del build).
          final live = el.id != null
              ? _firstWhereOrNull(_pv.elements, (e) => e.id == el.id)
              : _firstWhereOrNull(_pv.elements, (e) => identical(e, el)) ??
                  _firstWhereOrNull(
                    _pv.elements,
                    (e) =>
                        e.id == null &&
                        e.createdAt == el.createdAt &&
                        e.type == el.type,
                  );
          final target = live ?? el;
          _pv.moveLocal(target, target.x + d.delta.dx, target.y + d.delta.dy);
        },
        child: _buildElementBody(el, id, selected, editing),
      ),
    );
  }

  Widget _buildElementBody(BoardElement el, int id, bool selected, bool editing) {
    final w = el.width; final h = el.height;
    final color = el.color == null ? null : _hexToColor(el.color);

    Widget body;
    if (editing) {
      body = _editingBox(el, id);
    } else if (el.type == 'image') {
      body = Container(width: w, height: h, clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: _BoardImage(storagePath: el.content));
    } else if (el.type == 'link') {
      body = _LinkCard(url: el.content, title: el.data['title'] as String? ?? el.content, w: w, h: h);
    } else if (el.type == 'task') {
      body = Container(width: w, height: h, padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              final done = el.isDone;
              _pv.updateDataLocal(el, {...el.data, 'done': !done});
            },
            child: Container(width: 18, height: 18,
              decoration: BoxDecoration(color: el.isDone ? const Color(0xFF111111) : const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(4)),
              child: el.isDone ? const Icon(Icons.check, color: _c, size: 14) : null),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(el.content,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14,
              decoration: el.isDone ? TextDecoration.lineThrough : null,
              decorationThickness: 2))),
        ]));
    } else if (el.type == 'board') {
      // skill_visual: fondo=borde mismo color, sólido, redondo.
      const boardColor = Color(0xFF1A3A1A);
      body = Container(
        width: w,
        height: h,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: boardColor,
          border: Border.all(color: boardColor, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.create_new_folder, color: _c, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              el.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
        ]),
      );
    } else {
      body = Container(width: w, height: h, padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (el.content.isNotEmpty)
            Expanded(child: Text(el.content, style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14, height: 1.3, letterSpacing: 0.5), maxLines: 6, overflow: TextOverflow.ellipsis))
          else
            Expanded(child: Center(child: Icon(Icons.note_add, color: const Color(0xFF111111), size: h * 0.4))),
          if (!selected) Text(_ownerInitial(el), style: GoogleFonts.bangers(color: const Color(0xFF111111).withValues(alpha: .65), fontSize: 10)),
        ]));
    }

    return Transform.rotate(angle: el.rotation, child: Stack(children: [
      body,
      if (selected && !editing) ...[
        Positioned.fill(child: IgnorePointer(child: Container(
          decoration: BoxDecoration(border: Border.all(color: _c, width: 3), borderRadius: BorderRadius.circular(14))))),
        ..._buildHandles(el, w, h),
      ],
      if (!selected && commentCount(el) > 0)
        Positioned(right: 4, bottom: 4, child: Container(width: 18, height: 18,
          decoration: BoxDecoration(color: const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(9), border: Border.all(color: _c, width: 1)),
          child: Center(child: Text('${commentCount(el)}', style: GoogleFonts.bangers(color: _c, fontSize: 10)))),
      ),
    ]));
  }

  Widget _editingBox(BoardElement el, int id) {
    return Container(width: el.width, height: el.height + 70, padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF1A3A1A), border: Border.all(color: _c, width: 3), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Expanded(child: TextField(
          controller: _editCtrls[id], autofocus: true, maxLines: null,
          style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          onSubmitted: (_) => _finishEditing(id),
        )),
        TapTile(onTap: () => _finishEditing(id), child: Container(width: 44, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.check, color: Color(0xFF0D1A0D), size: 22))),
      ]));
  }

  String _ownerInitial(BoardElement el) {
    final my = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
    return el.isMine ? my : (my == 'F' ? 'R' : 'F');
  }

  Future<void> _editLink(BoardElement el) async {
    final newUrl = await _promptText(
      title: 'Editar link',
      hint: 'https://...',
      initial: el.content,
      keyboardType: TextInputType.url,
    );
    if (newUrl == null || newUrl.trim().isEmpty) return;
    final trimmed = newUrl.trim();
    final raw = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final host = Uri.tryParse(raw)?.host;
    // Actualiza content (URL visible) + data sin borrar comments/otros.
    _pv.updateContentLocal(el, raw);
    _pv.updateDataLocal(el, {
      ...el.data,
      'url': raw,
      'title': (host == null || host.isEmpty) ? trimmed : host,
    });
  }

  // ---------- Comentarios + menciones ----------

  List<dynamic> _commentsOf(BoardElement el) =>
      (el.data['comments'] as List?) ?? const [];

  int commentCount(BoardElement el) => _commentsOf(el).length;

  void _openComments() {
    final el = _resolveSelected(_selectedId);
    if (el == null || el.type == 'connector') return;
    HapticFeedback.selectionClick();
    _showCommentsSheet(el);
  }

  BoardElement _liveElement(BoardElement el) {
    if (el.id != null) {
      return _firstWhereOrNull(_pv.elements, (e) => e.id == el.id) ?? el;
    }
    return _firstWhereOrNull(_pv.elements, (e) => identical(e, el)) ??
        _firstWhereOrNull(
          _pv.elements,
          (e) =>
              e.id == null &&
              e.createdAt == el.createdAt &&
              e.type == el.type,
        ) ??
        el;
  }

  Future<void> _showCommentsSheet(BoardElement seed) {
    final input = TextEditingController();
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12331a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        int? replyingIndex;
        return StatefulBuilder(builder: (ctx, setSheet) {
          final el = _liveElement(seed);
          final comments = _commentsOf(el);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comentarios',
                      style: GoogleFonts.bangers(color: _c, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(children: [
                        for (final (i, c) in comments.indexed)
                          _commentRow(el, i, c, () {
                            replyingIndex = i;
                            setSheet(() {});
                          }),
                        if (comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text(
                                'Sin comentarios',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    if (replyingIndex != null)
                      Row(children: [
                        const Text(
                          'Respondiendo...',
                          style: TextStyle(
                            color: Color(0xFF88FF99),
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed: () {
                            replyingIndex = null;
                            setSheet(() {});
                          },
                        ),
                      ]),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          autofocus: false,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Escribí un comentario (@ para mencionar)',
                            hintStyle: TextStyle(color: Color(0xFF88FF99)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: _c),
                        onPressed: () {
                          final t = input.text.trim();
                          if (t.isEmpty) return;
                          _addComment(
                            _liveElement(seed),
                            t,
                            replyIndex: replyingIndex,
                          );
                          input.clear();
                          replyingIndex = null;
                          setSheet(() {});
                        },
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _addComment(BoardElement el, String text, {int? replyIndex}) {
    final live = _liveElement(el);
    final comments = List<dynamic>.from(_commentsOf(live));
    comments.add({
      'user': AppState.identity ?? '?',
      'text': text,
      'time': DateTime.now().millisecondsSinceEpoch,
      'replyTo': replyIndex,
    });
    _pv.updateDataLocal(live, {...live.data, 'comments': comments});
  }

  void _deleteComment(BoardElement el, int i) {
    final live = _liveElement(el);
    final comments = List<dynamic>.from(_commentsOf(live))..removeAt(i);
    _pv.updateDataLocal(live, {...live.data, 'comments': comments});
  }

  Widget _commentRow(BoardElement el, int i, dynamic c, VoidCallback onReply) {
    final map = c as Map;
    final isMine = (map['user'] as String? ?? '') == AppState.identity;
    final reply = map['replyTo'];
    return Padding(
      padding: EdgeInsets.only(left: reply is int && reply >= 0 ? 16 : 0, bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 26, height: 26, alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF1f3352), borderRadius: BorderRadius.circular(8)),
          child: Text((map['user'] as String? ?? '?').substring(0, 1).toUpperCase(), style: GoogleFonts.bangers(color: _c, fontSize: 12))),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(map['user'] as String? ?? '?', style: const TextStyle(color: Color(0xFF88FF99), fontSize: 11, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (isMine)
              GestureDetector(onTap: () => _deleteComment(el, i), child: const Icon(Icons.delete_outline, color: Colors.white54, size: 14)),
          ]),
          mentionRich(map['text'] as String? ?? ''),
        ])),
        GestureDetector(onTap: onReply, child: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.reply, color: Colors.white38, size: 14))),
      ]),
    );
  }

  Widget mentionRich(String text) {
    final spans = <TextSpan>[];
    final re = RegExp(r'@\w+');
    int last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(text: m.group(0), style: const TextStyle(color: _c, fontWeight: FontWeight.bold)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    if (spans.isEmpty) spans.add(TextSpan(text: text));
    return Text.rich(TextSpan(children: spans, style: const TextStyle(color: Colors.white, fontSize: 13)));
  }

  // ---------- Resize handles ----------

  List<Widget> _buildHandles(BoardElement el, double w, double h) {
    const size = 16.0;
    Offset pos(_Handle q) {
      switch (q) {
        case _Handle.topLeft: return const Offset(0, 0);
        case _Handle.top: return Offset(w / 2 - size / 2, 0);
        case _Handle.topRight: return Offset(w - size, 0);
        case _Handle.right: return Offset(w - size, h / 2 - size / 2);
        case _Handle.bottomRight: return Offset(w - size, h - size);
        case _Handle.bottom: return Offset(w / 2 - size / 2, h - size);
        case _Handle.bottomLeft: return Offset(0, h - size);
        case _Handle.left: return Offset(0, h / 2 - size / 2);
      }
    }

    return [
      for (final q in _Handle.values)
        Positioned(top: pos(q).dy, left: pos(q).dx,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => _onResize(el, q, d.delta.dx, d.delta.dy),
            child: Container(width: size, height: size,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _c, width: 2), borderRadius: BorderRadius.circular(4))),
          )),
    ];
  }

  void _onResize(BoardElement el, _Handle q, double dx, double dy) {
    const min = 40.0;
    final live = _liveElement(el);
    var x = live.x, y = live.y, w = live.width, h = live.height;
    switch (q) {
      case _Handle.bottomRight:
        w += dx;
        h += dy;
      case _Handle.bottomLeft:
        x += dx;
        w -= dx;
        h += dy;
      case _Handle.topRight:
        w += dx;
        y += dy;
        h -= dy;
      case _Handle.topLeft:
        x += dx;
        w -= dx;
        y += dy;
        h -= dy;
      case _Handle.right:
        w += dx;
      case _Handle.left:
        x += dx;
        w -= dx;
      case _Handle.bottom:
        h += dy;
      case _Handle.top:
        y += dy;
        h -= dy;
    }
    if (w < min || h < min) return;
    if (x != live.x || y != live.y) _pv.moveLocal(live, x, y);
    _pv.resizeLocal(live, w, h);
  }
}

class _BoardImage extends StatefulWidget {
  final String storagePath;
  const _BoardImage({required this.storagePath});
  @override
  State<_BoardImage> createState() => _BoardImageState();
}

class _BoardImageState extends State<_BoardImage> {
  late Future<Uint8List> _future;
  @override
  void initState() {
    super.initState();
    _future = BoardMediaService().downloadImage(widget.storagePath);
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) return Image.memory(snap.data!, fit: BoxFit.cover, gaplessPlayback: true);
        if (snap.hasError) return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 32));
        return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _c, strokeWidth: 2)));
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final Matrix4 transform;
  _GridPainter({Matrix4? transform}) : transform = transform ?? Matrix4.identity();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A3A1A)..strokeWidth = 1.5;
    const spacing = 30.0;
    final inv = Matrix4.inverted(transform);
    final tl = MatrixUtils.transformPoint(inv, Offset.zero);
    final br = MatrixUtils.transformPoint(inv, Offset(size.width, size.height));
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
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.transform != transform;
}

class _LinkCard extends StatelessWidget {
  final String url; final String title; final double w; final double h;
  const _LinkCard({required this.url, required this.title, required this.w, required this.h});
  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(url.contains('://') ? url : 'https://$url')?.host ?? url;
    return Container(width: w, height: h, padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF15223a), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: Image.network('https://www.google.com/s2/favicons?domain=$host&sz=64', width: 40, height: 40,
            errorBuilder: (_, _, _) => Container(width: 40, height: 40, color: const Color(0xFF1f3352),
              child: const Icon(Icons.link, color: _c, size: 22)))),
        const SizedBox(width: 10),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.bangers(color: _c, fontSize: 14, height: 1.2)),
          const SizedBox(height: 2),
          Text(host, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
      ]));
  }
}

class _ConnectorPainter extends CustomPainter {
  final List<BoardElement> elements;
  final List<BoardElement> connectors;
  _ConnectorPainter({required this.elements, required this.connectors});

  BoardElement? _byId(int? id) {
    if (id == null) return null;
    for (final e in elements) { if (e.id == id) return e; }
    return null;
  }

  Color _color(String hex) {
    try { return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16)); }
    catch (_) { return _c; }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in connectors) {
      final from = _byId(c.data['fromId'] as int?);
      final to = _byId(c.data['toId'] as int?);
      if (from == null || to == null) continue;
      final a = Offset(from.x + from.width / 2, from.y + from.height / 2);
      final b = Offset(to.x + to.width / 2, to.y + to.height / 2);
      final strokeW = (c.data['stroke'] as num?)?.toDouble() ?? 3;
      final dashed = c.data['dashed'] == true;
      final arrow = c.data['arrow'] == true;
      final lineColor = _color((c.data['color'] as String?) ?? '#39FF14');
      final stroke = Paint()..color = lineColor..strokeWidth = strokeW..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      _drawLine(canvas, a, b, stroke, dashed);
      if (arrow) {
        final fill = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;
        // Punta en el destino (b), dirección desde el origen (a).
        _drawArrowhead(canvas, b, a, fill, strokeW);
      }
    }
  }

  void _drawLine(Canvas canvas, Offset a, Offset b, Paint paint, bool dashed) {
    if (!dashed) {
      canvas.drawLine(a, b, paint);
      return;
    }
    const dash = 10.0;
    const gap = 8.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    double t = 0;
    while (t < total) {
      final e = (t + dash > total) ? total : t + dash;
      canvas.drawLine(a + dir * t, a + dir * e, paint);
      t += dash + gap;
    }
  }

  /// [tip] = punta de la flecha (destino). [from] = origen de la línea.
  void _drawArrowhead(
    Canvas canvas,
    Offset tip,
    Offset from,
    Paint paint,
    double w,
  ) {
    final vec = tip - from;
    final d = vec.distance == 0 ? 1.0 : vec.distance;
    final n = vec / d;
    final perp = Offset(-n.dy, n.dx);
    final size = 8 + w * 1.5;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - n.dx * size + perp.dx * size * 0.55,
        tip.dy - n.dy * size + perp.dy * size * 0.55,
      )
      ..lineTo(
        tip.dx - n.dx * size - perp.dx * size * 0.55,
        tip.dy - n.dy * size - perp.dy * size * 0.55,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      oldDelegate.connectors != connectors ||
      oldDelegate.elements != elements;
}