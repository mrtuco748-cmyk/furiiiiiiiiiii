import 'package:flutter/material.dart';
import '../models/comic_panel.dart';
import '../../widgets/creative_icon.dart';
import 'comic_panel_quick_border_row.dart';

/// Barra contextual flotante no invasiva para la viñeta seleccionada.
/// Permite dibujar adentro a escala real, insertar, cortar, personalizar bordes y eliminar.
class ComicPanelContextBar extends StatefulWidget {
  final ComicPanel panel;
  final VoidCallback onDraw;
  final VoidCallback onInsert;
  final VoidCallback? onGallery;
  final VoidCallback onCustomize;
  final VoidCallback? onSlice;
  final VoidCallback? onFrameContent;
  final VoidCallback? onDelete;
  final void Function(double borderWidth, Color borderColor)? onQuickBorder;
  final void Function(double scale, double dx, double dy) onTransform;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const ComicPanelContextBar({
    super.key,
    required this.panel,
    required this.onDraw,
    required this.onInsert,
    this.onGallery,
    required this.onCustomize,
    this.onSlice,
    this.onFrameContent,
    this.onDelete,
    this.onQuickBorder,
    required this.onTransform,
    required this.onClear,
    required this.onClose,
  });

  @override
  State<ComicPanelContextBar> createState() => _ComicPanelContextBarState();
}

class _ComicPanelContextBarState extends State<ComicPanelContextBar> {
  bool _showTransformControls = false;
  bool _showBorderControls = false;
  late double _scale;
  late double _dx;
  late double _dy;

  @override
  void initState() {
    super.initState();
    _scale = widget.panel.scale;
    _dx = widget.panel.offsetX;
    _dy = widget.panel.offsetY;
  }

  void _applyTransform() {
    widget.onTransform(_scale, _dx, _dy);
  }

  Widget _buildIconButton({
    required Widget child,
    required VoidCallback onTap,
    Color bg = const Color(0xFF242424),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDrawing = widget.panel.drawingPngBase64 != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Acción 1: Dibujar en esta viñeta a escala real
                _buildIconButton(
                  bg: const Color(0xFF00D4FF),
                  child: const CreativeIcon('pen_gpen', color: Colors.black, size: 20, fallback: Icons.brush),
                  onTap: widget.onDraw,
                ),
                const SizedBox(width: 8),

                // Acción 2: Insertar dibujo guardado
                _buildIconButton(
                  bg: const Color(0xFF39FF14),
                  child: const Icon(Icons.palette_outlined, color: Colors.black, size: 20),
                  onTap: widget.onInsert,
                ),
                const SizedBox(width: 8),

                // Acción 3: Imagen de galería del dispositivo
                if (widget.onGallery != null) ...[
                  _buildIconButton(
                    bg: const Color(0xFF282828),
                    child: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF00D4FF), size: 20),
                    onTap: widget.onGallery!,
                  ),
                  const SizedBox(width: 8),
                ],

                // Acción 4: Cortar viñeta con cuchillo
                if (widget.onSlice != null) ...[
                  _buildIconButton(
                    bg: const Color(0xFFFF6B00),
                    child: const Icon(Icons.content_cut, color: Colors.black, size: 20),
                    onTap: widget.onSlice!,
                  ),
                  const SizedBox(width: 8),
                ],

                // Acción 5: Personalización avanzada (skew, rotación, radio)
                _buildIconButton(
                  bg: const Color(0xFF282828),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF5AC8FA), size: 20),
                  onTap: widget.onCustomize,
                ),
                const SizedBox(width: 8),

                // Acción 6: Borde rápido en 1 toque
                _buildIconButton(
                  bg: _showBorderControls ? const Color(0xFFFFDE59) : const Color(0xFF282828),
                  child: Icon(
                    Icons.border_style,
                    color: _showBorderControls ? Colors.black : const Color(0xFFFFDE59),
                    size: 20,
                  ),
                  onTap: () => setState(() {
                    _showBorderControls = !_showBorderControls;
                    _showTransformControls = false;
                  }),
                ),
                const SizedBox(width: 8),

                // Si tiene dibujo o foto, controles de encuadre táctil y sliders
                if (hasDrawing) ...[
                  _buildIconButton(
                    bg: const Color(0xFFFF00FF),
                    child: const Icon(Icons.crop, color: Colors.white, size: 20),
                    onTap: () {
                      if (widget.onFrameContent != null) {
                        widget.onFrameContent!();
                      } else {
                        setState(() {
                          _showTransformControls = !_showTransformControls;
                          _showBorderControls = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    bg: const Color(0xFF2E1717),
                    child: const Icon(Icons.layers_clear, color: Color(0xFFFF453A), size: 20),
                    onTap: widget.onClear,
                  ),
                  const SizedBox(width: 8),
                ],

                // Acción 7: Eliminar viñeta
                if (widget.onDelete != null) ...[
                  _buildIconButton(
                    bg: const Color(0xFF2E1717),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFFF453A), size: 20),
                    onTap: widget.onDelete!,
                  ),
                  const SizedBox(width: 8),
                ],

                // Cerrar / Deseleccionar viñeta
                _buildIconButton(
                  bg: const Color(0xFF282828),
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),

          // Selector rápido de borde (Grosor y Color en 1 toque)
          if (_showBorderControls) ...[
            const SizedBox(height: 10),
            ComicPanelQuickBorderRow(
              currentBorderWidth: widget.panel.borderWidth,
              currentBorderColor: widget.panel.borderColor,
              onSelect: (w, c) => widget.onQuickBorder?.call(w, c),
            ),
          ],

          // Sliders de escala y paneo para dibujo embebido
          if (_showTransformControls && hasDrawing) ...[
            const SizedBox(height: 10),
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.aspect_ratio, size: 14, color: Color(0xFFFF00FF)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            thumbColor: const Color(0xFFFF00FF),
                            activeTrackColor: const Color(0xFFFF00FF),
                            inactiveTrackColor: const Color(0xFF444444),
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: _scale.clamp(0.5, 3.0),
                            min: 0.5,
                            max: 3.0,
                            onChanged: (val) {
                              setState(() => _scale = val);
                              _applyTransform();
                            },
                          ),
                        ),
                      ),
                      Text('${(_scale * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.open_with, size: 14, color: Color(0xFFFFDE59)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            thumbColor: const Color(0xFFFFDE59),
                            activeTrackColor: const Color(0xFFFFDE59),
                            inactiveTrackColor: const Color(0xFF444444),
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: _dx.clamp(-150.0, 150.0),
                            min: -150,
                            max: 150,
                            onChanged: (val) {
                              setState(() => _dx = val);
                              _applyTransform();
                            },
                          ),
                        ),
                      ),
                      Text('${_dx.toInt()}x', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
