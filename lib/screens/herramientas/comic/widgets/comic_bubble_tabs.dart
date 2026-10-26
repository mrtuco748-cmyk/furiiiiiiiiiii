import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/comic_bubble.dart';

/// Pestaña de Forma y Texto para ComicFloatingBubbleBar.
class ComicBubbleShapeAndTextTab extends StatelessWidget {
  final ComicBubbleType selectedType;
  final ComicTailDirection selectedTailDirection;
  final TextEditingController textController;
  final ValueChanged<ComicBubbleType> onTypeChanged;
  final ValueChanged<ComicTailDirection> onTailChanged;
  final VoidCallback onTextSubmitted;

  const ComicBubbleShapeAndTextTab({
    super.key,
    required this.selectedType,
    required this.selectedTailDirection,
    required this.textController,
    required this.onTypeChanged,
    required this.onTailChanged,
    required this.onTextSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector horizontal de formas de globo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ComicBubbleType.values.map((t) {
              final isSel = selectedType == t;
              return Tooltip(
                message: t.displayName,
                child: GestureDetector(
                  onTap: () => onTypeChanged(t),
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF00D4FF) : const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(t.icon, size: 16, color: isSel ? Colors.black : Colors.white70),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Selector de Dirección de Cola
        Row(
          children: [
            const Text('Cola:', style: TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ComicTailDirection.values.map((dir) {
                    final isSel = selectedTailDirection == dir;
                    return GestureDetector(
                      onTap: () => onTailChanged(dir),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFDE59) : const Color(0xFF282828),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(dir.icon, size: 12, color: isSel ? Colors.black : Colors.white70),
                            const SizedBox(width: 2),
                            Text(
                              dir.label,
                              style: TextStyle(
                                color: isSel ? Colors.black : Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Campo de Texto
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF292929),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Escribe el diálogo...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
              border: InputBorder.none,
              isDense: true,
            ),
            onChanged: (_) => onTextSubmitted(),
          ),
        ),
      ],
    );
  }
}

/// Pestaña de Transformación (Ancho, Alto, Rotación) para ComicFloatingBubbleBar.
class ComicBubbleTransformTab extends StatelessWidget {
  final double width;
  final double height;
  final double rotation;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onRotationChanged;

  const ComicBubbleTransformTab({
    super.key,
    required this.width,
    required this.height,
    required this.rotation,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onRotationChanged,
  });

  Widget _buildSliderRow(String label, double val, double min, double max, String textVal, Color color, ValueChanged<double> onChange) {
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbColor: color,
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xFF333333),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(value: val.clamp(min, max), min: min, max: max, onChanged: onChange),
          ),
        ),
        SizedBox(width: 40, child: Text(textVal, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 10))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSliderRow('Ancho', width, 80.0, 320.0, '${width.toInt()}px', const Color(0xFF00D4FF), onWidthChanged),
        _buildSliderRow('Alto', height, 50.0, 220.0, '${height.toInt()}px', const Color(0xFFFF00FF), onHeightChanged),
        _buildSliderRow('Ángulo', rotation, -math.pi, math.pi, '${(rotation * 180 / math.pi).toInt()}°', const Color(0xFFFFDE59), onRotationChanged),
      ],
    );
  }
}
