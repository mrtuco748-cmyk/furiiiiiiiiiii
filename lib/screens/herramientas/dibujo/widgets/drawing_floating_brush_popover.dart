import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../models/drawing_point.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_tool_type.dart';
import '../painters/stroke_renderer.dart';
import 'drawing_predictive_stroke_card.dart';

/// Popover flotante con la Biblioteca de Pinceles profesionales de Infinite Painter:
/// Birome, Pluma G Manga, Lápiz grafito, Marcador, Aerógrafo y Resaltador,
/// con previsualización en vivo, sliders de grosor y opacidad, y chips rápidos.
class DrawingFloatingBrushPopover extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback onClose;

  const DrawingFloatingBrushPopover({
    super.key,
    required this.controller,
    required this.onClose,
  });

  static const List<(DrawingToolType, String, String)> brushes = [
    (DrawingToolType.pen, 'Birome', 'Trazos continuos y fluidos'),
    (DrawingToolType.gPen, 'Pluma G Manga', 'Sensibilidad y afinamiento mangaka'),
    (DrawingToolType.pencil, 'Lápiz Grafito', 'Textura analógica para bocetos'),
    (DrawingToolType.marker, 'Marcador Tinta', 'Tinta densa con bordes nítidos'),
    (DrawingToolType.airbrush, 'Aerógrafo', 'Gradiente radial y aspersión suave'),
    (DrawingToolType.highlighter, 'Resaltador', 'Capa translúcida multiplicada'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final currentTool = controller.selectedTool;

        return Container(
          width: 320,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  children: [
                    const Icon(Icons.brush, color: Color(0xFF00D4FF), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pinceles',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Colors.white54, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lista de Pinceles
                ...brushes.map((b) {
                  final tool = b.$1;
                  final name = b.$2;
                  final desc = b.$3;
                  final isSelected = currentTool == tool;

                  return GestureDetector(
                    onTap: () => controller.selectTool(tool),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(tool.icon, size: 18, color: isSelected ? Colors.black : Colors.white70),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black87 : Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Previsualización de curva del trazo
                          SizedBox(
                            width: 50,
                            height: 24,
                            child: CustomPaint(
                              painter: _MiniBrushStrokePainter(
                                tool: tool,
                                color: isSelected ? Colors.black : controller.selectedColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // Preajustes rápidos de grosor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tamaño rápido:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text('${controller.strokeWidth.toInt()} px',
                        style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [2.0, 5.0, 10.0, 20.0, 35.0, 50.0].map((w) {
                    final isSel = (controller.strokeWidth - w).abs() < 1.5;
                    return GestureDetector(
                      onTap: () => controller.setStrokeWidth(w),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFDE59) : const Color(0xFF282828),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${w.toInt()}',
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Slider de Grosor
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00D4FF),
                    inactiveTrackColor: const Color(0xFF2E2E2E),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: controller.strokeWidth.clamp(1.0, 80.0),
                    min: 1.0,
                    max: 80.0,
                    onChanged: (val) => controller.setStrokeWidth(val),
                  ),
                ),

                // Slider de Opacidad
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Opacidad:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text('${(controller.strokeOpacity * 100).toInt()}%',
                        style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFF6B00),
                    inactiveTrackColor: const Color(0xFF2E2E2E),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: controller.strokeOpacity.clamp(0.05, 1.0),
                    min: 0.05,
                    max: 1.0,
                    onChanged: (val) => controller.setStrokeOpacity(val),
                  ),
                ),
                const SizedBox(height: 8),
                DrawingPredictiveStrokeCard(controller: controller, compact: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Painter para trazar una pequeña curva S de muestra que refleja el estilo del pincel.
class _MiniBrushStrokePainter extends CustomPainter {
  final DrawingToolType tool;
  final Color color;

  const _MiniBrushStrokePainter({required this.tool, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final points = <DrawingPoint>[
      DrawingPoint(offset: Offset(4, size.height * 0.75), pressure: 0.3),
      DrawingPoint(offset: Offset(size.width * 0.35, size.height * 0.25), pressure: 0.8),
      DrawingPoint(offset: Offset(size.width * 0.65, size.height * 0.8), pressure: 1.0),
      DrawingPoint(offset: Offset(size.width - 4, size.height * 0.3), pressure: 0.4),
    ];
    final stroke = DrawingStroke(
      id: 'preview',
      points: points,
      color: color,
      strokeWidth: 3.5,
      opacity: 0.95,
      tool: tool,
    );
    StrokeRenderer.renderStroke(canvas, stroke);
  }

  @override
  bool shouldRepaint(covariant _MiniBrushStrokePainter oldDelegate) =>
      oldDelegate.tool != tool || oldDelegate.color != color;
}
