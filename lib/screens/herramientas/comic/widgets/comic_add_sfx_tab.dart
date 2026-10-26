import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_sticker.dart';

/// Pestaña de Onomatopeyas SFX para ComicAddDrawer
class ComicAddSfxTab extends StatefulWidget {
  final ComicController controller;

  const ComicAddSfxTab({super.key, required this.controller});

  @override
  State<ComicAddSfxTab> createState() => _ComicAddSfxTabState();
}

class _ComicAddSfxTabState extends State<ComicAddSfxTab> {
  ComicSfxStyle _selectedSfxStyle = ComicSfxStyle.standard;
  final Color _selectedSfxColor = const Color(0xFFFFDE59);

  static const List<String> _sfxList = [
    '¡BOOM!', '¡ZAS!', '¡CRASH!', '¡POW!', '¡SLASH!', '¡BANG!',
    'ドンッ', 'ゴゴゴ', 'ズキューン', 'ドキドキ', 'ざわ…', 'バーン',
    'Doki Doki', 'Kyaa!', 'Chu~', 'Te amo ❤️', '¡WAAAH!', 'Baki!'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de estilo SFX
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: ComicSfxStyle.values.map((style) {
              final isSel = _selectedSfxStyle == style;
              return GestureDetector(
                onTap: () => setState(() => _selectedSfxStyle = style),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFFFDE59) : const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    style.label,
                    style: TextStyle(
                      color: isSel ? Colors.black : Colors.white70,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Grilla de stickers SFX
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: _sfxList.length,
            itemBuilder: (context, index) {
              final text = _sfxList[index];
              return GestureDetector(
                onTap: () {
                  widget.controller.addSfx(text, color: _selectedSfxColor);
                  if (widget.controller.selectedSfx != null) {
                    widget.controller.updateSfx(
                      widget.controller.selectedSfx!.copyWith(sfxStyle: _selectedSfxStyle),
                    );
                  }
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFFFFDE59),
                      fontFamily: 'Bangers',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
