import 'package:flutter/material.dart';

/// Pestaña de Colores y Fuente para ComicFloatingBubbleBar.
class ComicBubbleColorAndFontTab extends StatelessWidget {
  final String fontFamily;
  final Color backgroundColor;
  final Color textColor;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<Color> onBgChanged;
  final ValueChanged<Color> onTextColorChanged;

  const ComicBubbleColorAndFontTab({
    super.key,
    required this.fontFamily,
    required this.backgroundColor,
    required this.textColor,
    required this.onFontChanged,
    required this.onBgChanged,
    required this.onTextColorChanged,
  });

  static const List<String> fonts = [
    'Bangers',
    'Comic Neue',
    'Permanent Marker',
    'Press Start 2P',
    'Caveat',
    'Patrick Hand',
    'Russo One',
    'Bungee',
    'Oswald',
  ];

  static const List<Color> bgColors = [
    Colors.white,
    Color(0xFFF6F6F6),
    Color(0xFFFFDE59),
    Color(0xFF00D4FF),
    Color(0xFFFFB7B2),
    Color(0xFF141414),
  ];

  static const List<Color> textColors = [
    Color(0xFF111111),
    Color(0xFFE60012),
    Color(0xFF0055B8),
    Color(0xFF8A2BE2),
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector de Fuentes
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: fonts.map((f) {
              final isSel = fontFamily == f;
              return GestureDetector(
                onTap: () => onFontChanged(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFFF00FF) : const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    f.split(' ').first,
                    style: TextStyle(
                      color: isSel ? Colors.white : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Color de Fondo
        Row(
          children: [
            const Text('Fondo:', style: TextStyle(color: Colors.white60, fontSize: 10)),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: bgColors.map((c) {
                    final isSel = backgroundColor.toARGB32() == c.toARGB32();
                    return GestureDetector(
                      onTap: () => onBgChanged(c),
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

        // Color de Texto / Borde
        Row(
          children: [
            const Text('Texto:', style: TextStyle(color: Colors.white60, fontSize: 10)),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: textColors.map((c) {
                    final isSel = textColor.toARGB32() == c.toARGB32();
                    return GestureDetector(
                      onTap: () => onTextColorChanged(c),
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
