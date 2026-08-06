import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/board_data_provider.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../app_state.dart';

const _c = Color(0xFF39FF14);
const _boardBg = Color(0xFF0D1A0D);
const _boardSize = 20000.0;

final _noteColors = ['#FF5757','#FFDE59','#00FF66','#00F0FF','#FF66C4','#9D00FF','#FF8800','#0088FF'];

class PizarraScreen extends StatefulWidget {
  const PizarraScreen({super.key});
  @override
  State<PizarraScreen> createState() => _PizarraScreenState();
}

class _PizarraScreenState extends State<PizarraScreen> {
  final _rng = Random(7);
  final _transformController = TransformationController();
  int? _selectedId;
  final _editCtrls = <int, TextEditingController>{};
  final _editing = <int, bool>{};
  final _visibleRect = ValueNotifier<Rect>(Rect.zero);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BoardDataProvider>().load());
    _transformController.addListener(_onTransformChanged);
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

  void _addElement(String type) {
    HapticFeedback.heavyImpact();
    final pv = context.read<BoardDataProvider>();
    final center = _transformController.value.getTranslation();
    final x = (center.x.isFinite ? center.x.abs() : 500) + _rng.nextDouble() * 200 + 200;
    final y = (center.y.isFinite ? center.y.abs() : 500) + _rng.nextDouble() * 200 + 200;
    final rot = (_rng.nextDouble() - 0.5) * 0.1;
    final color = _noteColors[_rng.nextInt(_noteColors.length)];
    pv.add(BoardElement(type: type, content: type == 'note' ? 'Doble tap...' : '', x: x, y: y, width: 180, height: type == 'arrow' ? 40 : 110, rotation: rot, color: color, userId: AppState.myId));
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    HapticFeedback.heavyImpact();
    context.read<BoardDataProvider>().delete(_selectedId!);
    _editCtrls[_selectedId]?.dispose();
    _editCtrls.remove(_selectedId);
    _editing.remove(_selectedId);
    setState(() => _selectedId = null);
  }

  void _startEditing(int id, String content) {
    _editCtrls[id]?.dispose();
    _editCtrls[id] = TextEditingController(text: content);
    setState(() => _editing[id] = true);
  }

  void _finishEditing(int id) {
    final text = _editCtrls[id]?.text ?? '';
    final pv = context.read<BoardDataProvider>();
    if (text.isNotEmpty) {
      final candidates = pv.elements.where((e) => e.id == id);
      final byCreated = pv.elements
          .where((e) => (e.createdAt.millisecondsSinceEpoch % 1000000) == id)
          .toList();
      final match = candidates.isNotEmpty
          ? candidates.first
          : (byCreated.isNotEmpty ? byCreated.first : null);
      if (match != null) {
        pv.updateContentLocal(match, text);
      }
    }
    setState(() => _editing[id] = false);
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
    _transformController.value = Matrix4.identity()
      ..translate(-500, -400);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _boardBg,
      body: ResponsiveWrapper(builder: (context, w, h) => Stack(children: [
        _boardCanvas(),
        _headerFloating(),
        _toolsFloating(),
      ])),
    );
  }

  Widget _headerFloating() {
    final isMine = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
    return Positioned(left: 12, top: 8, right: 12, height: 48,
      child: Row(children: [
        TapTile(onTap: () { HapticFeedback.heavyImpact(); _goToCenter(); }, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Color(0xFF1A3A1A).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: _c, width: 2)), child: Text(isMine, style: GoogleFonts.bangers(color: _c, fontSize: 22, fontWeight: FontWeight.bold)))),
        const Spacer(),
        if (_selectedId != null)
          Padding(padding: const EdgeInsets.only(right: 8), child: TapTile(onTap: _deleteSelected, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFFF5757), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0xAA000000), offset: Offset(2, 2), blurRadius: 4)]), child: const Icon(Icons.delete, color: Colors.white, size: 24)))),
        TapTile(onTap: () { HapticFeedback.heavyImpact(); _addElement('note'); }, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0xAA000000), offset: Offset(2, 2), blurRadius: 4)]), child: const Icon(Icons.add, color: Color(0xFF0D1A0D), size: 24))),
      ]),
    );
  }

  Widget _toolsFloating() {
    final tools = [
      (Icons.note_add, 'note', const Color(0xFF00F0FF)),
      (Icons.arrow_forward, 'arrow', const Color(0xFF39FF14)),
      (Icons.push_pin, 'postit', const Color(0xFFFFDE59)),
      (Icons.image, 'note', const Color(0xFF9D00FF)),
    ];
    return Positioned(right: 12, top: 80,
      child: Column(children: tools.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TapTile(onTap: () => _addElement(t.$2), child: Container(width: 46, height: 46, decoration: BoxDecoration(color: t.$3.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: t.$3, width: 2), boxShadow: const [BoxShadow(color: Color(0xAA000000), offset: Offset(2, 2), blurRadius: 4)]), child: Icon(t.$1, color: t.$3, size: 22))),
      )).toList()),
    );
  }

  Widget _boardCanvas() {
    return Consumer<BoardDataProvider>(
      builder: (context, pv, _) {
        if (pv.loading) return const Center(child: CircularProgressIndicator(color: _c));
        return GestureDetector(
          onTap: () => setState(() => _selectedId = null),
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
                  return CustomPaint(
                    painter: _DotPainter(visibleRect: rect),
                    child: Stack(children: _buildVisibleElements(pv, rect)),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildVisibleElements(BoardDataProvider pv, Rect viewport) {
    final margin = 500.0;
    final visible = viewport.inflate(margin);
    final myInitial = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
    final partnerInitial = myInitial == 'F' ? 'R' : 'F';

    return pv.elements.where((el) {
      return el.x < visible.right && el.x + el.width > visible.left &&
             el.y < visible.bottom && el.y + el.height > visible.top;
    }).map((el) {
      final id = el.id ?? (el.createdAt.millisecondsSinceEpoch % 1000000);
      final selected = _selectedId == id;
      final editing = _editing[id] == true;
      final ownerInitial = el.isMine ? myInitial : partnerInitial;
      return Positioned(left: el.x, top: el.y,
        child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedId = id); },
          onDoubleTap: () => _startEditing(id, el.content),
          onPanUpdate: (d) {
            context.read<BoardDataProvider>().moveLocal(el, el.x + d.delta.dx, el.y + d.delta.dy);
          },
          child: _buildElement(el, id, selected, editing, ownerInitial),
        ),
      );
    }).toList();
  }

  Widget _buildElement(BoardElement el, int id, bool selected, bool editing, String ownerInitial) {
    final w = el.width; final h = el.height;
    final color = _hexToColor(el.color);

    if (editing) {
      return Container(width: w, height: h + 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF1A3A1A), border: Border.all(color: _c, width: 3), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Expanded(child: TextField(
            controller: _editCtrls[id], autofocus: true, maxLines: null,
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            onSubmitted: (_) => _finishEditing(id),
          )),
          TapTile(onTap: () => _finishEditing(id), child: Container(width: 44, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.check, color: Color(0xFF0D1A0D), size: 22))),
        ]),
      );
    }

    return Transform.rotate(angle: el.rotation, child: Container(
      width: w, height: h,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color, border: Border.all(color: selected ? _c : color, width: selected ? 4 : 2), borderRadius: BorderRadius.circular(14)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (el.content.isNotEmpty)
                Expanded(child: Text(el.content, style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14, height: 1.3, letterSpacing: 0.5), maxLines: 6, overflow: TextOverflow.ellipsis))
              else
                Expanded(child: Center(child: Icon(el.type == 'arrow' ? Icons.arrow_forward : (el.type == 'postit' ? Icons.push_pin : Icons.note_add), color: const Color(0xFF111111), size: h * 0.5))),
              Text(ownerInitial, style: GoogleFonts.bangers(color: const Color(0xFF111111).withValues(alpha: 0.65), fontSize: 10)),
            ],
          ),
          Positioned(right: 0, top: 0, child: GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              if (id != 0) {
                context.read<BoardDataProvider>().delete(id);
                _editCtrls[id]?.dispose();
                _editCtrls.remove(id);
                _editing.remove(id);
                if (_selectedId == id) setState(() => _selectedId = null);
              }
            },
            child: Container(width: 18, height: 18, decoration: BoxDecoration(color: const Color(0xFFFF4444), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.close, color: Colors.white, size: 12)),
          )),
        ],
      ),
    ));
  }
}

class _DotPainter extends CustomPainter {
  final Rect visibleRect;
  _DotPainter({this.visibleRect = Rect.zero});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A3A1A)..strokeWidth = 1.5;
    const spacing = 30.0;
    final startX = (visibleRect.left / spacing).floor() * spacing;
    final startY = (visibleRect.top / spacing).floor() * spacing;
    final endX = (visibleRect.right / spacing).ceil() * spacing;
    final endY = (visibleRect.bottom / spacing).ceil() * spacing;
    for (double x = startX.clamp(0, size.width); x <= endX.clamp(0, size.width); x += spacing) {
      for (double y = startY.clamp(0, size.height); y <= endY.clamp(0, size.height); y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) => oldDelegate.visibleRect != visibleRect;
}
