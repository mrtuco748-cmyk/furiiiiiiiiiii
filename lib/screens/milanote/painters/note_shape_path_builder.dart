import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/note_style_config.dart';

/// Constructor de los trazos (`Path`) geométricos para las formas de tarjeta del Pizarrón.
class NoteShapePathBuilder {
  static Path buildShapePath(
    NoteShapeType shape,
    Size size, {
    double inset = 0.0,
  }) {
    final left = inset;
    final top = inset;
    final w = math.max(10.0, size.width - inset * 2);
    final h = math.max(10.0, size.height - inset * 2);
    final right = left + w;
    final bottom = top + h;
    final cx = left + w / 2;
    final cy = top + h / 2;
    final minSide = math.min(w, h);

    final path = Path();

    switch (shape) {
      case NoteShapeType.square:
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, w, h),
            const Radius.circular(4),
          ),
        );
        break;

      case NoteShapeType.rounded:
        final r = math.min(24.0, minSide * 0.22);
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, w, h),
            Radius.circular(r),
          ),
        );
        break;

      case NoteShapeType.note:
        final fold = math.min(34.0, minSide * 0.24);
        final r = math.min(12.0, minSide * 0.10);
        path.moveTo(left + r, top);
        path.lineTo(right - r, top);
        path.quadraticBezierTo(right, top, right, top + r);
        path.lineTo(right, bottom - fold);
        path.lineTo(right - fold, bottom);
        path.lineTo(left + r, bottom);
        path.quadraticBezierTo(left, bottom, left, bottom - r);
        path.lineTo(left, top + r);
        path.quadraticBezierTo(left, top, left + r, top);
        path.close();
        break;

      case NoteShapeType.paper:
        final r = math.min(14.0, minSide * 0.12);
        final waveHeight = math.min(8.0, h * 0.045);
        const waves = 6;
        final waveW = w / waves;
        path.moveTo(left + r, top);
        path.lineTo(right - r, top);
        path.quadraticBezierTo(right, top, right, top + r);
        path.lineTo(right, bottom - waveHeight);
        for (int i = 0; i < waves; i++) {
          final sx = right - i * waveW;
          final ex = right - (i + 1) * waveW;
          final mx = (sx + ex) / 2;
          final ctrlY = (i.isEven) ? bottom + waveHeight : bottom - waveHeight * 2;
          path.quadraticBezierTo(mx, ctrlY, ex, bottom - waveHeight);
        }
        path.lineTo(left, top + r);
        path.quadraticBezierTo(left, top, left + r, top);
        path.close();
        break;

      case NoteShapeType.leaf:
        final bigR = math.min(w, h) * 0.48;
        final smallR = math.min(14.0, minSide * 0.10);
        path.addRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, top, w, h),
            topLeft: Radius.circular(smallR),
            topRight: Radius.circular(bigR),
            bottomRight: Radius.circular(smallR),
            bottomLeft: Radius.circular(bigR),
          ),
        );
        break;

      case NoteShapeType.circle:
        path.addOval(Rect.fromLTWH(left, top, w, h));
        break;

      case NoteShapeType.diamond:
        path.moveTo(cx, top);
        path.lineTo(right, cy);
        path.lineTo(cx, bottom);
        path.lineTo(left, cy);
        path.close();
        break;

      case NoteShapeType.hexagon:
        final dx = w * 0.22;
        path.moveTo(left + dx, top);
        path.lineTo(right - dx, top);
        path.lineTo(right, cy);
        path.lineTo(right - dx, bottom);
        path.lineTo(left + dx, bottom);
        path.lineTo(left, cy);
        path.close();
        break;

      case NoteShapeType.octagon:
        final cutX = w * 0.27;
        final cutY = h * 0.27;
        path.moveTo(left + cutX, top);
        path.lineTo(right - cutX, top);
        path.lineTo(right, top + cutY);
        path.lineTo(right, bottom - cutY);
        path.lineTo(right - cutX, bottom);
        path.lineTo(left + cutX, bottom);
        path.lineTo(left, bottom - cutY);
        path.lineTo(left, top + cutY);
        path.close();
        break;

      case NoteShapeType.shield:
        final r = math.min(16.0, minSide * 0.12);
        path.moveTo(left + r, top);
        path.lineTo(right - r, top);
        path.quadraticBezierTo(right, top, right, top + r);
        path.lineTo(right, top + h * 0.48);
        path.quadraticBezierTo(
          right,
          top + h * 0.80,
          cx,
          bottom,
        );
        path.quadraticBezierTo(
          left,
          top + h * 0.80,
          left,
          top + h * 0.48,
        );
        path.lineTo(left, top + r);
        path.quadraticBezierTo(left, top, left + r, top);
        path.close();
        break;

      case NoteShapeType.tag:
        final cut = math.min(28.0, minSide * 0.20);
        path.moveTo(left + cut, top);
        path.lineTo(right - cut, top);
        path.lineTo(right, top + cut);
        path.lineTo(right, bottom - cut);
        path.lineTo(right - cut, bottom);
        path.lineTo(left, bottom);
        path.lineTo(left, top + cut);
        path.close();
        break;
    }

    return path;
  }

  /// Devuelve el doblez de la esquina si la forma es `NoteShapeType.note`
  static Path? buildNoteFoldOverlayPath(NoteShapeType shape, Size size) {
    if (shape != NoteShapeType.note) return null;
    final minSide = math.min(size.width, size.height);
    final fold = math.min(34.0, minSide * 0.24);
    return Path()
      ..moveTo(size.width, size.height - fold)
      ..lineTo(size.width - fold, size.height)
      ..lineTo(size.width - fold, size.height - fold)
      ..close();
  }
}
