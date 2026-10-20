import 'package:flutter/material.dart';

import '../../models/note_style_config.dart';
import '../../painters/note_shape_utils.dart';

class ShapeMiniPreviewPainter extends CustomPainter {
  final NoteShapeType shape;
  ShapeMiniPreviewPainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final path = NoteShapeUtils.buildShapePath(shape, size);
    final fillPaint = Paint()
      ..color = const Color(0x38FFFFFF)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant ShapeMiniPreviewPainter oldDelegate) => oldDelegate.shape != shape;
}

class BorderMiniPreviewPainter extends CustomPainter {
  final NoteBorderType borderType;
  BorderMiniPreviewPainter({required this.borderType});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    switch (borderType) {
      case NoteBorderType.none:
        final p = Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawLine(Offset(size.width * 0.3, size.height * 0.25), Offset(size.width * 0.7, size.height * 0.75), p);
        break;
      case NoteBorderType.solid:
        canvas.drawLine(Offset(4, cy), Offset(size.width - 4, cy), paint);
        break;
      case NoteBorderType.dotted:
        final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        for (double x = 6; x <= size.width - 6; x += 8) {
          canvas.drawCircle(Offset(x, cy), 2.2, dotPaint);
        }
        break;
      case NoteBorderType.dashed:
        for (double x = 4; x < size.width - 6; x += 11) {
          canvas.drawLine(Offset(x, cy), Offset(x + 6, cy), paint);
        }
        break;
      case NoteBorderType.doubleLine:
        canvas.drawLine(Offset(4, cy - 3), Offset(size.width - 4, cy - 3), paint);
        canvas.drawLine(Offset(4, cy + 3), Offset(size.width - 4, cy + 3), paint);
        break;
      case NoteBorderType.wavy:
        final path = Path()..moveTo(4, cy);
        for (double x = 4; x < size.width - 6; x += 10) {
          path.quadraticBezierTo(x + 2.5, cy - 4, x + 5, cy);
          path.quadraticBezierTo(x + 7.5, cy + 4, x + 10, cy);
        }
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant BorderMiniPreviewPainter oldDelegate) => oldDelegate.borderType != borderType;
}

class BlockFormatMiniPainter extends CustomPainter {
  final TextBlockFormat format;
  BlockFormatMiniPainter({required this.format});

  @override
  void paint(Canvas canvas, Size size) {
    final textPaint = Paint()..color = Colors.white70..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    final accentPaint = Paint()..color = const Color(0xFF2EE50F)..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;

    if (format == TextBlockFormat.sunken) {
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(2, 2, w - 4, h - 4), const Radius.circular(5));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xAA0C0F17));
    }

    canvas.drawLine(Offset(6, h * 0.36), Offset(w - 8, h * 0.36), textPaint);
    canvas.drawLine(Offset(6, h * 0.62), Offset(w * 0.65, h * 0.62), textPaint);

    switch (format) {
      case TextBlockFormat.none:
        break;
      case TextBlockFormat.escuadra:
        final p = Path()..moveTo(w - 3, 3)..lineTo(w - 3, h - 3)..lineTo(4, h - 3);
        canvas.drawPath(p, accentPaint);
        break;
      case TextBlockFormat.escuadraLeft:
        final p = Path()..moveTo(3, 3)..lineTo(3, h - 3)..lineTo(w - 4, h - 3);
        canvas.drawPath(p, accentPaint);
        break;
      case TextBlockFormat.thickUnderline:
        canvas.drawLine(Offset(4, h - 3), Offset(w - 4, h - 3), accentPaint..strokeWidth = 3.4);
        break;
      case TextBlockFormat.topBottomLines:
        canvas.drawLine(Offset(3, 2), Offset(w - 3, 2), accentPaint);
        canvas.drawLine(Offset(3, h - 2), Offset(w - 3, h - 2), accentPaint);
        break;
      case TextBlockFormat.sunken:
        canvas.drawLine(Offset(3, 3), Offset(w - 3, 3), Paint()..color = const Color(0xFF2EE50F)..strokeWidth = 1.6);
        break;
      case TextBlockFormat.quoteBar:
        canvas.drawLine(Offset(3, 3), Offset(3, h - 3), accentPaint..strokeWidth = 3.5);
        break;
      case TextBlockFormat.framed:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, 2, w - 4, h - 4), const Radius.circular(4)), accentPaint..strokeWidth = 2.0);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant BlockFormatMiniPainter oldDelegate) => oldDelegate.format != format;
}

class ImagePositionMiniPainter extends CustomPainter {
  final InlineImagePosition position;
  ImagePositionMiniPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white54..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    final imgPaint = Paint()..color = const Color(0xFF2EE50F)..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    canvas.drawLine(const Offset(4, 4), Offset(w * 0.7, 4), linePaint);

    switch (position) {
      case InlineImagePosition.aboveBody:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, 9, w - 8, 11), const Radius.circular(3)), imgPaint);
        canvas.drawLine(const Offset(4, 25), Offset(w - 4, 25), linePaint);
        canvas.drawLine(const Offset(4, 30), Offset(w - 6, 30), linePaint);
        break;
      case InlineImagePosition.middleBody:
        canvas.drawLine(const Offset(4, 10), Offset(w - 4, 10), linePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, 14, w - 8, 11), const Radius.circular(3)), imgPaint);
        canvas.drawLine(const Offset(4, 30), Offset(w - 5, 30), linePaint);
        break;
      case InlineImagePosition.belowBody:
        canvas.drawLine(const Offset(4, 10), Offset(w - 4, 10), linePaint);
        canvas.drawLine(const Offset(4, 15), Offset(w - 6, 15), linePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, 20, w - 8, 11), const Radius.circular(3)), imgPaint);
        break;
      case InlineImagePosition.footer:
        canvas.drawLine(const Offset(4, 10), Offset(w - 4, 10), linePaint);
        canvas.drawLine(const Offset(4, 15), Offset(w - 6, 15), linePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, h - 10, w - 4, 8), const Radius.circular(2)), imgPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant ImagePositionMiniPainter oldDelegate) => oldDelegate.position != position;
}
