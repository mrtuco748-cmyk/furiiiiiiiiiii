import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/note_style_config.dart';
import 'note_shape_path_builder.dart';

/// Utilidades geométricas para las 11 formas de tarjeta del Pizarrón:
/// - Delegación de construcción de `Path` exacto a [NoteShapePathBuilder]
/// - Cálculo de padding inscrito para que el texto se centre y encaje en rombos, círculos, etc.
/// - Posicionamiento matemático del agarre de redimensionamiento (esquina inferior derecha)
///   sobre el perímetro real de cada forma para que nunca quede flotando en el aire.
class NoteShapeUtils {
  static Path buildShapePath(
    NoteShapeType shape,
    Size size, {
    double inset = 0.0,
  }) {
    return NoteShapePathBuilder.buildShapePath(shape, size, inset: inset);
  }

  /// Devuelve el doblez de la esquina si la forma es `NoteShapeType.note`
  static Path? buildNoteFoldOverlayPath(NoteShapeType shape, Size size) {
    return NoteShapePathBuilder.buildNoteFoldOverlayPath(shape, size);
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
        return Offset(w - fold * 0.52, h - fold * 0.52);

      case NoteShapeType.paper:
        return Offset(w - 12, h - 14);

      case NoteShapeType.leaf:
        return Offset(w - 14, h - 14);

      case NoteShapeType.circle:
        const angle = math.pi / 4;
        final rx = w / 2;
        final ry = h / 2;
        return Offset(
          rx + (rx - 6) * math.cos(angle),
          ry + (ry - 6) * math.sin(angle),
        );

      case NoteShapeType.diamond:
        const t = 0.45;
        final x = w * (1.0 - 0.5 * t);
        final y = h * (0.5 + 0.5 * t);
        return Offset(x - 4, y - 4);

      case NoteShapeType.hexagon:
        const t = 0.55;
        final x = w * (1.0 - 0.22 * t);
        final y = h * (0.5 + 0.5 * t);
        return Offset(x - 4, y - 4);

      case NoteShapeType.octagon:
        final cutX = w * 0.27;
        final cutY = h * 0.27;
        return Offset(w - cutX * 0.5 - 3, h - cutY * 0.5 - 3);

      case NoteShapeType.shield:
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
