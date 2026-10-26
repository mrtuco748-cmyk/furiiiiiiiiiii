import 'package:flutter/material.dart';

/// Painter para la previsualización en vivo continua al trazar una nueva viñeta
/// o realizar un corte de panel con el dedo.
class ComicDrawGuidePainter extends CustomPainter {
  final Rect? drawRect;
  final Offset? sliceStart;
  final Offset? sliceEnd;

  const ComicDrawGuidePainter({
    this.drawRect,
    this.sliceStart,
    this.sliceEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Previsualización de viñeta en dibujo libre
    if (drawRect != null && drawRect!.width > 0 && drawRect!.height > 0) {
      final fillPaint = Paint()
        ..color = const Color(0x3300D4FF)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = const Color(0xFF00D4FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final rrect = RRect.fromRectAndRadius(drawRect!, const Radius.circular(8));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);

      // 4 esquinas marcadas
      final markerPaint = Paint()..color = const Color(0xFF00D4FF);
      canvas.drawCircle(drawRect!.topLeft, 4, markerPaint);
      canvas.drawCircle(drawRect!.topRight, 4, markerPaint);
      canvas.drawCircle(drawRect!.bottomLeft, 4, markerPaint);
      canvas.drawCircle(drawRect!.bottomRight, 4, markerPaint);
    }

    // 2. Previsualización de línea de corte (Navaja / Knife)
    if (sliceStart != null && sliceEnd != null) {
      final glowPaint = Paint()
        ..color = const Color(0x66FF453A)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      final linePaint = Paint()
        ..color = const Color(0xFFFF453A)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(sliceStart!, sliceEnd!, glowPaint);
      canvas.drawLine(sliceStart!, sliceEnd!, linePaint);

      canvas.drawCircle(sliceStart!, 5, linePaint);
      canvas.drawCircle(sliceEnd!, 5, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ComicDrawGuidePainter oldDelegate) {
    return oldDelegate.drawRect != drawRect ||
        oldDelegate.sliceStart != sliceStart ||
        oldDelegate.sliceEnd != sliceEnd;
  }
}
