import 'package:flutter/material.dart';
import '../models/note_style_config.dart';

/// Envoltorio decorativo para bloques de texto en tarjetas de notas:
/// - `escuadra`: marco en L derecha e inferior
/// - `escuadraLeft`: marco en L izquierda e inferior
/// - `thickUnderline`: subrayado grueso redondeado
/// - `topBottomLines`: bordes de línea superior e inferior
/// - `sunken`: fondo oscuro hundido con sombreado interno
/// - `quoteBar`: barra lateral izquierda gruesa con fondo tenue
/// - `framed`: marco perimetral completo
class PizarronFormattedBlockContainer extends StatelessWidget {
  final TextBlockFormat format;
  final Color accentColor;
  final bool isHighlightedTarget;
  final Widget child;

  const PizarronFormattedBlockContainer({
    super.key,
    required this.format,
    required this.accentColor,
    required this.isHighlightedTarget,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    switch (format) {
      case TextBlockFormat.none:
        break;

      case TextBlockFormat.escuadra:
        content = CustomPaint(
          painter: PizarronEscuadraPainter(
            color: accentColor.withValues(alpha: 0.88),
            rightSide: true,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 10, 7),
            child: content,
          ),
        );
        break;

      case TextBlockFormat.escuadraLeft:
        content = CustomPaint(
          painter: PizarronEscuadraPainter(
            color: accentColor.withValues(alpha: 0.88),
            rightSide: false,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 4, 7),
            child: content,
          ),
        );
        break;

      case TextBlockFormat.thickUnderline:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            const SizedBox(height: 3),
            Container(
              height: 4.5,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
        break;

      case TextBlockFormat.topBottomLines:
        content = Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: accentColor.withValues(alpha: 0.75),
                width: 2.2,
              ),
              bottom: BorderSide(
                color: accentColor.withValues(alpha: 0.75),
                width: 2.2,
              ),
            ),
          ),
          child: content,
        );
        break;

      case TextBlockFormat.sunken:
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x660B0E14),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55080A0F),
                offset: Offset(0, 2),
                blurRadius: 3,
                spreadRadius: -1,
              ),
            ],
            border: const Border(
              top: BorderSide(color: Color(0x66080A0F), width: 2.0),
              left: BorderSide(color: Color(0x55080A0F), width: 1.5),
              bottom: BorderSide(color: Color(0x28FFFFFF), width: 1.0),
              right: BorderSide(color: Color(0x18FFFFFF), width: 1.0),
            ),
          ),
          child: content,
        );
        break;

      case TextBlockFormat.quoteBar:
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(
              left: BorderSide(
                color: accentColor.withValues(alpha: 0.90),
                width: 4.0,
              ),
            ),
          ),
          child: content,
        );
        break;

      case TextBlockFormat.framed:
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.75),
              width: 2.0,
            ),
          ),
          child: content,
        );
        break;
    }

    return content;
  }
}

class PizarronEscuadraPainter extends CustomPainter {
  final Color color;
  final bool rightSide;

  PizarronEscuadraPainter({
    required this.color,
    required this.rightSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (rightSide) {
      path.moveTo(size.width - 2, 2);
      path.lineTo(size.width - 2, size.height - 2);
      path.lineTo(2, size.height - 2);
    } else {
      path.moveTo(2, 2);
      path.lineTo(2, size.height - 2);
      path.lineTo(size.width - 2, size.height - 2);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PizarronEscuadraPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.rightSide != rightSide;
  }
}
