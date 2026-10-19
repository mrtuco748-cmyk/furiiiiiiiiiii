import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/board_element.dart';
import '../milanote_colors.dart';

/// Dibuja líneas y flechas conectoras entre elementos del tablero Milanote
class ConnectorLinePainter extends CustomPainter {
  final List<BoardElement> elements;
  final Offset? draftStart;
  final Offset? draftEnd;
  final BoardElement? activeDraggedElement;

  const ConnectorLinePainter({
    required this.elements,
    this.draftStart,
    this.draftEnd,
    this.activeDraggedElement,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Mapa rápido de elementos por id
    final map = <int, BoardElement>{};
    for (final el in elements) {
      if (el.id != null) map[el.id!] = el;
    }

    // Sobreescribe la posición en tiempo real del elemento arrastrado si existe
    if (activeDraggedElement != null && activeDraggedElement!.id != null) {
      map[activeDraggedElement!.id!] = activeDraggedElement!;
    }

    // Dibujar todas las conexiones persistidas
    for (final el in elements) {
      if (el.type == 'connection') {
        final fromId = el.data['fromId'] as int?;
        final toId = el.data['toId'] as int?;
        if (fromId != null && toId != null && map.containsKey(fromId) && map.containsKey(toId)) {
          final fromEl = map[fromId]!;
          final toEl = map[toId]!;

          final fromCenter = Offset(fromEl.x + fromEl.width / 2, fromEl.y + fromEl.height / 2);
          final toCenter = Offset(toEl.x + toEl.width / 2, toEl.y + toEl.height / 2);

          final lineColor = MilanotePalette.parseHex(el.color, defaultColor: const Color(0xFF00E5FF));
          _drawCurvedArrow(canvas, fromCenter, toCenter, lineColor, el.title);
        }
      }
    }

    // Dibujar línea temporal mientras se arrastra una conexión
    if (draftStart != null && draftEnd != null) {
      _drawCurvedArrow(canvas, draftStart!, draftEnd!, const Color(0xFF39FF14), 'Conectando...');
    }
  }

  void _drawCurvedArrow(Canvas canvas, Offset p1, Offset p2, Color color, String label) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    // Curvatura suave bezier
    final dx = p2.dx - p1.dx;
    final cx1 = p1.dx + dx * 0.5;
    final cy1 = p1.dy;
    final cx2 = p1.dx + dx * 0.5;
    final cy2 = p2.dy;

    path.cubicTo(cx1, cy1, cx2, cy2, p2.dx, p2.dy);
    canvas.drawPath(path, linePaint);

    // Cabeza de flecha
    final angle = math.atan2(p2.dy - cy2, p2.dx - cx2);
    final arrowSize = 12.0;

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    arrowPath.moveTo(p2.dx, p2.dy);
    arrowPath.lineTo(
      p2.dx - arrowSize * math.cos(angle - math.pi / 6),
      p2.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    arrowPath.lineTo(
      p2.dx - arrowSize * math.cos(angle + math.pi / 6),
      p2.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Círculo en el punto de origen
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p1, 4.0, dotPaint);

    // Si tiene etiqueta, dibujarla en el medio
    if (label.isNotEmpty) {
      final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xDD141416),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(midPoint.dx - textPainter.width / 2, midPoint.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConnectorLinePainter oldDelegate) {
    return oldDelegate.elements != elements ||
        oldDelegate.draftStart != draftStart ||
        oldDelegate.draftEnd != draftEnd ||
        oldDelegate.activeDraggedElement != activeDraggedElement;
  }
}
