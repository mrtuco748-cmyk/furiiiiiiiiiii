import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'theme_customizer/theme_block_selector_row.dart';
import 'theme_customizer/theme_customizer_palette.dart';

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
  State<ThemeColorCustomizerSheet> createState() =>
      _ThemeColorCustomizerSheetState();
}

class _ThemeColorCustomizerSheetState extends State<ThemeColorCustomizerSheet> {
  late AppMode _selectedMode;
  String _selectedBlock = 'a';
  double _customHue = 180.0;
  double _customLightness = 0.5;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final baseTheme = appThemes[_selectedMode]!;
    final effectiveTheme = settings.getCustomTheme(_selectedMode, baseTheme);
    final currentColor =
        ThemeBlockSelectorRow.getBlockColor(effectiveTheme, _selectedBlock);

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
                    child:
                        const Icon(Icons.palette, color: Colors.white, size: 20),
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
                    Text(
                      '1. SELECCIONA EL TEMA',
                      style: GoogleFonts.bangers(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ThemeModeSelectorRow(
                      selectedMode: _selectedMode,
                      onModeSelected: (mode) =>
                          setState(() => _selectedMode = mode),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '2. ELIGE EL BLOQUE A PINTAR',
                      style: GoogleFonts.bangers(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ThemeBlockSelectorRow(
                      selectedBlock: _selectedBlock,
                      effectiveTheme: effectiveTheme,
                      onBlockSelected: (bKey) =>
                          setState(() => _selectedBlock = bKey),
                    ),
                    const SizedBox(height: 22),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Editando Bloque ${_selectedBlock.toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(
                              color: currentColor.computeLuminance() > 0.55
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ThemeColorPaletteGrid(
                      currentColor: currentColor,
                      onColorSelected: (pColor) {
                        settings.setCustomColor(
                            _selectedMode, _selectedBlock, pColor);
                      },
                    ),
                    const SizedBox(height: 20),
                    ThemeHueLightnessSelector(
                      hue: _customHue,
                      lightness: _customLightness,
                      onHueChanged: (val) {
                        setState(() => _customHue = val);
                        final color = HSLColor.fromAHSL(
                                1.0, val, 1.0, _customLightness)
                            .toColor();
                        settings.setCustomColor(
                            _selectedMode, _selectedBlock, color);
                      },
                      onLightnessChanged: (val) {
                        setState(() => _customLightness = val);
                        final color =
                            HSLColor.fromAHSL(1.0, _customHue, 1.0, val)
                                .toColor();
                        settings.setCustomColor(
                            _selectedMode, _selectedBlock, color);
                      },
                    ),
                    const SizedBox(height: 12),
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
                            icon: const Icon(Icons.refresh,
                                color: Colors.white70, size: 18),
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
