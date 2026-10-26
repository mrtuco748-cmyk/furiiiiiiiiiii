import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/comic_sticker.dart';

/// Pestaña de Texto y Estilo para ComicSfxEditorBar.
class ComicSfxStyleTab extends StatelessWidget {
  final TextEditingController textController;
  final ComicSfxStyle selectedStyle;
  final String selectedFont;
  final ValueChanged<ComicSfxStyle> onStyleChanged;
  final ValueChanged<String> onFontChanged;
  final VoidCallback onTextSubmitted;

  const ComicSfxStyleTab({
    super.key,
    required this.textController,
    required this.selectedStyle,
    required this.selectedFont,
    required this.onStyleChanged,
    required this.onFontChanged,
    required this.onTextSubmitted,
  });

  static const List<String> fonts = ['Bangers', 'Russo One', 'Bungee', 'Permanent Marker', 'Press Start 2P', 'Oswald'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Texto SFX...'),
            onChanged: (_) => onTextSubmitted(),
          ),
        ),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ComicSfxStyle.values.map((st) {
              final isSel = selectedStyle == st;
              return GestureDetector(
                onTap: () => onStyleChanged(st),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFFF00FF) : const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(st.icon, size: 12, color: isSel ? Colors.white : Colors.white60),
                      const SizedBox(width: 4),
                      Text(st.label, style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: fonts.map((f) {
              final isSel = selectedFont == f;
              return GestureDetector(
                onTap: () => onFontChanged(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF00D4FF) : const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(f.split(' ').first, style: TextStyle(color: isSel ? Colors.black : Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Pestaña de Escala y Rotación para ComicSfxEditorBar.
class ComicSfxTransformTab extends StatelessWidget {
  final double scale;
  final double rotation;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onRotationChanged;

  const ComicSfxTransformTab({
    super.key,
    required this.scale,
    required this.rotation,
    required this.onScaleChanged,
    required this.onRotationChanged,
  });

  Widget _buildSlider(String label, double val, double min, double max, String text, Color color, ValueChanged<double> onChange) {
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
        SizedBox(width: 40, child: Text(text, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 10))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSlider('Escala', scale, 0.4, 3.5, '${(scale * 100).toInt()}%', const Color(0xFFFFDE59), onScaleChanged),
        _buildSlider('Ángulo', rotation, -math.pi, math.pi, '${(rotation * 180 / math.pi).toInt()}°', const Color(0xFF00D4FF), onRotationChanged),
      ],
    );
  }
}

/// Pestaña de Colores para ComicSfxEditorBar.
class ComicSfxColorsTab extends StatelessWidget {
  final Color fillColor;
  final Color outlineColor;
  final ValueChanged<Color> onFillColorChanged;
  final ValueChanged<Color> onOutlineColorChanged;

  const ComicSfxColorsTab({
    super.key,
    required this.fillColor,
    required this.outlineColor,
    required this.onFillColorChanged,
    required this.onOutlineColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('Relleno:', style: TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Color(0xFFFFDE59),
                    const Color(0xFFFF3B30),
                    const Color(0xFF00D4FF),
                    const Color(0xFFFF00FF),
                    const Color(0xFF39FF14),
                    const Color(0xFFFFFFFF),
                    const Color(0xFF8A2BE2),
                    const Color(0xFFFF6B00),
                  ].map((c) {
                    final isSel = fillColor.toARGB32() == c.toARGB32();
                    return GestureDetector(
                      onTap: () => onFillColorChanged(c),
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                        child: isSel ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text('Borde:', style: TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(width: 14),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Color(0xFF111111),
                    const Color(0xFFFFFFFF),
                    const Color(0xFF0055B8),
                    const Color(0xFF58007C),
                    const Color(0xFFE60012),
                  ].map((c) {
                    final isSel = outlineColor.toARGB32() == c.toARGB32();
                    return GestureDetector(
                      onTap: () => onOutlineColorChanged(c),
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                        child: isSel ? const Icon(Icons.check, size: 12, color: Colors.amber) : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
