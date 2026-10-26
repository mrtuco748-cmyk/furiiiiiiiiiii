import 'package:flutter/material.dart';
import '../models/comic_sticker.dart';
import 'comic_sfx_editor_tabs.dart';

/// Barra flotante contextual para modificar un efecto de sonido / onomatopeya (SFX) seleccionado:
/// Texto, tamaño, rotación, estilo gráfico, color de relleno y contorno.
class ComicSfxEditorBar extends StatefulWidget {
  final ComicSticker sfx;
  final ValueChanged<ComicSticker> onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const ComicSfxEditorBar({
    super.key,
    required this.sfx,
    required this.onUpdate,
    required this.onDelete,
    required this.onClose,
  });

  @override
  State<ComicSfxEditorBar> createState() => _ComicSfxEditorBarState();
}

class _ComicSfxEditorBarState extends State<ComicSfxEditorBar> {
  late final TextEditingController _textCtrl;
  late double _scale;
  late double _rotation;
  late double _fontSize;
  late String _fontFamily;
  late ComicSfxStyle _sfxStyle;
  late Color _color;
  late Color _outlineColor;

  int _tab = 0; // 0 = Texto & Estilo, 1 = Giro & Escala, 2 = Colores

  @override
  void initState() {
    super.initState();
    final s = widget.sfx;
    _textCtrl = TextEditingController(text: s.text);
    _scale = s.scale;
    _rotation = s.rotation;
    _fontSize = s.fontSize;
    _fontFamily = s.fontFamily;
    _sfxStyle = s.sfxStyle;
    _color = s.color;
    _outlineColor = s.outlineColor;
  }

  @override
  void didUpdateWidget(covariant ComicSfxEditorBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sfx.id != widget.sfx.id ||
        oldWidget.sfx.scale != widget.sfx.scale ||
        oldWidget.sfx.rotation != widget.sfx.rotation ||
        oldWidget.sfx.text != widget.sfx.text) {
      final s = widget.sfx;
      if (oldWidget.sfx.id != widget.sfx.id) {
        _textCtrl.text = s.text;
      }
      _scale = s.scale;
      _rotation = s.rotation;
      _fontSize = s.fontSize;
      _fontFamily = s.fontFamily;
      _sfxStyle = s.sfxStyle;
      _color = s.color;
      _outlineColor = s.outlineColor;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final text = _textCtrl.text.trim();
    final updated = widget.sfx.copyWith(
      text: text.isEmpty ? '¡ZAS!' : text,
      scale: _scale,
      rotation: _rotation,
      fontSize: _fontSize,
      fontFamily: _fontFamily,
      sfxStyle: _sfxStyle,
      color: _color,
      outlineColor: _outlineColor,
    );
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pestañas
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTab(0, 'Estilo', Icons.auto_awesome),
                      const SizedBox(width: 4),
                      _buildTab(1, 'Giro', Icons.rotate_right),
                      const SizedBox(width: 4),
                      _buildTab(2, 'Color', Icons.palette),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(Icons.delete_outline, color: Color(0xFFFF453A), size: 20),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_tab == 0)
            ComicSfxStyleTab(
              textController: _textCtrl,
              selectedStyle: _sfxStyle,
              selectedFont: _fontFamily,
              onStyleChanged: (st) {
                setState(() => _sfxStyle = st);
                _apply();
              },
              onFontChanged: (f) {
                setState(() => _fontFamily = f);
                _apply();
              },
              onTextSubmitted: _apply,
            ),
          if (_tab == 1)
            ComicSfxTransformTab(
              scale: _scale,
              rotation: _rotation,
              onScaleChanged: (v) {
                setState(() => _scale = v);
                _apply();
              },
              onRotationChanged: (v) {
                setState(() => _rotation = v);
                _apply();
              },
            ),
          if (_tab == 2)
            ComicSfxColorsTab(
              fillColor: _color,
              outlineColor: _outlineColor,
              onFillColorChanged: (c) {
                setState(() => _color = c);
                _apply();
              },
              onOutlineColorChanged: (c) {
                setState(() => _outlineColor = c);
                _apply();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTab(int idx, String label, IconData icon) {
    final isSel = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFFFDE59) : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSel ? Colors.black : Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
