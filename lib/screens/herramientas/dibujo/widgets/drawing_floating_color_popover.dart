import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';
import '../../comic/models/comic_color_palette.dart';

/// Paleta flotante compacta no invasiva para selección rápida de color,
/// incluyendo paletas legendarias de mangas y cómics USA famosos.
class DrawingFloatingColorPopover extends StatefulWidget {
  final DrawingController controller;
  final VoidCallback onClose;

  const DrawingFloatingColorPopover({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<DrawingFloatingColorPopover> createState() => _DrawingFloatingColorPopoverState();
}

class _DrawingFloatingColorPopoverState extends State<DrawingFloatingColorPopover> {
  double _hue = 0.0;
  int _selectedPaletteIndex = 0; // 0 = Básicos, 1+ = Paletas legendarias

  static const List<Color> _defaultSwatches = [
    Color(0xFF111111), // Negro Carbón
    Color(0xFFFFFFFF), // Blanco
    Color(0xFFFFDE59), // Amarillo FURI
    Color(0xFF00D4FF), // Cian Vibrante
    Color(0xFFFF00FF), // Fucsia
    Color(0xFF39FF14), // Verde Neón
    Color(0xFFFF3B30), // Rojo
    Color(0xFFFF6B00), // Naranja
    Color(0xFF7000FF), // Violeta
    Color(0xFF8E8E93), // Gris neutro
    Color(0xFF8B4513), // Marrón cómic
    Color(0xFFFFB6C1), // Rosa piel manga
  ];

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.controller.selectedColor);
    _hue = hsv.hue;
  }

  void _pickColor(Color color) {
    setState(() {
      final hsv = HSVColor.fromColor(color);
      _hue = hsv.hue;
    });
    widget.controller.setColor(color);
  }

  void _onHueChanged(double hue) {
    setState(() => _hue = hue);
    final color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    widget.controller.setColor(color);
  }

  List<Color> get _currentColors {
    if (_selectedPaletteIndex == 0) return _defaultSwatches;
    final palette = ComicColorPalettes.all[_selectedPaletteIndex - 1];
    return palette.colors;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila de Cabecera con selector actual y cerrar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: widget.controller.selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedPaletteIndex == 0
                        ? 'Color'
                        : ComicColorPalettes.all[_selectedPaletteIndex - 1].name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Selector horizontal de paletas Manga / Cómic
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPaletteChip(0, 'Básicos', const Color(0xFF00D4FF)),
                ...ComicColorPalettes.all.asMap().entries.map((entry) {
                  return _buildPaletteChip(
                    entry.key + 1,
                    entry.value.name.split(' ').first,
                    entry.value.accentColor,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Muestras de la paleta activa
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentColors.map((color) {
              final isSelected = widget.controller.selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => _pickColor(color),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: color.computeLuminance() > 0.4 ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Barra de Matiz HSV continua
          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
            child: SliderTheme(
              data: SliderThemeData(
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                trackShape: const RectangularSliderTrackShape(),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(
                value: _hue,
                min: 0,
                max: 360,
                onChanged: _onHueChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteChip(int index, String label, Color accent) {
    final isSel = _selectedPaletteIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaletteIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? accent : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
