import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/note_style_config.dart';
import 'note_border_painter.dart';
import 'note_pattern_painter.dart';
import 'note_shape_utils.dart';

/// CustomPainter multicapa que dibuja la tarjeta del Pizarrón:
/// 1. Capa Base: Color sólido o Degradado de 3 partes (inicial, medio, final)
/// 2. Capa de Patrones: Ajedrez, Líneas oblicuas/horizontales/verticales, Ondas,
///    Círculos rellenos/vacíos, Puntos, Cuadrícula, o Emojis/Texto en patrón
/// 3. Capa de Brillo animado (opcional)
/// 4. Capa de Borde adaptativo que sigue el `Path` exacto de cualquiera de las 11 formas
///    (Sólido, Punteado, Rayas, Doble línea, Ondulado)
class NoteCardPainter extends CustomPainter {
  final NoteStyleConfig config;
  final double shineProgress;
  final bool isEditing;

  NoteCardPainter({
    required this.config,
    this.shineProgress = 0.0,
    this.isEditing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final shapePath = NoteShapeUtils.buildShapePath(config.shapeType, size);

    // 1. Recortar todo el interior a la forma exacta de la tarjeta
    canvas.save();
    canvas.clipPath(shapePath);

    // --- CAPA 1: FONDO BASE ---
    _paintBaseLayer(canvas, rect);

    // --- CAPA 2: PATRÓN ---
    if (config.patternType != NotePatternType.none &&
        config.patternOpacity > 0.01) {
      NotePatternPainter.paintPattern(canvas, size, rect, config);
    }

    // --- PLIEGUE DE ESQUINA (para forma 'note') ---
    final foldPath =
        NoteShapeUtils.buildNoteFoldOverlayPath(config.shapeType, size);
    if (foldPath != null) {
      final foldPaint = Paint()
        ..color = const Color(0x38FFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawPath(foldPath, foldPaint);
    }

    // --- CAPA 3: EFECTO BRILLO ANIMADO OPCIONAL ---
    if (config.hasShine) {
      _paintShineLayer(canvas, size);
    }

    canvas.restore();

    // --- CAPA 4: BORDES ADAPTADOS A LA FORMA ---
    if (config.borderType != NoteBorderType.none && config.borderWidth > 0) {
      NoteBorderPainter.paintBorder(canvas, size, config);
    }
  }

  void _paintBaseLayer(Canvas canvas, Rect rect) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (config.baseMode == 'gradient') {
      final c1 = PizarronPalette.parseHex(config.gradientStartColor);
      final c2 = PizarronPalette.parseHex(config.gradientMidColor);
      final c3 = PizarronPalette.parseHex(config.gradientEndColor);
      final rad = config.gradientAngle * math.pi / 180.0;
      final begin = Alignment(-math.cos(rad), -math.sin(rad));
      final end = Alignment(math.cos(rad), math.sin(rad));

      paint.shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [c1, c2, c3],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    } else {
      paint.color = PizarronPalette.parseHex(config.solidColor);
    }

    canvas.drawRect(rect, paint);
  }

  void _paintShineLayer(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pos = (shineProgress * 2.2) - 0.6;
    final rect = Offset.zero & size;

    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(pos - 0.45, -1.0),
        end: Alignment(pos + 0.45, 1.0),
        colors: [
          const Color(0x00FFFFFF),
          const Color(0x2EFFFFFF),
          const Color(0x00FFFFFF),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), shinePaint);
  }

  @override
  bool shouldRepaint(covariant NoteCardPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.shineProgress != shineProgress ||
        oldDelegate.isEditing != isEditing;
  }
}
