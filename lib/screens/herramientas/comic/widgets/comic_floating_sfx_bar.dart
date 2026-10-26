import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barra flotante no invasiva para estampar onomatopeyas SFX con 1-tap.
class ComicFloatingSfxBar extends StatefulWidget {
  final void Function(String text, Color color) onStamp;
  final VoidCallback onClose;

  const ComicFloatingSfxBar({
    super.key,
    required this.onStamp,
    required this.onClose,
  });

  @override
  State<ComicFloatingSfxBar> createState() => _ComicFloatingSfxBarState();
}

class _ComicFloatingSfxBarState extends State<ComicFloatingSfxBar> {
  Color _selectedColor = const Color(0xFFFFDE59);

  final List<String> _presets = [
    '¡¡BOOM!!',
    '¡¡CRASH!!',
    '¡¡ZAP!!',
    '¡¡WHAM!!',
    '¡¡SMASH!!',
    '¡¡KABOOM!!',
    '¡¡DOKI DOKI!!',
    '¡¡CHU~!!',
    '¡¡TE AMO!!',
    '¡¡KYAAA!!',
    '¡¡FURI!!',
    '¡¡UWU!!',
    '¡¡SLAP!!',
    '¡¡SWOOSH!!',
    '¡¡PLOP!!',
    '¡¡GLUP!!',
    '¡¡GRRR!!',
    '¡¡BEEP!!',
    'ゴゴゴゴ',
    'ドドドド',
    'バーン',
    'ドキドキ',
  ];

  final List<Color> _colors = [
    Color(0xFFFFDE59), // Amarillo Manga
    Color(0xFFFF3B30), // Rojo Shonen
    Color(0xFF00D4FF), // Cian
    Color(0xFFFF00FF), // Fucsia
    Color(0xFF39FF14), // Verde Neón
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector de color compacto
          ..._colors.map((c) {
            final isSel = _selectedColor == c;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                ),
                child: isSel ? const Icon(Icons.check, size: 10, color: Colors.black) : null,
              ),
            );
          }),

          Container(width: 1, height: 22, color: const Color(0xFF333333), margin: const EdgeInsets.only(right: 6)),

          // Scroll horizontal de efectos
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _presets.map((p) {
                  return GestureDetector(
                    onTap: () => widget.onStamp(p, _selectedColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p,
                        style: GoogleFonts.bangers(
                          fontSize: 14,
                          color: _selectedColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Cerrar barra
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(Icons.close, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }
}
