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
    _transformController.value = Matrix4.translationValues(-500, -400, 0);
  }

  double _randPos() {
    final t = _transformController.value.getTranslation();
    final base = t.x.isFinite ? t.x.abs() : 500.0;
    return base + _rng.nextDouble() * 200 + 200;
  }

  BoardDataProvider get _pv => context.read<BoardDataProvider>();

  void _spawnAdd(String type, {String content = '', double width = 180, double height = 110, Map<String, dynamic> data = const {}}) {
    HapticFeedback.heavyImpact();
    final isArrow = type == 'arrow';
    final isMedia = type == 'image' || type == 'link';
    _pv.add(BoardElement(
      type: type,
      content: content.isNotEmpty ? content : (type == 'note' || type == 'postit' ? 'Doble tap...' : ''),
      x: _randPos(),
      y: _randPos(),
      width: isArrow ? 160 : width,
      height: isArrow ? 40 : height,
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
    }
  }

  Future<void> _addLinkFromDialog() async {
    HapticFeedback.heavyImpact();
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12331a),
        title: const Text('Pegar link', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl, autofocus: true,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://...', hintStyle: TextStyle(color: Color(0xFF88FF99))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: ctrl.text.isNotEmpty ? () => Navigator.pop(ctx, ctrl.text) : null, child: const Text('Crear', style: TextStyle(color: _c))),
        ],
      ),
    );
    ctrl.dispose();
    if (url == null || url.trim().isEmpty) return;
    final raw = url.trim().contains('://') ? url.trim() : 'https://${url.trim()}';
    final host = Uri.tryParse(raw)?.host;
    _spawnAdd('link', content: url.trim(), width: 260, height: 96, data: {'url': url.trim(), 'title': (host == null || host.isEmpty) ? url.trim() : host});
  }

  void _enterConnectorMode() {
    HapticFeedback.heavyImpact();
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elegí primero una nota para conectar')));
      return;
    }
    setState(() => _connSourceId = _selectedId);
  }

  void _deleteSelected() {
    final s = _selectedId;
    if (s == null) return;
    HapticFeedback.heavyImpact();
    final el = _firstWhereOrNull(_pv.elements, (e) => e.id == s);
    if (el != null && el.type == 'image') {
      BoardMediaService().deleteImage(el.content);
    }
    _pv.delete(s);
    _editCtrls[s]?.dispose();
    _editCtrls.remove(s);
    _editing.remove(s);
    setState(() { _selectedId = null; _connSourceId = null; });
  }

  void _bringToFront() {
    final s = _selectedId;
    if (s == null) return;
    HapticFeedback.selectionClick();
    _pv.bringToFront(s);
  }

  void _startEditing(int id, String content) {
    _editCtrls[id]?.dispose();
    _editCtrls[id] = TextEditingController(text: content);
    setState(() => _editing[id] = true);
  }

  void _finishEditing(int id) {
    final text = _editCtrls[id]?.text ?? '';
    if (text.isNotEmpty) {
      final match = _firstWhereOrNull(_pv.elements, (e) => e.id == id) ??
          _firstWhereOrNull(_pv.elements, (e) => (e.createdAt.millisecondsSinceEpoch % 1000000) == id);
      if (match != null) _pv.updateContentLocal(match, text);
    }
    setState(() => _editing[id] = false);
  }

  void _createConnector(int fromId, int toId) {
    final from = _first((e) => e.id == fromId);
    final to = _first((e) => e.id == toId);
    if (from == null || to == null || from.type == 'connector' || to.type == 'connector') {
      setState(() => _connSourceId = null);
      return;
    }
    setState(() => _connSourceId = null);
    _pv.add(BoardElement(
      type: 'connector', x: 0, y: 0, width: 0, height: 0, z: 0,
      data: {'fromId': fromId, 'toId': toId, 'stroke': 3.0, 'dashed': false, 'arrow': true, 'color': '#39FF14'},
      userId: AppState.myId,
    ));
  }

  BoardElement? _first([bool Function(BoardElement)? test]) {
    for (final e in _pv.elements) {
      if (test == null || test(e)) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _boardBg,
      body: ResponsiveWrapper(builder: (context, w, h) => Stack(children: [
        _boardCanvas(),
        _headerFloating(),
        _toolsFloating(),
        if (_connSourceId != null) _connectorHint(),
      ])),
    );
  }

  Widget _headerFloating() {
    return Positioned(left: 12, top: 8, right: 12, height: 48,
      child: Row(children: [
        const Spacer(),
        if (_selectedId != null) ...[
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
      (Icons.push_pin, () => _spawnAdd('postit'), const Color(0xFFFFDE59)),
      (Icons.arrow_forward, () => _spawnAdd('arrow'), const Color(0xFF39FF14)),
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

  Widget _boardCanvas() {
    return Consumer<BoardDataProvider>(
      builder: (context, pv, _) {
        if (pv.loading) return const Center(child: CircularProgressIndicator(color: _c));
        return GestureDetector(
          onTap: () {
            if (_connSourceId != null) { setState(() => _connSourceId = null); }
            else { setState(() => _selectedId = null); }
          },
          child: InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(_boardSize),
            constrained: false,
            minScale: 0.1,
            maxScale: 5.0,
            child: SizedBox(width: _boardSize, height: _boardSize,
              child: ValueListenableBuilder<Rect>(
                valueListenable: _visibleRect,
                builder: (context, rect, _) {
                  final all = pv.elements;
                  final connectors = all.where((e) => e.type == 'connector').toList();
                  final items = all.where((e) => e.type != 'connector').toList()
                    ..sort((a, b) => a.z.compareTo(b.z));
                  return Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: _GridPainter(visibleRect: rect))),
                    if (connectors.isNotEmpty)
                      Positioned.fill(child: CustomPaint(painter: _ConnectorPainter(elements: all, connectors: connectors))),
                    for (final el in items) _buildVisibleElement(el),
                  ]);
                },
              ),
            ),
          ),
        );
      },
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
          if (el.id == null) return;
          if (el.type == 'note' || el.type == 'postit' || el.type == 'arrow') {
            _startEditing(id, el.content);
          } else if (el.type == 'link') {
            _editLink(el);
          }
        },
        onPanUpdate: (d) => _pv.moveLocal(el, el.x + d.delta.dx, el.y + d.delta.dy),
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
    } else if (el.type == 'arrow') {
      body = Container(width: w, height: h, padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(child: Text(el.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14))),
          const Icon(Icons.arrow_forward, color: Color(0xFF111111), size: 22),
        ]));
    } else {
      body = Container(width: w, height: h, padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (el.content.isNotEmpty)
            Expanded(child: Text(el.content, style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14, height: 1.3, letterSpacing: 0.5), maxLines: 6, overflow: TextOverflow.ellipsis))
          else
            Expanded(child: Center(child: Icon(el.type == 'postit' ? Icons.push_pin : Icons.note_add, color: const Color(0xFF111111), size: h * 0.4))),
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
    final ctrl = TextEditingController(text: el.content);
    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16233c),
        title: const Text('Editar link', style: TextStyle(color: Colors.white)),
        content: TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'https://...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Guardar', style: TextStyle(color: _c))),
        ],
      ),
    );
    if (newUrl == null || newUrl.trim().isEmpty) return;
    final raw = newUrl.trim().contains('://') ? newUrl.trim() : 'https://${newUrl.trim()}';
    _pv.updateDataLocal(el, {'url': newUrl.trim(), 'title': Uri.tryParse(raw)?.host ?? newUrl});
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
    var x = el.x, y = el.y, w = el.width, h = el.height;
    switch (q) {
      case _Handle.bottomRight: w += dx; h += dy;
      case _Handle.bottomLeft: x += dx; w -= dx; h += dy;
      case _Handle.topRight: w += dx; y += dy; h -= dy;
      case _Handle.topLeft: x += dx; w -= dx; y += dy; h -= dy;
      case _Handle.right: w += dx;
      case _Handle.left: x += dx; w -= dx;
      case _Handle.bottom: h += dy;
      case _Handle.top: y += dy; h -= dy;
    }
    if (w < min || h < min) return;
    if (x != el.x || y != el.y) _pv.moveLocal(el, x, y);
    _pv.resizeLocal(el, w, h);
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
  final Rect visibleRect;
  _GridPainter({this.visibleRect = Rect.zero});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A3A1A)..strokeWidth = 1.5;
    const spacing = 30.0;
    final startX = (visibleRect.left / spacing).floor() * spacing;
    final startY = (visibleRect.top / spacing).floor() * spacing;
    final endX = (visibleRect.right / spacing).ceil() * spacing;
    final endY = (visibleRect.bottom / spacing).ceil() * spacing;
    for (double x = startX; x <= endX; x += spacing) {
      for (double y = startY; y <= endY; y += spacing) {
        canvas.drawCircle(Offset(x.clamp(0, size.width), y.clamp(0, size.height)), 1.5, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.visibleRect != visibleRect;
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
        final fill = Paint()..color = lineColor..style = PaintingStyle.fill;
        _drawArrowhead(canvas, a, b, fill, strokeW);
      }
    }
  }

  void _drawLine(Canvas canvas, Offset a, Offset b, Paint paint, bool dashed) {
    if (!dashed) { canvas.drawLine(a, b, paint); return; }
    const dash = 10.0; const gap = 8.0;
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

  void _drawArrowhead(Canvas canvas, Offset tip, Offset a, Paint paint, double w) {
    final vec = tip - a;
    final d = vec.distance == 0 ? 1.0 : vec.distance;
    final n = vec / d;
    final perp = Offset(-n.dy, n.dx);
    final size = 8 + w * 1.5;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - n.dx * size + perp.dx * size * 0.55, tip.dy - n.dy * size + perp.dy * size * 0.55)
      ..lineTo(tip.dx - n.dx * size - perp.dx * size * 0.55, tip.dy - n.dy * size - perp.dy * size * 0.55)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      oldDelegate.connectors != connectors;
}