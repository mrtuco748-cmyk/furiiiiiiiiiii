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
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _buildSliderRow(IconData icon, Color color, double val, double min, double max, ValueChanged<double> onChange, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbColor: color,
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xFF444444),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(value: val, min: min, max: max, onChanged: onChange),
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDrawing = widget.panel.drawingPngBase64 != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sub-controles flotantes a la izquierda del dock si están activos
        if (_showBorderControls) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333333), width: 1.2),
            ),
            child: ComicPanelQuickBorderRow(
              currentBorderWidth: widget.panel.borderWidth,
              currentBorderColor: widget.panel.borderColor,
              onSelect: (w, c) => widget.onQuickBorder?.call(w, c),
            ),
          ),
          const SizedBox(width: 8),
        ],

        if (_showTransformControls && hasDrawing) ...[
          Container(
            width: 190,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333333), width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSliderRow(Icons.aspect_ratio, const Color(0xFFFF00FF), _scale.clamp(0.5, 3.0), 0.5, 3.0, (v) {
                  setState(() => _scale = v);
                  _applyTransform();
                }, '${(_scale * 100).toInt()}%'),
                _buildSliderRow(Icons.open_with, const Color(0xFFFFDE59), _dx.clamp(-150.0, 150.0), -150.0, 150.0, (v) {
                  setState(() => _dx = v);
                  _applyTransform();
                }, '${_dx.toInt()}x'),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Dock vertical de acciones estilo Infinite Painter (derecha de la pantalla)
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF333333), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Dibujar
                _buildIconButton(
                  bg: const Color(0xFF00D4FF),
                  child: const CreativeIcon('pen_gpen', color: Colors.black, size: 20, fallback: Icons.brush),
                  onTap: widget.onDraw,
                ),
                const SizedBox(height: 6),

                // 2. Insertar dibujo guardado
                _buildIconButton(
                  bg: const Color(0xFF39FF14),
                  child: const Icon(Icons.palette_outlined, color: Colors.black, size: 20),
                  onTap: widget.onInsert,
                ),
                const SizedBox(height: 6),

                // 3. Galería
                if (widget.onGallery != null) ...[
                  _buildIconButton(
                    bg: const Color(0xFF282828),
                    child: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF00D4FF), size: 20),
                    onTap: widget.onGallery!,
                  ),
                  const SizedBox(height: 6),
                ],

                // 4. Cortar
                if (widget.onSlice != null) ...[
                  _buildIconButton(
                    bg: const Color(0xFFFF6B00),
                    child: const Icon(Icons.content_cut, color: Colors.black, size: 20),
                    onTap: widget.onSlice!,
                  ),
                  const SizedBox(height: 6),
                ],

                // 5. Personalizar
                _buildIconButton(
                  bg: const Color(0xFF282828),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF5AC8FA), size: 20),
                  onTap: widget.onCustomize,
                ),
                const SizedBox(height: 6),

                // 6. Borde
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
                const SizedBox(height: 6),

                // Si tiene dibujo, encuadre y limpiar
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
                  const SizedBox(height: 6),
                  _buildIconButton(
                    bg: const Color(0xFF2E1717),
                    child: const Icon(Icons.layers_clear, color: Color(0xFFFF453A), size: 20),
                    onTap: widget.onClear,
                  ),
                  const SizedBox(height: 6),
                ],

                // Eliminar viñeta
                if (widget.onDelete != null) ...[
                  _buildIconButton(
                    bg: const Color(0xFF2E1717),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFFF453A), size: 20),
                    onTap: widget.onDelete!,
                  ),
                  const SizedBox(height: 6),
                ],

                // Cerrar / Deseleccionar
                _buildIconButton(
                  bg: const Color(0xFF282828),
                  child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
