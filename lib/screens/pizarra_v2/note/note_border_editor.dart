import 'package:flutter/material.dart';
import 'note_common_color_wheel.dart';

const _borderTypes = ['Sólido', 'Punteado', 'Dashed', 'Doble', 'Ondulado', 'Relieve'];

class NoteBorderEditor extends StatefulWidget {
  final bool borderEnabled;
  final Color borderColor;
  final String borderType;
  final double borderWidth;
  final double borderSpacing;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onSpacingChanged;

  const NoteBorderEditor({
    super.key,
    this.borderEnabled = false,
    this.borderColor = const Color(0xFF39FF14),
    this.borderType = 'Sólido',
    this.borderWidth = 2,
    this.borderSpacing = 4,
    required this.onEnabledChanged,
    required this.onColorChanged,
    required this.onTypeChanged,
    required this.onWidthChanged,
    required this.onSpacingChanged,
  });

  @override
  State<NoteBorderEditor> createState() => _NoteBorderEditorState();
}

class _NoteBorderEditorState extends State<NoteBorderEditor> {
  late bool _on;
  late Color _col;
  late String _type;
  late double _w;
  late double _spacing;

  @override
  void initState() {
    super.initState();
    _on = widget.borderEnabled;
    _col = widget.borderColor;
    _type = widget.borderType;
    _w = widget.borderWidth;
    _spacing = widget.borderSpacing;
  }

  @override
  void didUpdateWidget(covariant NoteBorderEditor old) {
    super.didUpdateWidget(old);
    if (old.borderEnabled != widget.borderEnabled) setState(() => _on = widget.borderEnabled);
    if (old.borderColor != widget.borderColor) setState(() => _col = widget.borderColor);
    if (old.borderType != widget.borderType) setState(() => _type = widget.borderType);
    if (old.borderWidth != widget.borderWidth) setState(() => _w = widget.borderWidth);
    if (old.borderSpacing != widget.borderSpacing) setState(() => _spacing = widget.borderSpacing);
  }

  static const _sec = TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Borde', style: _sec),
        const Spacer(),
        GestureDetector(
          onTap: () {
            setState(() => _on = !_on);
            widget.onEnabledChanged(_on);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46, height: 26, padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _on ? const Color(0xFF39FF14) : const Color(0xFF333333),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: _on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(width: 20, height: 20,
              decoration: BoxDecoration(
                color: _on ? const Color(0xFF0A0A0A) : Colors.white38,
                shape: BoxShape.circle)),
          ),
        ),
      ]),
      if (_on) ...[
        const SizedBox(height: 14),
        const Text('Color', style: _sec),
        const SizedBox(height: 8),
        _buildColorRow(),
        const SizedBox(height: 14),
        const Text('Tipo', style: _sec),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in _borderTypes) _typeChip(t),
        ]),
        const SizedBox(height: 14),
        const Text('Grosor', style: _sec),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                activeTrackColor: _col, inactiveTrackColor: const Color(0xFF333333),
                thumbColor: _col, overlayColor: _col.withValues(alpha: 0.2),
              ),
              child: Slider(value: _w, min: 1, max: 10,
                onChanged: (v) { setState(() => _w = v); widget.onWidthChanged(v); }),
            ),
          ),
          SizedBox(width: 32,
            child: Text('${_w.round()}px', style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 10))),
        ]),
        const SizedBox(height: 10),
        const Text('Espaciado', style: _sec),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                activeTrackColor: _col, inactiveTrackColor: const Color(0xFF333333),
                thumbColor: _col.withValues(alpha: 0.5), overlayColor: _col.withValues(alpha: 0.2),
              ),
              child: Slider(value: _spacing, min: 1, max: 20,
                onChanged: (v) { setState(() => _spacing = v); widget.onSpacingChanged(v); }),
            ),
          ),
          SizedBox(width: 32,
            child: Text('${_spacing.round()}px', style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 10))),
        ]),
      ],
    ]);
  }

  Widget _buildColorRow() {
    return Row(children: [
      _colorDot(const Color(0xFF39FF14)),
      const SizedBox(width: 10),
      _colorDot(const Color(0xFFFF6B00)),
      const SizedBox(width: 10),
      _colorDot(const Color(0xFF00D4FF)),
      const SizedBox(width: 10),
      _colorDot(const Color(0xFFFF00FF)),
      const SizedBox(width: 10),
      _colorDot(const Color(0xFF9D00FF)),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: () => _pickCustomBorderColor(),
        child: Container(width: 30, height: 30,
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF333333), width: 2)),
          child: const Center(child: Text('+', style: TextStyle(color: Colors.white70, fontSize: 18,
            fontWeight: FontWeight.bold, fontFamily: 'monospace')))),
      ),
    ]);
  }

  Widget _colorDot(Color c) {
    final active = _col.toARGB32() == c.toARGB32();
    return GestureDetector(
      onTap: () { setState(() => _col = c); widget.onColorChanged(c); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: c, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? Colors.white : c, width: active ? 3 : 2)),
        child: active ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
      ),
    );
  }

  Widget _typeChip(String t) {
    final active = _type == t;
    return GestureDetector(
      onTap: () { setState(() => _type = t); widget.onTypeChanged(t); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _col : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _col : const Color(0xFF333333), width: active ? 2.5 : 1.5),
        ),
        child: Text(t, style: TextStyle(
          color: active ? const Color(0xFF0A0A0A) : Colors.white70,
          fontFamily: 'monospace', fontSize: 11)),
      ),
    );
  }

  void _pickCustomBorderColor() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          Color picked = _col;
          return Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0A0A0A), width: 2)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SimpleColorWheel(initialColor: _col, onColorChanged: (c) => setD(() => picked = c)),
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
                      setState(() => _col = picked);
                      widget.onColorChanged(picked);
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
}

