import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';

/// Renderer para conectores (líneas entre elementos).
/// Calcula posiciones en tiempo de renderizado desde los elementos referenciados.
class BoardConnectorRenderer extends CustomPainter {
  final BoardElementV2 connector;
  final List<BoardElementV2> allElements;

  BoardConnectorRenderer({
    required this.connector,
    required this.allElements,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final data = ConnectorData.fromMap(connector.data);
    if (data.fromId == null || data.toId == null) return;

    final fromEl = _byId(data.fromId);
    final toEl = _byId(data.toId);
    if (fromEl == null || toEl == null) return;

    final fromCenter = Offset(
      fromEl.x + (fromEl.width ?? 180) / 2,
      fromEl.y + (fromEl.height ?? 110) / 2,
    );
    final toCenter = Offset(
      toEl.x + (toEl.width ?? 180) / 2,
      toEl.y + (toEl.height ?? 110) / 2,
    );

    final color = _parseColor(data.color, const Color(0xFF39FF14));
    final stroke = Paint()
      ..color = color
      ..strokeWidth = data.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (data.style == 'straight') {
      canvas.drawLine(fromCenter, toCenter, stroke);
    } else if (data.style == 'dashed') {
      _drawDashedLine(canvas, fromCenter, toCenter, stroke);
    } else {
      _drawBezierCurve(canvas, fromCenter, toCenter, data, stroke);
    }

    // Arrow at destination
    _drawArrowhead(canvas, toCenter, fromCenter, color, data.strokeWidth);

    // Label
    if (data.label != null && data.label!.isNotEmpty) {
      _drawLabel(canvas, fromCenter, toCenter, data, color);
    }
  }

  void _drawBezierCurve(
    Canvas canvas,
    Offset from,
    Offset to,
    ConnectorData data,
    Paint stroke,
  ) {
    final distance = (to - from).distance;
    final curvature = min(distance * 0.4, 100);

    // Control points for bezier curve
    final cp1 = Offset(
      from.dx + (to.dx - from.dx) * 0.5,
      from.dy - curvature,
    );
    final cp2 = Offset(
      from.dx + (to.dx - from.dx) * 0.5,
      to.dy + curvature,
    );

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, to.dx, to.dy);

    canvas.drawPath(path, stroke);
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint stroke) {
    const dash = 10.0;
    const gap = 8.0;
    final total = (to - from).distance;
    if (total == 0) return;
    final dir = (to - from) / total;
    double t = 0;
    while (t < total) {
      final e = (t + dash > total) ? total : t + dash;
      canvas.drawLine(from + dir * t, from + dir * e, stroke);
      t += dash + gap;
    }
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset tip,
    Offset from,
    Color color,
    double strokeWidth,
  ) {
    final vec = tip - from;
    final d = vec.distance == 0 ? 1.0 : vec.distance;
    final n = vec / d;
    final perp = Offset(-n.dy, n.dx);
    final size = 8 + strokeWidth * 1.5;

    final fill = Paint()..color = color..style = PaintingStyle.fill;
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

    canvas.drawPath(path, fill);
  }

  void _drawLabel(
    Canvas canvas,
    Offset from,
    Offset to,
    ConnectorData data,
    Color color,
  ) {
    final mid = Offset(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: data.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final bgRect = Rect.fromCenter(
      center: mid,
      width: textPainter.width + 12,
      height: textPainter.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFF0A0A0A)
        ..style = PaintingStyle.fill,
    );

    textPainter.paint(
      canvas,
      Offset(
        mid.dx - textPainter.width / 2,
        mid.dy - textPainter.height / 2,
      ),
    );
  }

  BoardElementV2? _byId(int? id) {
    if (id == null) return null;
    for (final e in allElements) {
      if (e.id == id) return e;
    }
    return null;
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
  bool shouldRepaint(covariant BoardConnectorRenderer oldDelegate) {
    return oldDelegate.connector != connector ||
        oldDelegate.allElements != allElements;
  }
}

/// Painter que renderiza múltiples conectores a la vez.
/// Solo pinta los que tienen al menos un extremo dentro del viewport (culling).
class MultiConnectorPainter extends CustomPainter {
  final List<BoardElementV2> connectors;
  final List<BoardElementV2> allElements;
  final Rect visibleRect;

  MultiConnectorPainter({
    required this.connectors,
    required this.allElements,
    this.visibleRect = Rect.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final view = visibleRect == Rect.zero ? null : visibleRect.inflate(600);
    for (final connector in connectors) {
      final data = ConnectorData.fromMap(connector.data);
      BoardElementV2? fromEl;
      BoardElementV2? toEl;
      for (final e in allElements) {
        if (e.id == data.fromId) fromEl = e;
        if (e.id == data.toId) toEl = e;
      }
      if (fromEl == null || toEl == null) continue;

      final fromCenter = Offset(
        fromEl.x + (fromEl.width ?? 180) / 2,
        fromEl.y + (fromEl.height ?? 110) / 2,
      );
      final toCenter = Offset(
        toEl.x + (toEl.width ?? 180) / 2,
        toEl.y + (toEl.height ?? 110) / 2,
      );
      if (view != null &&
          !view.contains(fromCenter) &&
          !view.contains(toCenter)) {
        continue;
      }

      final painter = BoardConnectorRenderer(
        connector: connector,
        allElements: allElements,
      );
      painter.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant MultiConnectorPainter oldDelegate) {
    return oldDelegate.connectors != connectors ||
        oldDelegate.allElements != allElements ||
        oldDelegate.visibleRect != visibleRect;
  }
}
