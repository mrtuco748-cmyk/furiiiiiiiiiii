import 'dart:convert';
import 'package:flutter/material.dart';
import '../../dibujo/models/drawing_project.dart';
import '../../dibujo/painters/stroke_renderer.dart';

/// Renderizador reactivo de miniaturas para proyectos de dibujo.
/// Si existe un thumbnailBase64 lo decodifica sobre fondo blanco de lienzo;
/// si es nulo, renderiza vectorialmente los trazos sobre una hoja de papel blanca.
class ComicDrawingThumbnail extends StatelessWidget {
  final DrawingProject project;

  const ComicDrawingThumbnail({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (project.thumbnailBase64 != null && project.thumbnailBase64!.isNotEmpty) {
      try {
        return Container(
          color: Colors.white,
          child: Image.memory(
            base64Decode(project.thumbnailBase64!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildVectorPreview(),
          ),
        );
      } catch (_) {
        return _buildVectorPreview();
      }
    }
    return _buildVectorPreview();
  }

  Widget _buildVectorPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.white,
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _MiniProjectPainter(project: project),
          ),
        );
      },
    );
  }
}

class _MiniProjectPainter extends CustomPainter {
  final DrawingProject project;

  _MiniProjectPainter({required this.project});

  @override
  void paint(Canvas canvas, Size size) {
    final origW = project.canvasWidth > 0 ? project.canvasWidth : 1080.0;
    final origH = project.canvasHeight > 0 ? project.canvasHeight : 1080.0;

    // Pintar fondo blanco de papel para el lienzo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final scaleX = size.width / origW;
    final scaleY = size.height / origH;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.save();
    canvas.scale(scale, scale);

    for (final layer in project.layers) {
      if (!layer.isVisible) continue;
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, origW, origH),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: layer.opacity),
      );
      for (final stroke in layer.strokes) {
        StrokeRenderer.renderStroke(canvas, stroke);
      }
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniProjectPainter oldDelegate) =>
      oldDelegate.project != project;
}
