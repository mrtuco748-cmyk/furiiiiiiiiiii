import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../app_state.dart';

/// Editor de dibujo libre que se abre como bottom sheet.
class BoardDrawingEditor extends StatefulWidget {
  final BoardProviderV2 provider;
  final VoidCallback onClose;

  const BoardDrawingEditor({
    super.key,
    required this.provider,
    required this.onClose,
  });

  @override
  State<BoardDrawingEditor> createState() => _BoardDrawingEditorState();
}

class _BoardDrawingEditorState extends State<BoardDrawingEditor> {
  late DrawingData _data;
  DrawingStroke? _currentStroke;
  String _tool = 'brush';
  String _color = '#FFFFFF';
  double _brushSize = 3.0;
  int? _targetId;

  final List<String> _tools = ['brush', 'eraser', 'line', 'rectangle', 'circle'];
  final List<String> _colors = [
    '#FFFFFF', '#FF5757', '#FFDE59', '#00FF66',
    '#00F0FF', '#FF66C4', '#9D00FF', '#FF8800',
  ];

  @override
  void initState() {
    super.initState();
    _targetId = _latestDrawingId();
    final existing = _findTarget();
    _data = existing != null
        ? DrawingData.fromMap(existing.data)
        : DrawingData();
  }

  int? _latestDrawingId() {
    final drawings = widget.provider.elements
        .where((e) => e.type == BoardElementType.drawing)
        .toList();
    if (drawings.isEmpty) return null;
    return drawings.last.id;
  }

  BoardElementV2? _findTarget() {
    if (_targetId == null) {
      final drawings = widget.provider.elements
          .where((e) => e.type == BoardElementType.drawing)
          .toList();
      if (drawings.isEmpty) return null;
      return drawings.last;
    }
    for (final e in widget.provider.elements) {
      if (e.id == _targetId) return e;
    }
    return null;
  }

  void _onPanStart(Offset pos) {
    setState(() {
      _currentStroke = DrawingStroke(
        type: _tool,
        color: _tool == 'eraser' ? '#111111' : _color,
        width: _tool == 'eraser' ? _brushSize * 3 : _brushSize,
        points: [_toMap(pos)],
      );
    });
  }

  void _onPanUpdate(Offset pos) {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, _toMap(pos)],
      );
    });
  }

  void _onPanEnd() {
    if (_currentStroke == null) return;
    setState(() {
      _data = _data.copyWith(
        strokes: [..._data.strokes, _currentStroke!],
      );
      _currentStroke = null;
    });
  }

  Map<String, double> _toMap(Offset pos) => {'x': pos.dx, 'y': pos.dy};

  void _saveData() {
    final target = _findTarget();
    if (target == null) return;
    final updated = target.copyWith(
      data: _data.toMap(),
      width: _data.width,
      height: _data.height,
    );
    widget.provider.update(updated);
  }

  void _undo() {
    if (_data.strokes.isEmpty) return;
    setState(() {
      _data = _data.copyWith(
        strokes: _data.strokes.sublist(0, _data.strokes.length - 1),
      );
    });
    _saveData();
  }

  void _clear() {
    setState(() {
      _data = DrawingData(width: _data.width, height: _data.height);
    });
    _saveData();
  }

  void _finish() {
    _saveData();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Canvas area
              Container(
                height: 250,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: GestureDetector(
                  onPanStart: (d) => _onPanStart(d.localPosition),
                  onPanUpdate: (d) => _onPanUpdate(d.localPosition),
                  onPanEnd: (_) => _onPanEnd(),
                  child: CustomPaint(
                    painter: _DrawingCanvasPainter(
                      strokes: _data.strokes,
                      currentStroke: _currentStroke,
                    ),
                    size: Size(_data.width, _data.height),
                  ),
                ),
              ),
              // Tools
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    ..._tools.map(
                      (t) => _ToolButton(
                        icon: _toolIcon(t),
                        isActive: _tool == t,
                        onTap: () => setState(() => _tool = t),
                      ),
                    ),
                    const Spacer(),
                    _ToolButton(
                      icon: Icons.undo,
                      onTap: _undo,
                    ),
                    const SizedBox(width: 4),
                    _ToolButton(
                      icon: Icons.delete,
                      onTap: _clear,
                    ),
                    const SizedBox(width: 4),
                    _ToolButton(
                      icon: Icons.check,
                      isActive: true,
                      onTap: _finish,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Colors
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    ..._colors.map(
                      (c) => GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: _parseColor(c, Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _color == c
                                  ? const Color(0xFF4FC3F7)
                                  : const Color(0xFF333333),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_brushSize.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 80,
                      child: Slider(
                        value: _brushSize,
                        min: 1,
                        max: 10,
                        divisions: 18,
                        onChanged: (v) => setState(() => _brushSize = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  IconData _toolIcon(String tool) {
    switch (tool) {
      case 'brush':
        return Icons.brush;
      case 'eraser':
        return Icons.auto_fix_normal;
      case 'line':
        return Icons.show_chart;
      case 'rectangle':
        return Icons.crop_square;
      case 'circle':
        return Icons.circle;
      default:
        return Icons.brush;
    }
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

class _DrawingCanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  _DrawingCanvasPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final color = _parseColor(stroke.color, Colors.white);
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.type == 'line' && stroke.points.length >= 2) {
      final start = _toOffset(stroke.points.first);
      final end = _toOffset(stroke.points.last);
      canvas.drawLine(start, end, paint);
    } else if (stroke.type == 'rectangle' && stroke.points.length >= 2) {
      final start = _toOffset(stroke.points.first);
      final end = _toOffset(stroke.points.last);
      canvas.drawRect(Rect.fromPoints(start, end), paint);
    } else if (stroke.type == 'circle' && stroke.points.length >= 2) {
      final start = _toOffset(stroke.points.first);
      final end = _toOffset(stroke.points.last);
      final center = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );
      final radius = (end - start).distance / 2;
      canvas.drawCircle(center, radius, paint);
    } else {
      final path = Path();
      final first = _toOffset(stroke.points.first);
      path.moveTo(first.dx, first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final prev = _toOffset(stroke.points[i - 1]);
        final curr = _toOffset(stroke.points[i]);
        final mid = Offset(
          (prev.dx + curr.dx) / 2,
          (prev.dy + curr.dy) / 2,
        );
        path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  Offset _toOffset(Map<String, double> point) {
    return Offset(point['x'] ?? 0, point['y'] ?? 0);
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingCanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4FC3F7) : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF0A0A0A) : Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}
