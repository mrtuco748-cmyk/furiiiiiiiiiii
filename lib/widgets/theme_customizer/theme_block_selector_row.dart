import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Selector horizontal de modos de tema.
class ThemeModeSelectorRow extends StatelessWidget {
  final AppMode selectedMode;
  final ValueChanged<AppMode> onModeSelected;

  const ThemeModeSelectorRow({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  static String modeLabel(AppMode mode) {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: AppMode.values.map((mode) {
          final isSel = mode == selectedMode;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                onModeSelected(mode);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color(0xFF00F0FF)
                      : const Color(0xFF2A2A34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  modeLabel(mode),
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
    );
  }
}

/// Selector visual interactivo para los bloques (A, B, C, D, E) del tema.
class ThemeBlockSelectorRow extends StatelessWidget {
  final String selectedBlock;
  final ThemeSet effectiveTheme;
  final ValueChanged<String> onBlockSelected;

  const ThemeBlockSelectorRow({
    super.key,
    required this.selectedBlock,
    required this.effectiveTheme,
    required this.onBlockSelected,
  });

  static Color getBlockColor(ThemeSet theme, String key) {
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
    return Row(
      children: ['a', 'b', 'c', 'd', 'e'].map((bKey) {
        final isSel = bKey == selectedBlock;
        final color = getBlockColor(effectiveTheme, bKey);
        final textColor =
            color.computeLuminance() > 0.55 ? Colors.black : Colors.white;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onBlockSelected(bKey);
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
    );
  }
}
