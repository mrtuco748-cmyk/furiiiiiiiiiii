import 'package:flutter/material.dart';
import '../models/comic_template.dart';
import '../painters/comic_panel_shape_helper.dart';

/// Barra flotante no invasiva para seleccionar plantillas dinámicas y divertidas con 1-tap.
class ComicFloatingTemplateBar extends StatelessWidget {
  final ValueChanged<ComicTemplateType> onSelect;
  final VoidCallback onClose;

  const ComicFloatingTemplateBar({
    super.key,
    required this.onSelect,
    required this.onClose,
  });

  Widget _buildMiniTemplate(ComicTemplateType type) {
    return Tooltip(
      message: type.displayName,
      child: GestureDetector(
        onTap: () => onSelect(type),
        child: Container(
          width: 38,
          height: 48,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _MiniPainter(type),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ComicTemplateType.values.map(_buildMiniTemplate).toList(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  final ComicTemplateType template;
  _MiniPainter(this.template);

  @override
  void paint(Canvas canvas, Size size) {
    final panels = template.createPanels();
    final fill = Paint()..color = const Color(0xFF444444);
    final border = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final p in panels) {
      final r = Rect.fromLTWH(
        p.normalizedRect.left * size.width,
        p.normalizedRect.top * size.height,
        p.normalizedRect.width * size.width,
        p.normalizedRect.height * size.height,
      );
      final path = ComicPanelShapeHelper.getPanelPath(r, p);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, border);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) => old.template != template;
}
