import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/note_style_config.dart';

/// Utilidades geométricas para las 11 formas de tarjeta del Pizarrón:
/// - Construcción de `Path` exacto
/// - Cálculo de padding inscrito para que el texto se centre y encaje en rombos, círculos, etc.
/// - Posicionamiento matemático del agarre de redimensionamiento (esquina inferior derecha)
///   sobre el perímetro real de cada forma para que nunca quede flotando en el aire.
class NoteShapeUtils {
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
        // Nota con esquina inferior derecha doblada y esquinas suaves
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
        // Hoja de papel con borde superior redondeado e inferior con ondas suaves
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
        // Forma de hoja orgánica: esquina sup-izq e inf-der en punta suave,
        // esquina sup-der e inf-izq con gran curvatura orgánica
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
    final path = Path()
      ..moveTo(size.width, size.height - fold)
      ..lineTo(size.width - fold, size.height)
      ..lineTo(size.width - fold, size.height - fold)
      ..close();
    return path;
  }

  /// Calcula el padding interno inscrito según la forma para que el título,
  /// texto e imágenes nunca se salgan del borde en rombos, círculos, octágonos, hojas, etc.
  static EdgeInsets getContentPadding(NoteShapeType shape, Size size) {
    final w = size.width;
    final h = size.height;

    switch (shape) {
      case NoteShapeType.square:
        return const EdgeInsets.fromLTRB(16, 16, 16, 20);
      case NoteShapeType.rounded:
        return const EdgeInsets.fromLTRB(18, 16, 18, 22);
      case NoteShapeType.note:
        return const EdgeInsets.fromLTRB(18, 16, 22, 28);
      case NoteShapeType.paper:
        return const EdgeInsets.fromLTRB(18, 16, 18, 26);
      case NoteShapeType.leaf:
        return EdgeInsets.fromLTRB(
          math.max(20.0, w * 0.11),
          math.max(18.0, h * 0.10),
          math.max(20.0, w * 0.11),
          math.max(22.0, h * 0.11),
        );
      case NoteShapeType.circle:
        return EdgeInsets.symmetric(
          horizontal: math.max(20.0, w * 0.155),
          vertical: math.max(18.0, h * 0.155),
        );
      case NoteShapeType.diamond:
        return EdgeInsets.symmetric(
          horizontal: math.max(24.0, w * 0.235),
          vertical: math.max(22.0, h * 0.225),
        );
      case NoteShapeType.hexagon:
        return EdgeInsets.symmetric(
          horizontal: math.max(22.0, w * 0.15),
          vertical: math.max(18.0, h * 0.12),
        );
      case NoteShapeType.octagon:
        return EdgeInsets.symmetric(
          horizontal: math.max(22.0, w * 0.145),
          vertical: math.max(18.0, h * 0.145),
        );
      case NoteShapeType.shield:
        return EdgeInsets.fromLTRB(
          math.max(18.0, w * 0.12),
          math.max(16.0, h * 0.08),
          math.max(18.0, w * 0.12),
          math.max(28.0, h * 0.21),
        );
      case NoteShapeType.tag:
        return const EdgeInsets.fromLTRB(20, 18, 20, 22);
    }
  }

  /// Calcula la coordenada exacta (x, y) sobre la esquina/borde inferior-derecho
  /// de cada forma donde se debe ubicar el agarre para redimensionar la nota.
  static Offset getResizeHandleCenter(NoteShapeType shape, Size size) {
    final w = size.width;
    final h = size.height;
    final minSide = math.min(w, h);

    switch (shape) {
      case NoteShapeType.square:
        return Offset(w - 10, h - 10);

      case NoteShapeType.rounded:
        final r = math.min(24.0, minSide * 0.22);
        const angle = math.pi / 4; // 45 grados en el arco inferior-derecho
        return Offset(
          (w - r) + (r - 5) * math.cos(angle),
          (h - r) + (r - 5) * math.sin(angle),
        );

      case NoteShapeType.note:
        final fold = math.min(34.0, minSide * 0.24);
        // Punto medio exacto sobre el pliegue diagonal inferior derecho
        return Offset(w - fold * 0.52, h - fold * 0.52);

      case NoteShapeType.paper:
        return Offset(w - 12, h - 14);

      case NoteShapeType.leaf:
        // En la hoja, la esquina inferior derecha es la punta orgánica
        return Offset(w - 14, h - 14);

      case NoteShapeType.circle:
        // Punto a 45° exactos sobre el perímetro de la elipse
        const angle = math.pi / 4;
        final rx = w / 2;
        final ry = h / 2;
        return Offset(
          rx + (rx - 6) * math.cos(angle),
          ry + (ry - 6) * math.sin(angle),
        );

      case NoteShapeType.diamond:
        // En el borde diagonal inferior-derecho entre (w, h/2) y (w/2, h)
        // t = 0.45 ubica el agarre cómodamente sobre la arista inferior-derecha
        const t = 0.45;
        final x = w * (1.0 - 0.5 * t);
        final y = h * (0.5 + 0.5 * t);
        return Offset(x - 4, y - 4);

      case NoteShapeType.hexagon:
        // Arista inferior-derecha entre (w, h*0.5) y (w*0.78, h)
        const t = 0.55;
        final x = w * (1.0 - 0.22 * t);
        final y = h * (0.5 + 0.5 * t);
        return Offset(x - 4, y - 4);

      case NoteShapeType.octagon:
        // Chaflán inferior-derecho entre (w, h*0.73) y (w*0.73, h)
        final cutX = w * 0.27;
        final cutY = h * 0.27;
        return Offset(w - cutX * 0.5 - 3, h - cutY * 0.5 - 3);

      case NoteShapeType.shield:
        // Curva cuadrática inferior-derecha desde (w, 0.48h), ctrl (w, 0.80h), hasta (0.5w, h)
        const t = 0.45;
        const invT = 1.0 - t;
        final p0 = Offset(w, h * 0.48);
        final p1 = Offset(w, h * 0.80);
        final p2 = Offset(w * 0.5, h);
        final bx = invT * invT * p0.dx + 2 * invT * t * p1.dx + t * t * p2.dx;
        final by = invT * invT * p0.dy + 2 * invT * t * p1.dy + t * t * p2.dy;
        return Offset(bx - 4, by - 4);

      case NoteShapeType.tag:
        final cut = math.min(28.0, minSide * 0.20);
        return Offset(w - cut * 0.5 - 2, h - cut * 0.5 - 2);
    }
  }
}

/// Clipper reutilizable para recortar cualquier widget hijo a la forma exacta de la nota.
class NoteShapeClipper extends CustomClipper<Path> {
  final NoteShapeType shape;
  final double inset;

  const NoteShapeClipper(this.shape, {this.inset = 0.0});

  @override
  Path getClip(Size size) {
    return NoteShapeUtils.buildShapePath(shape, size, inset: inset);
  }

  @override
  bool shouldReclip(covariant NoteShapeClipper oldClipper) {
    return oldClipper.shape != shape || oldClipper.inset != inset;
  }
}
