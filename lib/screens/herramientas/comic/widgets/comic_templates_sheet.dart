import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/comic_template.dart';

/// Modal para seleccionar la distribución y estructura de viñetas de la página.
class ComicTemplatesSheet extends StatelessWidget {
  final ValueChanged<ComicTemplateType> onSelect;

  const ComicTemplatesSheet({super.key, required this.onSelect});

  Widget _buildTemplateCard(BuildContext context, ComicTemplateType template) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        onSelect(template);
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: CustomPaint(
                  painter: _TemplateMiniPainter(template),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              template.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              template.description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize_outlined, color: Color(0xFF00D4FF), size: 24),
              const SizedBox(width: 10),
              Text(
                'PLANTILLAS DE PÁGINA',
                style: GoogleFonts.bangers(fontSize: 22, color: Colors.white, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Elige la estructura de viñetas para tu página de manga o cómic:',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: ComicTemplateType.values.map((t) => _buildTemplateCard(context, t)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateMiniPainter extends CustomPainter {
  final ComicTemplateType template;
  _TemplateMiniPainter(this.template);

  @override
  void paint(Canvas canvas, Size size) {
    final panels = template.createPanels();
    final fillPaint = Paint()..color = const Color(0xFF333333);
    final borderPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final panel in panels) {
      final r = Rect.fromLTWH(
        panel.normalizedRect.left * size.width,
        panel.normalizedRect.top * size.height,
        panel.normalizedRect.width * size.width,
        panel.normalizedRect.height * size.height,
      );
      canvas.drawRect(r, fillPaint);
      canvas.drawRect(r, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TemplateMiniPainter old) => old.template != template;
}
