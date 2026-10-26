import 'package:flutter/material.dart';
import '../../comic/models/comic_panel.dart';
import '../../comic/painters/comic_panel_shape_helper.dart';

/// Pintor de guías de recorte y máscara para cuando se dibuja dentro de una viñeta de cómic.
/// Muestra un sombreado exterior sutil y el contorno cyan punteado del panel.
class DrawingPanelGuidePainter extends CustomPainter {
  final ComicPanelShape? shape;
  final List<Offset>? polygonPoints;
  final double borderRadius;
  final bool visible;

  const DrawingPanelGuidePainter({
    this.shape,
    this.polygonPoints,
    this.borderRadius = 0.0,
    this.visible = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible || (shape == null && (polygonPoints == null || polygonPoints!.isEmpty))) {
      return;
    }

    final dummyPanel = ComicPanel(
      id: 'guide_preview',
      normalizedRect: const Rect.fromLTWH(0, 0, 1, 1),
      panelShape: shape ?? ComicPanelShape.rectangle,
      polygonPoints: polygonPoints,
      borderRadius: borderRadius,
    );

    final rect = Offset.zero & size;
    final panelPath = ComicPanelShapeHelper.getPanelPath(rect, dummyPanel);

    // 1. Máscara oscura para el área fuera de la viñeta (lo que será recortado)
    final outerPath = Path()..addRect(rect);
    final cutoutMask = Path.combine(PathOperation.difference, outerPath, panelPath);

    canvas.drawPath(
      cutoutMask,
      Paint()
        ..color = const Color(0x66000000)
        ..style = PaintingStyle.fill,
    );

    // 2. Línea guía cyan perimetral de la viñeta
    final guideBorderPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(panelPath, guideBorderPaint);
  }

  @override
  bool shouldRepaint(covariant DrawingPanelGuidePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.polygonPoints != polygonPoints ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.visible != visible;
}
