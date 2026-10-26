import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/comic_panel.dart';

Widget _buildCustomizerSlider({
  required String label,
  required double value,
  required double min,
  required double max,
  required String displayValue,
  required Color color,
  required ValueChanged<double> onChanged,
  double labelWidth = 60,
}) {
  return Row(
    children: [
      SizedBox(width: labelWidth, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))),
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
          child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ),
      ),
      SizedBox(width: 36, child: Text(displayValue, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 10))),
    ],
  );
}

/// Pestaña de Forma y Ángulo de Viñeta.
class ComicPanelShapeTab extends StatelessWidget {
  final ComicPanelShape selectedShape;
  final double skewX;
  final double rotation;
  final double borderRadius;
  final ValueChanged<ComicPanelShape> onShapeChanged;
  final ValueChanged<double> onSkewChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<double> onRadiusChanged;

  const ComicPanelShapeTab({
    super.key,
    required this.selectedShape,
    required this.skewX,
    required this.rotation,
    required this.borderRadius,
    required this.onShapeChanged,
    required this.onSkewChanged,
    required this.onRotationChanged,
    required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ComicPanelShape.values.map((s) {
              final isSel = selectedShape == s;
              return Tooltip(
                message: s.displayName,
                child: GestureDetector(
                  onTap: () => onShapeChanged(s),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF00D4FF) : const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(s.icon, size: 18, color: isSel ? Colors.black : Colors.white70),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        _buildCustomizerSlider(label: 'Inclinación', value: skewX, min: -0.3, max: 0.3, displayValue: '${(skewX * 100).toInt()}%', color: const Color(0xFFFFDE59), onChanged: onSkewChanged),
        _buildCustomizerSlider(label: 'Ángulo', value: rotation, min: -0.4, max: 0.4, displayValue: '${(rotation * 180 / math.pi).toInt()}°', color: const Color(0xFFFF00FF), onChanged: onRotationChanged),
        _buildCustomizerSlider(label: 'Redondeo', value: borderRadius, min: 0.0, max: 24.0, displayValue: '${borderRadius.toInt()}px', color: const Color(0xFF39FF14), onChanged: onRadiusChanged),
      ],
    );
  }
}

/// Pestaña de Dimensiones y División de Viñeta.
class ComicPanelDimensionsTab extends StatelessWidget {
  final double width;
  final double height;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onHeightChanged;
  final VoidCallback onSplitH;
  final VoidCallback onSplitV;

  const ComicPanelDimensionsTab({
    super.key,
    required this.width,
    required this.height,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onSplitH,
    required this.onSplitV,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCustomizerSlider(label: 'Ancho', value: width, min: 0.15, max: 0.94, displayValue: '${(width * 100).toInt()}%', color: const Color(0xFF00D4FF), onChanged: onWidthChanged, labelWidth: 44),
        _buildCustomizerSlider(label: 'Alto', value: height, min: 0.10, max: 0.94, displayValue: '${(height * 100).toInt()}%', color: const Color(0xFFFF00FF), onChanged: onHeightChanged, labelWidth: 44),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onSplitH,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.splitscreen, size: 14, color: Color(0xFF00D4FF)),
                      SizedBox(width: 4),
                      Text('Dividir Horizontal', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: onSplitV,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.vertical_split, size: 14, color: Color(0xFFFFDE59)),
                      SizedBox(width: 4),
                      Text('Dividir Vertical', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pestaña de Colores y Marco de Viñeta.
class ComicPanelColorAndBorderTab extends StatelessWidget {
  final double borderWidth;
  final Color backgroundColor;
  final Color borderColor;
  final ValueChanged<double> onBorderWidthChanged;
  final ValueChanged<Color> onBgColorChanged;
  final ValueChanged<Color> onBorderColorChanged;

  const ComicPanelColorAndBorderTab({
    super.key,
    required this.borderWidth,
    required this.backgroundColor,
    required this.borderColor,
    required this.onBorderWidthChanged,
    required this.onBgColorChanged,
    required this.onBorderColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCustomizerSlider(label: 'Marco', value: borderWidth, min: 0.0, max: 10.0, displayValue: '${borderWidth.toInt()}px', color: const Color(0xFF00D4FF), onChanged: onBorderWidthChanged, labelWidth: 44),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text('Fondo:', style: TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Colors.white,
                    const Color(0xFF141414),
                    const Color(0xFF0B0B0B),
                    const Color(0xFFF6F6F6),
                    const Color(0xFFFFDE59),
                    const Color(0xFFE60012),
                    const Color(0xFF1C2833),
                  ].map((c) {
                    final isSel = backgroundColor.toARGB32() == c.toARGB32();
                    return GestureDetector(
                      onTap: () => onBgColorChanged(c),
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                        child: isSel ? const Icon(Icons.check, size: 12, color: Colors.grey) : null,
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
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Color(0xFF111111),
                    Colors.white,
                    const Color(0xFF00D4FF),
                    const Color(0xFFFFDE59),
                    const Color(0xFFFF00FF),
                    const Color(0xFFE60012),
                  ].map((c) {
                    final isSel = borderColor.toARGB32() == c.toARGB32();
                    return GestureDetector(
                      onTap: () => onBorderColorChanged(c),
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
