import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/drawing_controller.dart';

/// Modal para seleccionar y personalizar el color del trazo.
class DrawingColorPickerSheet extends StatefulWidget {
  final DrawingController controller;

  const DrawingColorPickerSheet({super.key, required this.controller});

  @override
  State<DrawingColorPickerSheet> createState() => _DrawingColorPickerSheetState();
}

class _DrawingColorPickerSheetState extends State<DrawingColorPickerSheet> {
  static const List<Color> _palette = [
    Color(0xFF111111),
    Color(0xFF4A4A4A),
    Color(0xFF9E9E9E),
    Color(0xFFFFFFFF),
    Color(0xFFFF3B30),
    Color(0xFFFF6B00),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
    Color(0xFF39FF14),
    Color(0xFF00D4FF),
    Color(0xFF007AFF),
    Color(0xFF5856D6),
    Color(0xFFAF52DE),
    Color(0xFFFF2D55),
    Color(0xFFFF94B8),
    Color(0xFF8D6E63),
    Color(0xFF5D4037),
    Color(0xFFFFCCBC),
    Color(0xFFD7CCC8),
    Color(0xFF004D40),
  ];

  late double _hue;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.controller.selectedColor);
    _hue = hsv.hue;
  }

  void _onHueChanged(double value) {
    setState(() => _hue = value);
    final currentHsv = HSVColor.fromColor(widget.controller.selectedColor);
    final newColor = HSVColor.fromAHSV(
      1.0,
      _hue,
      currentHsv.saturation > 0.1 ? currentHsv.saturation : 0.85,
      currentHsv.value > 0.1 ? currentHsv.value : 0.95,
    ).toColor();
    widget.controller.setColor(newColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'COLOR DEL TRAZO',
              style: GoogleFonts.bangers(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            // Paleta en cuadrícula
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _palette.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, i) {
                final c = _palette[i];
                final isSelected = widget.controller.selectedColor.toARGB32() == c.toARGB32();

                return GestureDetector(
                  onTap: () {
                    widget.controller.setColor(c);
                    setState(() {
                      _hue = HSVColor.fromColor(c).hue;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Espectro de matiz (Hue Slider)
            const Text(
              'Tonalidad personalizada',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: widget.controller.selectedColor,
                inactiveTrackColor: const Color(0xFF262626),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _hue,
                min: 0.0,
                max: 360.0,
                onChanged: _onHueChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
