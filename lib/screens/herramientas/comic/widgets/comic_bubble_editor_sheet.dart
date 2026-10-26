import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/comic_bubble.dart';

/// Modal para crear y editar globos de diálogo (manga, grito, pensamiento, FURI).
class ComicBubbleEditorSheet extends StatefulWidget {
  final ComicBubble? bubble;
  final ValueChanged<ComicBubble> onSave;
  final ValueChanged<String>? onDelete;

  const ComicBubbleEditorSheet({
    super.key,
    this.bubble,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ComicBubbleEditorSheet> createState() => _ComicBubbleEditorSheetState();
}

class _ComicBubbleEditorSheetState extends State<ComicBubbleEditorSheet> {
  late final TextEditingController _textCtrl;
  late ComicBubbleType _type;
  late String _fontFamily;
  late double _fontSize;
  late Color _backgroundColor;
  late Color _textColor;

  final List<String> _availableFonts = [
    'Bangers',
    'Comic Neue',
    'Permanent Marker',
    'Caveat',
    'Patrick Hand',
    'Press Start 2P',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.bubble;
    _textCtrl = TextEditingController(text: b?.text ?? '¡Hola amor!');
    _type = b?.type ?? ComicBubbleType.mangaOval;
    _fontFamily = b?.fontFamily ?? 'Bangers';
    _fontSize = b?.fontSize ?? 18.0;
    _backgroundColor = b?.backgroundColor ?? const Color(0xFFFFFFFF);
    _textColor = b?.textColor ?? const Color(0xFF111111);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  TextStyle _getStyleForFont(String font, {double size = 14, Color? color}) {
    switch (font) {
      case 'Comic Neue':
        return GoogleFonts.comicNeue(fontSize: size, color: color, fontWeight: FontWeight.bold);
      case 'Permanent Marker':
        return GoogleFonts.permanentMarker(fontSize: size, color: color);
      case 'Caveat':
        return GoogleFonts.caveat(fontSize: size + 2, color: color, fontWeight: FontWeight.bold);
      case 'Patrick Hand':
        return GoogleFonts.patrickHand(fontSize: size + 1, color: color);
      case 'Press Start 2P':
        return GoogleFonts.pressStart2p(fontSize: size - 4, color: color);
      case 'Bangers':
      default:
        return GoogleFonts.bangers(fontSize: size, color: color);
    }
  }

  void _submit() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final result = (widget.bubble ??
            ComicBubble(
              id: 'bubble_${DateTime.now().microsecondsSinceEpoch}',
              type: _type,
              text: text,
            ))
        .copyWith(
      text: text,
      type: _type,
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
    );

    widget.onSave(result);
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.bubble == null ? 'Nuevo Globo' : 'Editar Globo',
                  style: GoogleFonts.bangers(fontSize: 22, color: Colors.white, letterSpacing: 1),
                ),
                if (widget.bubble != null && widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                    onPressed: () {
                      widget.onDelete!(widget.bubble!.id);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Campo de Texto
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF262626),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: TextField(
                controller: _textCtrl,
                maxLines: 3,
                style: _getStyleForFont(_fontFamily, size: 16, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Texto del globo...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selector de Estilo de Globo
            const Text('ESTILO DE GLOBO', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ComicBubbleType.values.map((type) {
                  final isSelected = _type == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _type = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          type.label,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Selector de Fuente
            const Text('TIPOGRAFÍA MANGA', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableFonts.map((font) {
                  final isSelected = _fontFamily == font;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _fontFamily = font),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF00FF) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          font,
                          style: _getStyleForFont(
                            font,
                            size: 13,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Slider Tamaño de Fuente
            Row(
              children: [
                const Text('TAMAÑO', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                Expanded(
                  child: SliderTheme(
                    data: const SliderThemeData(
                      thumbColor: Color(0xFF39FF14),
                      activeTrackColor: Color(0xFF39FF14),
                      inactiveTrackColor: Color(0xFF333333),
                    ),
                    child: Slider(
                      value: _fontSize.clamp(12.0, 32.0),
                      min: 12,
                      max: 32,
                      onChanged: (val) => setState(() => _fontSize = val),
                    ),
                  ),
                ),
                Text('${_fontSize.toInt()} px', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),

            // Botón Guardar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submit,
              child: Text(
                widget.bubble == null ? 'COLOCAR GLOBO' : 'ACTUALIZAR GLOBO',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
