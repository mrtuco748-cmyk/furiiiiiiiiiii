import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores predefinidos para la personalización de bloques.
const List<Color> kThemePresetPalette = [
  Color(0xFFFF66C4), // Rosa Neón
  Color(0xFF00F0FF), // Cian Neón
  Color(0xFF00FF66), // Verde Neón
  Color(0xFFFFDE59), // Amarillo Sol
  Color(0xFFFF5757), // Rojo Coral
  Color(0xFF7000FF), // Violeta Eléctrico
  Color(0xFFFF8C00), // Naranja Fuego
  Color(0xFF00E5FF), // Turquesa
  Color(0xFF38B6FF), // Azul Cielo
  Color(0xFFC9A8E8), // Lavanda
  Color(0xFF2ECC71), // Esmeralda
  Color(0xFFE91E63), // Fucsia
  Color(0xFFFFAAA6), // Melocotón Pastel
  Color(0xFF9B59B6), // Amatista
  Color(0xFF8E24AA), // Magenta Profundo
  Color(0xFFFFB300), // Ámbar Cálido
  Color(0xFF16A085), // Verde Azulado
  Color(0xFF4A1C5E), // Púrpura Arcilla
  Color(0xFFE67E22), // Zanahoria
  Color(0xFFF1C40F), // Oro Pastel
  Color(0xFF1ABC9C), // Menta Suave
  Color(0xFF34495E), // Azul Noche
  Color(0xFFFFFFFF), // Blanco Puro
  Color(0xFFB0BEC5), // Plata Ceniza
];

/// Grid de colores predefinidos con indicador de selección.
class ThemeColorPaletteGrid extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const ThemeColorPaletteGrid({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kThemePresetPalette.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (ctx, idx) {
        final pColor = kThemePresetPalette[idx];
        final isChosen = currentColor.toARGB32() == pColor.toARGB32();

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onColorSelected(pColor);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: pColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isChosen
                ? Icon(
                    Icons.check,
                    color: pColor.computeLuminance() > 0.55
                        ? Colors.black
                        : Colors.white,
                    size: 22,
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// Selector de tono continuo (Hue) y luminosidad (Lightness).
class ThemeHueLightnessSelector extends StatelessWidget {
  final double hue;
  final double lightness;
  final ValueChanged<double> onHueChanged;
  final ValueChanged<double> onLightnessChanged;

  const ThemeHueLightnessSelector({
    super.key,
    required this.hue,
    required this.lightness,
    required this.onHueChanged,
    required this.onLightnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O AJUSTA UN TONO PERSONALIZADO',
          style: GoogleFonts.bangers(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
        ),
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 2,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Colors.white,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: hue,
            min: 0,
            max: 360,
            onChanged: onHueChanged,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BRILLO / PASTEL',
              style: GoogleFonts.bangers(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${(lightness * 100).round()}%',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: lightness,
            min: 0.2,
            max: 0.85,
            onChanged: onLightnessChanged,
          ),
        ),
      ],
    );
  }
}
