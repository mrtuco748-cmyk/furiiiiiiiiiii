import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/comic_bubble.dart';
import '../models/comic_page.dart';
import '../models/comic_panel.dart';
import '../models/comic_sticker.dart';
import 'comic_bubble_painter.dart';
import 'comic_panel_shape_helper.dart';

/// Painter de la página completa de cómic/manga con viñetas recortadas a sus formas vectoriales,
/// dibujos incrustados, onomatopeyas estilizadas y globos de diálogo rotables.
class ComicPagePainter extends CustomPainter {
  final ComicPage page;
  final Map<String, ui.Image> panelImages;
  final String? selectedPanelId;
  final String? selectedBubbleId;
  final String? selectedSfxId;

  ComicPagePainter({
    required this.page,
    this.panelImages = const {},
    this.selectedPanelId,
    this.selectedBubbleId,
    this.selectedSfxId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo de la hoja
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = page.backgroundColor,
    );

    // 2. Dibujar Paneles / Viñetas con geometría dinámica
    for (final panel in page.panels) {
      _paintPanel(canvas, size, panel);
    }

    // 3. Dibujar Onomatopeyas / SFX
    for (final sfx in page.sfxStickers) {
      _paintSfx(canvas, size, sfx);
    }

    // 4. Dibujar Burbujas de Diálogo
    for (final bubble in page.bubbles) {
      _paintBubble(canvas, size, bubble);
    }
  }

  void _paintPanel(Canvas canvas, Size size, ComicPanel panel) {
    final rect = Rect.fromLTWH(
      panel.normalizedRect.left * size.width,
      panel.normalizedRect.top * size.height,
      panel.normalizedRect.width * size.width,
      panel.normalizedRect.height * size.height,
    );

    final path = ComicPanelShapeHelper.getPanelPath(rect, panel);

    // Fondo del panel
    canvas.drawPath(path, Paint()..color = panel.backgroundColor);

    // Dibujo incrustado con recorte exacto a la silueta de la viñeta
    final img = panelImages[panel.id];
    if (img != null) {
      canvas.save();
      canvas.clipPath(path);

      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dstCenter = rect.center + Offset(panel.offsetX, panel.offsetY);
      final dstW = rect.width * panel.scale;
      final dstH = rect.height * panel.scale;
      final dst = Rect.fromCenter(center: dstCenter, width: dstW, height: dstH);

      if (panel.rotation != 0.0) {
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.rotate(panel.rotation);
        canvas.translate(-rect.center.dx, -rect.center.dy);
      }

      canvas.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
    }

    // Borde real de la viñeta (siempre visible con su color y grosor real)
    final borderPaint = Paint()
      ..color = panel.borderColor
      ..strokeWidth = panel.borderWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, borderPaint);

