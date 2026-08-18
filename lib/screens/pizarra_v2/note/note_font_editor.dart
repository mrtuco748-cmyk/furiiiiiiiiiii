import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'note_common_color_wheel.dart';

const _googleFonts = [
  'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Oswald', 'Raleway',
  'Poppins', 'Dancing Script', 'Pacifico', 'Permanent Marker', 'Caveat', 'Indie Flower',
];

const _fontColors = [
  Colors.white, Color(0xFFB0B0B0), Color(0xFF444444),
  Color(0xFFFF6B00), Color(0xFF00D4FF),
];

class NoteFontEditor extends StatefulWidget {
  final String currentFont;
  final Color currentFontColor;
  final double currentFontSize;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<Color> onFontColorChanged;
  final ValueChanged<double> onFontSizeChanged;

  const NoteFontEditor({
    super.key,
    this.currentFont = 'Roboto',
    this.currentFontColor = Colors.white,
    this.currentFontSize = 14,
    required this.onFontChanged,
    required this.onFontColorChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<NoteFontEditor> createState() => _NoteFontEditorState();
}

class _NoteFontEditorState extends State<NoteFontEditor> {
  late String _font;
  late Color _color;
  late double _size;

  @override
  void initState() {
    super.initState();
    _font = widget.currentFont;
    _color = widget.currentFontColor;
    _size = widget.currentFontSize;
  }

  @override
  void didUpdateWidget(covariant NoteFontEditor old) {
    super.didUpdateWidget(old);
    if (old.currentFont != widget.currentFont) setState(() => _font = widget.currentFont);
    if (old.currentFontColor != widget.currentFontColor) setState(() => _color = widget.currentFontColor);
    if (old.currentFontSize != widget.currentFontSize) setState(() => _size = widget.currentFontSize);
  }

  static const _sec = TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Fuente', style: _sec),
      const SizedBox(height: 8),
      _buildFontList(),
      const SizedBox(height: 14),
      const Text('Color', style: _sec),
      const SizedBox(height: 8),
      _buildColors(),
      const SizedBox(height: 14),
      const Text('Tamaño', style: _sec),
      const SizedBox(height: 8),
      _buildSizeSlider(),
    ]);
  }

  Widget _buildFontList() {
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final f in _googleFonts) _fontChip(f),
    ]);
  }

  Widget _fontChip(String f) {
    final active = _font == f;
    final fontStyle = GoogleFonts.getFont(f, fontSize: 13);
    return GestureDetector(
      onTap: () {
        setState(() => _font = f);
        widget.onFontChanged(f);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF9D00FF) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF9D00FF) : const Color(0xFF333333), width: active ? 2.5 : 1.5),
        ),
        child: Text(f, style: fontStyle.copyWith(
          color: active ? const Color(0xFF0A0A0A) : Colors.white70,
        )),
      ),
    );
  }

  Widget _buildColors() {
    return Row(children: [
      for (final c in _fontColors) ...[
        _colorDot(c),
        const SizedBox(width: 10),
      ],
      _addCustomColor(),
    ]);
  }

  Widget _colorDot(Color c) {
    final active = _color.toARGB32() == c.toARGB32();
    return GestureDetector(
      onTap: () {
        setState(() => _color = c);
        widget.onFontColorChanged(c);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: c, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF9D00FF) : const Color(0xFF333333),
            width: active ? 3 : 2),
        ),
        child: active ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
      ),
    );
  }

  Widget _addCustomColor() {
    return GestureDetector(
      onTap: () => _pickCustomFontColor(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF333333), width: 2)),
        child: const Center(
          child: Text('+', style: TextStyle(color: Colors.white70, fontSize: 20,
            fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
      ),
    );
  }

  void _pickCustomFontColor() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          Color picked = _color;
          return Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0A0A0A), width: 2)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SimpleColorWheel(initialColor: _color, onColorChanged: (c) => setD(() => picked = c)),
                const SizedBox(height: 12),
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5)),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontFamily: 'monospace')),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _color = picked);
                      widget.onFontColorChanged(picked);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF00D4FF), borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00D4FF), width: 1.5)),
                      child: const Text('Aceptar', style: TextStyle(color: Color(0xFF0A0A0A),
                        fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSizeSlider() {
    return Row(children: [
      GestureDetector(
        onTap: () { final v = (_size - 1).clamp(8.0, 48.0).toDouble();
          setState(() => _size = v); widget.onFontSizeChanged(v); },
        child: Container(width: 34, height: 34,
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF333333), width: 1.5)),
          child: const Icon(Icons.remove, color: Colors.white70, size: 16)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: const Color(0xFF9D00FF),
            inactiveTrackColor: const Color(0xFF333333),
            thumbColor: const Color(0xFF9D00FF),
            overlayColor: const Color(0xFF9D00FF).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _size, min: 8, max: 48,
            onChanged: (v) { setState(() => _size = v); widget.onFontSizeChanged(v); },
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () { final v = (_size + 1).clamp(8.0, 48.0).toDouble();
          setState(() => _size = v); widget.onFontSizeChanged(v); },
        child: Container(width: 34, height: 34,
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF333333), width: 1.5)),
          child: const Icon(Icons.add, color: Colors.white70, size: 16)),
      ),
      const SizedBox(width: 8),
      Text('${_size.round()}px', style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13)),
    ]);
  }
}
