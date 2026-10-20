import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/tap_tile.dart';

/// Tile interactivo para una opción de respuesta o predicción en Trivia.
class TriviaOptionTile extends StatelessWidget {
  final String option;
  final bool isSelected;
  final Color selectedColor;
  final Color textColor;
  final VoidCallback onTap;

  const TriviaOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.selectedColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.bangers(
                  fontSize: 15,
                  color: isSelected ? textColor : Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: textColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
