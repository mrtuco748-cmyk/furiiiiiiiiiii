import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/tap_tile.dart';

/// Barra de navegación superior entre preguntas del mazo de Trivia.
class TriviaDeckNav extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final ValueChanged<int> onIndexChanged;

  const TriviaDeckNav({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TapTile(
            onTap: currentIndex > 0
                ? () => onIndexChanged(currentIndex - 1)
                : () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: currentIndex > 0
                    ? const Color(0xFF222222)
                    : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_left,
                color: currentIndex > 0 ? Colors.white : Colors.white24,
                size: 24,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${currentIndex + 1} de $totalQuestions',
              style: GoogleFonts.bangers(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),
          ),
          TapTile(
            onTap: currentIndex < totalQuestions - 1
                ? () => onIndexChanged(currentIndex + 1)
                : () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: currentIndex < totalQuestions - 1
                    ? const Color(0xFF222222)
                    : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right,
                color: currentIndex < totalQuestions - 1
                    ? Colors.white
                    : Colors.white24,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
