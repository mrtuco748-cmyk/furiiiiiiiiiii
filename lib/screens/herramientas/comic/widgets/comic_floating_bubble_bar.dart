import 'package:flutter/material.dart';
import '../models/comic_bubble.dart';
import 'comic_bubble_color_tab.dart';
import 'comic_bubble_tabs.dart';

/// Barra flotante no invasiva para crear y modificar completamente globos de diálogo:
/// Forma, texto, tamaño, rotación, dirección de cola, colores y fuentes.
class ComicFloatingBubbleBar extends StatefulWidget {
  final ComicBubble? bubble;
  final ValueChanged<ComicBubble> onSave;
  final ValueChanged<String>? onDelete;
  final VoidCallback onClose;

  const ComicFloatingBubbleBar({
    super.key,
    this.bubble,
    required this.onSave,
    this.onDelete,
    required this.onClose,
  });

  @override
  State<ComicFloatingBubbleBar> createState() => _ComicFloatingBubbleBarState();
}

class _ComicFloatingBubbleBarState extends State<ComicFloatingBubbleBar> {
  late final TextEditingController _textCtrl;
  late ComicBubbleType _type;
  late String _fontFamily;
  late double _fontSize;
  late double _width;
  late double _height;
  late double _rotation;
  late ComicTailDirection _tailDirection;
  late Color _backgroundColor;
  late Color _borderColor;
  late Color _textColor;

  int _currentTab = 0; // 0 = Texto & Forma, 1 = Tamaño & Giro, 2 = Colores & Fuente

  @override
  void initState() {
    super.initState();
    final b = widget.bubble;
    _textCtrl = TextEditingController(text: b?.text ?? '¡Hola!');
    _type = b?.type ?? ComicBubbleType.mangaOval;
    _fontFamily = b?.fontFamily ?? 'Comic Neue';
    _fontSize = b?.fontSize ?? 14.0;
    _width = b?.width ?? 160.0;
    _height = b?.height ?? 90.0;
    _rotation = b?.rotation ?? 0.0;
    _tailDirection = b?.tailDirection ?? ComicTailDirection.bottom;
    _backgroundColor = b?.backgroundColor ?? const Color(0xFFFFFFFF);
    _borderColor = b?.borderColor ?? const Color(0xFF111111);
    _textColor = b?.textColor ?? const Color(0xFF111111);
  }

  @override
  void didUpdateWidget(covariant ComicFloatingBubbleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bubble?.id != widget.bubble?.id ||
        oldWidget.bubble?.width != widget.bubble?.width ||
        oldWidget.bubble?.height != widget.bubble?.height ||
        oldWidget.bubble?.rotation != widget.bubble?.rotation) {
      final b = widget.bubble;
      if (oldWidget.bubble?.id != widget.bubble?.id) {
        _textCtrl.text = b?.text ?? '¡Hola!';
      }
      _type = b?.type ?? ComicBubbleType.mangaOval;
      _fontFamily = b?.fontFamily ?? 'Comic Neue';
      _fontSize = b?.fontSize ?? 14.0;
      _width = b?.width ?? 160.0;
      _height = b?.height ?? 90.0;
      _rotation = b?.rotation ?? 0.0;
      _tailDirection = b?.tailDirection ?? ComicTailDirection.bottom;
      _backgroundColor = b?.backgroundColor ?? const Color(0xFFFFFFFF);
      _borderColor = b?.borderColor ?? const Color(0xFF111111);
      _textColor = b?.textColor ?? const Color(0xFF111111);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _applyLiveChanges() {
    final text = _textCtrl.text.trim();
    final result = (widget.bubble ??
            ComicBubble(
              id: 'bubble_${DateTime.now().microsecondsSinceEpoch}',
              type: _type,
              text: text.isEmpty ? '...' : text,
            ))
        .copyWith(
      text: text.isEmpty ? '...' : text,
      type: _type,
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      width: _width,
      height: _height,
      rotation: _rotation,
      tailDirection: _tailDirection,
      backgroundColor: _backgroundColor,
      borderColor: _borderColor,
      textColor: _textColor,
    );
    widget.onSave(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pestañas compactas
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton(0, 'Texto', Icons.edit_note),
                      const SizedBox(width: 4),
                      _buildTabButton(1, 'Ajuste', Icons.open_in_full),
                      const SizedBox(width: 4),
                      _buildTabButton(2, 'Color', Icons.palette_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (widget.bubble != null && widget.onDelete != null)
                GestureDetector(
                  onTap: () => widget.onDelete!(widget.bubble!.id),
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

          if (_currentTab == 0)
            ComicBubbleShapeAndTextTab(
              selectedType: _type,
              selectedTailDirection: _tailDirection,
              textController: _textCtrl,
              onTypeChanged: (t) {
                setState(() => _type = t);
                _applyLiveChanges();
              },
              onTailChanged: (dir) {
                setState(() => _tailDirection = dir);
                _applyLiveChanges();
              },
              onTextSubmitted: _applyLiveChanges,
            ),
          if (_currentTab == 1)
            ComicBubbleTransformTab(
              width: _width,
              height: _height,
              rotation: _rotation,
              onWidthChanged: (v) {
                setState(() => _width = v);
                _applyLiveChanges();
              },
              onHeightChanged: (v) {
                setState(() => _height = v);
                _applyLiveChanges();
              },
              onRotationChanged: (v) {
                setState(() => _rotation = v);
                _applyLiveChanges();
              },
            ),
          if (_currentTab == 2)
            ComicBubbleColorAndFontTab(
              fontFamily: _fontFamily,
              backgroundColor: _backgroundColor,
              textColor: _textColor,
              onFontChanged: (f) {
                setState(() => _fontFamily = f);
                _applyLiveChanges();
              },
              onBgChanged: (c) {
                setState(() => _backgroundColor = c);
                _applyLiveChanges();
              },
              onTextColorChanged: (c) {
                setState(() {
                  _textColor = c;
                  _borderColor = c;
                });
                _applyLiveChanges();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSel = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF00D4FF) : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSel ? Colors.black : Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.black : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
