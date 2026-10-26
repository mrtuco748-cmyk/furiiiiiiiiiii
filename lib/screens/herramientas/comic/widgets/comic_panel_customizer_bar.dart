import 'package:flutter/material.dart';
import '../models/comic_panel.dart';
import 'comic_panel_customizer_tabs.dart';

/// Barra flotante completa para personalizar viñetas:
/// Formas (corte shonen, trapecio, rombo, etc.), ángulo/inclinación,
/// dimensiones, esquinas, colores de fondo y borde, y división de paneles.
class ComicPanelCustomizerBar extends StatefulWidget {
  final ComicPanel panel;
  final ValueChanged<ComicPanel> onUpdate;
  final VoidCallback onSplitH;
  final VoidCallback onSplitV;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const ComicPanelCustomizerBar({
    super.key,
    required this.panel,
    required this.onUpdate,
    required this.onSplitH,
    required this.onSplitV,
    required this.onDelete,
    required this.onClose,
  });

  @override
  State<ComicPanelCustomizerBar> createState() => _ComicPanelCustomizerBarState();
}

class _ComicPanelCustomizerBarState extends State<ComicPanelCustomizerBar> {
  late ComicPanelShape _shape;
  late double _rotation;
  late double _skewX;
  late double _borderRadius;
  late double _borderWidth;
  late Color _borderColor;
  late Color _backgroundColor;
  late double _width;
  late double _height;

  int _tab = 0; // 0 = Forma & Ángulo, 1 = Dimensiones & División, 2 = Colores

  @override
  void initState() {
    super.initState();
    final p = widget.panel;
    _shape = p.panelShape;
    _rotation = p.rotation;
    _skewX = p.skewX;
    _borderRadius = p.borderRadius;
    _borderWidth = p.borderWidth;
    _borderColor = p.borderColor;
    _backgroundColor = p.backgroundColor;
    _width = p.normalizedRect.width;
    _height = p.normalizedRect.height;
  }

  @override
  void didUpdateWidget(covariant ComicPanelCustomizerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.panel.id != widget.panel.id) {
      final p = widget.panel;
      _shape = p.panelShape;
      _rotation = p.rotation;
      _skewX = p.skewX;
      _borderRadius = p.borderRadius;
      _borderWidth = p.borderWidth;
      _borderColor = p.borderColor;
      _backgroundColor = p.backgroundColor;
      _width = p.normalizedRect.width;
      _height = p.normalizedRect.height;
    }
  }

  void _apply() {
    final updatedRect = Rect.fromLTWH(
      widget.panel.normalizedRect.left,
      widget.panel.normalizedRect.top,
      _width.clamp(0.1, 0.96),
      _height.clamp(0.1, 0.96),
    );

    final updated = widget.panel.copyWith(
      panelShape: _shape,
      rotation: _rotation,
      skewX: _skewX,
      borderRadius: _borderRadius,
      borderWidth: _borderWidth,
      borderColor: _borderColor,
      backgroundColor: _backgroundColor,
      normalizedRect: updatedRect,
    );
    widget.onUpdate(updated);
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
          // Pestañas
          Row(
            children: [
              _buildTab(0, 'Forma & Giro', Icons.crop_rotate),
              const SizedBox(width: 4),
              _buildTab(1, 'Tamaño & Split', Icons.aspect_ratio),
              const SizedBox(width: 4),
              _buildTab(2, 'Color & Marco', Icons.color_lens_outlined),
              const Spacer(),
              GestureDetector(
                onTap: widget.onDelete,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.delete_outline, color: Color(0xFFFF453A), size: 18),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_tab == 0)
            ComicPanelShapeTab(
              selectedShape: _shape,
              skewX: _skewX,
              rotation: _rotation,
              borderRadius: _borderRadius,
              onShapeChanged: (s) {
                setState(() => _shape = s);
                _apply();
              },
              onSkewChanged: (v) {
                setState(() => _skewX = v);
                _apply();
              },
              onRotationChanged: (v) {
                setState(() => _rotation = v);
                _apply();
              },
              onRadiusChanged: (v) {
                setState(() => _borderRadius = v);
                _apply();
              },
            ),
          if (_tab == 1)
            ComicPanelDimensionsTab(
              width: _width,
              height: _height,
              onWidthChanged: (v) {
                setState(() => _width = v);
                _apply();
              },
              onHeightChanged: (v) {
                setState(() => _height = v);
                _apply();
              },
              onSplitH: widget.onSplitH,
              onSplitV: widget.onSplitV,
            ),
          if (_tab == 2)
            ComicPanelColorAndBorderTab(
              borderWidth: _borderWidth,
              backgroundColor: _backgroundColor,
              borderColor: _borderColor,
              onBorderWidthChanged: (v) {
                setState(() => _borderWidth = v);
                _apply();
              },
              onBgColorChanged: (c) {
                setState(() => _backgroundColor = c);
                _apply();
              },
              onBorderColorChanged: (c) {
                setState(() => _borderColor = c);
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
          color: isSel ? const Color(0xFF00D4FF) : const Color(0xFF282828),
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
