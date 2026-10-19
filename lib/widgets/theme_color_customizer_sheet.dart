import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class ThemeColorCustomizerSheet extends StatefulWidget {
  final AppMode initialMode;

  const ThemeColorCustomizerSheet({
    super.key,
    required this.initialMode,
  });

  static Future<void> show(BuildContext context, {required AppMode mode}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ThemeColorCustomizerSheet(initialMode: mode),
    );
  }

  @override
  State<ThemeColorCustomizerSheet> createState() => _ThemeColorCustomizerSheetState();
}

class _ThemeColorCustomizerSheetState extends State<ThemeColorCustomizerSheet> {
  late AppMode _selectedMode;
  String _selectedBlock = 'a'; // 'a', 'b', 'c', 'd', 'e'
  double _customHue = 180.0;
  double _customLightness = 0.5;

  static const List<Color> _presetPalette = [
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

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  String _modeLabel(AppMode mode) {
    switch (mode) {
      case AppMode.flower:
        return '🌸 Flower';
      case AppMode.green:
        return '🌿 Green';
      case AppMode.dark:
        return '🌙 Dark';
      case AppMode.blue:
        return '🌊 Blue';
      case AppMode.heart:
        return '❤️ Heart';
    }
  }

  Color _getBlockColor(SettingsService settings, ThemeSet theme, String key) {
    switch (key) {
      case 'a':
        return theme.a;
      case 'b':
        return theme.b;
      case 'c':
        return theme.c;
      case 'd':
        return theme.d;
      case 'e':
        return theme.e;
      default:
        return theme.a;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final baseTheme = appThemes[_selectedMode]!;
    final effectiveTheme = settings.getCustomTheme(_selectedMode, baseTheme);
    final currentColor = _getBlockColor(settings, effectiveTheme, _selectedBlock);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),

            // Header con título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.palette, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COLORES DE BLOQUES',
                          style: GoogleFonts.bangers(
                            color: Colors.white,
                            fontSize: 19,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Personaliza cada bloque de cada tema',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de Tema (Tabs horizontales)
                    Text(
                      '1. SELECCIONA EL TEMA',
                      style: GoogleFonts.bangers(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: AppMode.values.map((mode) {
                          final isSel = mode == _selectedMode;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedMode = mode);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF00F0FF)
                                      : const Color(0xFF2A2A34),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _modeLabel(mode),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isSel ? Colors.black : Colors.white70,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Vista previa y selector de bloques (A, B, C, D, E)
                    Text(
                      '2. ELIGE EL BLOQUE A PINTAR',
                      style: GoogleFonts.bangers(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['a', 'b', 'c', 'd', 'e'].map((bKey) {
                        final isSel = bKey == _selectedBlock;
                        final color = _getBlockColor(settings, effectiveTheme, bKey);
                        final textColor = color.computeLuminance() > 0.55 ? Colors.black : Colors.white;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedBlock = bKey);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: isSel ? 74 : 64,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            offset: const Offset(0, 4),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'BLOQUE',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: textColor.withValues(alpha: 0.75),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      bKey.toUpperCase(),
                                      style: GoogleFonts.bangers(
                                        color: textColor,
                                        fontSize: 22,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (isSel)
                                      Icon(Icons.check, color: textColor, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // Paleta de Colores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '3. SELECCIONA UN COLOR',
                          style: GoogleFonts.bangers(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Editando Bloque ${_selectedBlock.toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(
                              color: currentColor.computeLuminance() > 0.55 ? Colors.black : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Grid de colores predefinidos
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _presetPalette.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (ctx, idx) {
                        final pColor = _presetPalette[idx];
                        final isChosen = currentColor.toARGB32() == pColor.toARGB32();

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            settings.setCustomColor(_selectedMode, _selectedBlock, pColor);
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
                                    color: pColor.computeLuminance() > 0.55 ? Colors.black : Colors.white,
                                    size: 22,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Selector de tono fino (Hue Slider)
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
                      data: SliderThemeData(
                        trackHeight: 2,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _customHue,
                        min: 0,
                        max: 360,
                        onChanged: (val) {
                          setState(() => _customHue = val);
                          final color = HSLColor.fromAHSL(1.0, val, 1.0, _customLightness).toColor();
                          settings.setCustomColor(_selectedMode, _selectedBlock, color);
                        },
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
                          '${(_customLightness * 100).round()}%',
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
                        value: _customLightness,
                        min: 0.2,
                        max: 0.85,
                        onChanged: (val) {
                          setState(() => _customLightness = val);
                          final color = HSLColor.fromAHSL(1.0, _customHue, 1.0, val).toColor();
                          settings.setCustomColor(_selectedMode, _selectedBlock, color);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF2E2E38),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                            label: Text(
                              'Restablecer tema',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              await settings.resetThemeColors(_selectedMode);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F0FF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'LISTO',
                              style: GoogleFonts.bangers(
                                color: Colors.black,
                                fontSize: 16,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