    // Halo exterior tenue azul cian indicador de selección sin tapar el color del marco
    final isSelected = selectedPanelId == panel.id;
    if (isSelected) {
      final haloPaint = Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.35)
        ..strokeWidth = panel.borderWidth + 4.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, haloPaint);
    }
  }

  void _paintSfx(Canvas canvas, Size size, ComicSticker sfx) {
    final x = sfx.x * size.width;
    final y = sfx.y * size.height;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(sfx.rotation);
    canvas.scale(sfx.scale);

    final shadows = _buildSfxShadows(sfx.sfxStyle, sfx.outlineColor, sfx.color);
    final textStyle = _getFontStyle(sfx.fontFamily, sfx.fontSize, sfx.color).copyWith(
      shadows: shadows,
      letterSpacing: 1.0,
    );

    final textSpan = TextSpan(text: sfx.text, style: textStyle);
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    if (selectedSfxId == sfx.id) {
      final selectPaint = Paint()
        ..color = const Color(0xFF00D4FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(Rect.fromLTWH(-tp.width / 2 - 4, -tp.height / 2 - 4, tp.width + 8, tp.height + 8), selectPaint);
    }

    canvas.restore();
  }

  List<Shadow> _buildSfxShadows(ComicSfxStyle style, Color outline, Color fill) {
    switch (style) {
      case ComicSfxStyle.standard:
        return [
          Shadow(color: outline, offset: const Offset(-2, -2), blurRadius: 0),
          Shadow(color: outline, offset: const Offset(2, -2), blurRadius: 0),
          Shadow(color: outline, offset: const Offset(-2, 2), blurRadius: 0),
          Shadow(color: outline, offset: const Offset(2, 2), blurRadius: 0),
        ];
      case ComicSfxStyle.extruded3D:
        return [
          Shadow(color: outline, offset: const Offset(2, 2), blurRadius: 0),
          Shadow(color: outline, offset: const Offset(4, 4), blurRadius: 0),
          Shadow(color: outline, offset: const Offset(6, 6), blurRadius: 0),
        ];
      case ComicSfxStyle.neonGlow:
        return [
          Shadow(color: fill.withValues(alpha: 0.9), offset: Offset.zero, blurRadius: 10),
          Shadow(color: outline, offset: const Offset(-1, -1), blurRadius: 1),
          Shadow(color: outline, offset: const Offset(1, 1), blurRadius: 1),
        ];
      case ComicSfxStyle.speedLines:
        return [
          Shadow(color: outline, offset: const Offset(-4, 0), blurRadius: 0),
          Shadow(color: outline, offset: const Offset(-8, 0), blurRadius: 0),
          Shadow(color: outline, offset: const Offset(2, 0), blurRadius: 0),
        ];
      case ComicSfxStyle.screentoneDots:
        return [
          Shadow(color: outline.withValues(alpha: 0.5), offset: const Offset(3, 3), blurRadius: 2),
          Shadow(color: outline, offset: const Offset(-1, -1), blurRadius: 0),
        ];
    }
  }

  void _paintBubble(Canvas canvas, Size size, ComicBubble bubble) {
    final cx = bubble.x * size.width;
    final cy = bubble.y * size.height;

    canvas.save();
    canvas.translate(cx, cy);
    if (bubble.rotation != 0.0) {
      canvas.rotate(bubble.rotation);
    }
    canvas.translate(-bubble.width / 2, -bubble.height / 2);

    // Pintar la silueta y cola
    ComicBubblePainter.paintBubble(canvas, Size(bubble.width, bubble.height), bubble);

    // Pintar el texto del diálogo centrado
    final textStyle = _getFontStyle(bubble.fontFamily, bubble.fontSize, bubble.textColor);
    final textSpan = TextSpan(text: bubble.text, style: textStyle);
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(10.0, bubble.width - 24));

    final textOffset = Offset(
      (bubble.width - tp.width) / 2,
      (bubble.height - tp.height) / 2,
    );
    tp.paint(canvas, textOffset);

    canvas.restore();
  }

  TextStyle _getFontStyle(String family, double size, Color color) {
    switch (family) {
      case 'Bangers':
        return GoogleFonts.bangers(fontSize: size, color: color, height: 1.1);
      case 'Permanent Marker':
        return GoogleFonts.permanentMarker(fontSize: size, color: color, height: 1.1);
      case 'Press Start 2P':
        return GoogleFonts.pressStart2p(fontSize: size * 0.75, color: color, height: 1.2);
      case 'Patrick Hand':
        return GoogleFonts.patrickHand(fontSize: size * 1.15, color: color, height: 1.1);
      case 'Caveat':
        return GoogleFonts.caveat(fontSize: size * 1.25, color: color, height: 1.1);
      case 'Russo One':
        return GoogleFonts.russoOne(fontSize: size, color: color, height: 1.1);
      case 'Bungee':
        return GoogleFonts.bungee(fontSize: size * 0.85, color: color, height: 1.1);
      case 'Oswald':
        return GoogleFonts.oswald(fontSize: size, color: color, fontWeight: FontWeight.bold, height: 1.1);
      default:
        return GoogleFonts.comicNeue(fontSize: size, color: color, fontWeight: FontWeight.bold, height: 1.15);
    }
  }

  @override
  bool shouldRepaint(covariant ComicPagePainter oldDelegate) => true;
}
