import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';

/// Renderer para elementos de dibujo libre.
/// Muestra los strokes como CustomPainter o la imagen renderizada si existe.
class BoardDrawingRenderer extends StatelessWidget {
  final BoardElementV2 element;

  const BoardDrawingRenderer({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    final data = DrawingData.fromMap(element.data);
    final w = element.width ?? data.width;
    final h = element.height ?? data.height;

    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
      ),
      child: data.imagePath != null
          ? Image.file(
              File(data.imagePath!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => const Center(
                child: Icon(Icons.broken_image,
                    color: Colors.white54, size: 32),
              ),
            )
          : CustomPaint(
              painter: _DrawingPainter(strokes: data.strokes),
              size: Size(w, h),
            ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  _DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final color = _parseColor(stroke.color, Colors.white);
      final paint = Paint()
        ..color = stroke.type == 'eraser'
            ? const Color(0xFF111111)
            : color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.type == 'line') {
        if (stroke.points.length >= 2) {
          final start = _toOffset(stroke.points.first);
          final end = _toOffset(stroke.points.last);
          canvas.drawLine(start, end, paint);
        }
      } else if (stroke.type == 'rectangle') {
        if (stroke.points.length >= 2) {
          final start = _toOffset(stroke.points.first);
          final end = _toOffset(stroke.points.last);
          canvas.drawRect(
            Rect.fromPoints(start, end),
            paint..style = PaintingStyle.stroke,
          );
        }
      } else if (stroke.type == 'circle') {
        if (stroke.points.length >= 2) {
          final start = _toOffset(stroke.points.first);
          final end = _toOffset(stroke.points.last);
          final center = Offset(
            (start.dx + end.dx) / 2,
            (start.dy + end.dy) / 2,
          );
          final radius = (end - start).distance / 2;
          canvas.drawCircle(center, radius, paint..style = PaintingStyle.stroke);
        }
      } else {
        // Brush or eraser: draw path through points
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
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
