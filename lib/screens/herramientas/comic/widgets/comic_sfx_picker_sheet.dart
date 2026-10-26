import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modal para seleccionar y agregar onomatopeyas / SFX estilo manga.
class ComicSfxPickerSheet extends StatefulWidget {
  final void Function(String text, Color color) onSelect;

  const ComicSfxPickerSheet({super.key, required this.onSelect});

  @override
  State<ComicSfxPickerSheet> createState() => _ComicSfxPickerSheetState();
}

class _ComicSfxPickerSheetState extends State<ComicSfxPickerSheet> {
  final TextEditingController _customCtrl = TextEditingController();
  Color _selectedColor = const Color(0xFFFFDE59);

  final List<String> _presets = [
    '¡¡BOOM!!',
    '¡¡DOKI DOKI!!',
    '¡¡ZAP!!',
    '¡¡WHAM!!',
    '¡¡CRASH!!',
    '¡¡KABOOM!!',
    '¡¡GLUP!!',
    '¡¡SUSPIRO!!',
    '¡¡TE AMO!!',
    '¡¡FURI!!',
    '¡¡SLAP!!',
    '¡¡CHU!!',
  ];

  final List<Color> _colors = [
    const Color(0xFFFFDE59), // Amarillo Manga
    const Color(0xFFFF0055), // Rojo Shonen
    const Color(0xFF00D4FF), // Cian
    const Color(0xFF39FF14), // Verde
    const Color(0xFFFF00FF), // Fucsia
    const Color(0xFFFFFFFF), // Blanco
  ];

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _submitText(String text) {
    if (text.trim().isEmpty) return;
    widget.onSelect(text.trim(), _selectedColor);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFFFDE59), size: 24),
                const SizedBox(width: 10),
                Text(
                  'ONOMATOPEYAS & SFX',
                  style: GoogleFonts.bangers(fontSize: 22, color: Colors.white, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Selector de Colores
            Row(
              children: _colors.map((c) {
                final isSelected = _selectedColor == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.black) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Grilla de Efectos Predefinidos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _submitText(preset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      preset,
                      style: GoogleFonts.bangers(
                        fontSize: 18,
                        color: _selectedColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Texto Personalizado
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _customCtrl,
                      style: GoogleFonts.bangers(fontSize: 18, color: _selectedColor),
                      decoration: const InputDecoration(
                        hintText: 'Texto personalizado...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _submitText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDE59),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: () => _submitText(_customCtrl.text),
                  child: const Text('AGREGAR', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
