import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'note_color_wheel.dart';

const _brutalistColors = [
  Color(0xFFFF6B00),
  Color(0xFFFF00FF),
  Color(0xFF00D4FF),
  Color(0xFF39FF14),
  Color(0xFF9D00FF),
];

class NoteColorEditor extends StatefulWidget {
  final Color currentColor;
  final List<Color> lastCustomColors;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<List<Color>> onCustomColorsChanged;

  const NoteColorEditor({
    super.key,
    required this.currentColor,
    this.lastCustomColors = const [],
    required this.onColorSelected,
    required this.onCustomColorsChanged,
  });

  @override
  State<NoteColorEditor> createState() => _NoteColorEditorState();
}

class _NoteColorEditorState extends State<NoteColorEditor> {
  late Color _sel;
  late List<Color> _custom;

  @override
  void initState() {
    super.initState();
    _sel = widget.currentColor;
    _custom = List.from(widget.lastCustomColors);
  }

  @override
  void didUpdateWidget(covariant NoteColorEditor old) {
    super.didUpdateWidget(old);
    if (old.currentColor != widget.currentColor) {
      setState(() => _sel = widget.currentColor);
    }
  }

  void _pick(Color c) {
    HapticFeedback.selectionClick();
    setState(() => _sel = c);
    widget.onColorSelected(c);
    Navigator.of(context).pop();
  }

  void _pickCustom(Color c) {
    setState(() => _sel = c);
    widget.onColorSelected(c);
    _custom.insert(0, c);
    if (_custom.length > 5) _custom.removeLast();
    widget.onCustomColorsChanged(List.from(_custom));
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Colores base',
        style: TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)),
      const SizedBox(height: 8),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final c in _brutalistColors) _swatch(c),
        _addCustomBtn(),
      ]),
      if (_custom.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Recientes',
          style: TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 11)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final c in _custom) _swatch(c, isCustom: true),
        ]),
      ],
      const SizedBox(height: 14),
      _preview(),
    ]);
  }

  Widget _swatch(Color c, {bool isCustom = false}) {
    final eq = c.toARGB32() == _sel.toARGB32();
    return GestureDetector(
      onTap: () => isCustom ? _pickCustom(c) : _pick(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: eq ? Colors.white : c, width: eq ? 3 : 2),
          boxShadow: eq ? [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 8)] : null,
        ),
        child: eq ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }

  Widget _addCustomBtn() {
    return GestureDetector(
      onTap: _showWheel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333), width: 2),
        ),
        child: const Center(child: Text('+', style: TextStyle(
          color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
      ),
    );
  }

  void _showWheel() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          Color picked = _sel;
          return Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                NoteColorWheel(
                  initialColor: picked,
                  onColorChanged: (c) => setDialog(() => picked = c),
                ),
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
                      _pickCustom(picked);
                      Navigator.of(ctx)
                        ..pop()
                        ..pop();
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

  Widget _preview() {
    return Row(children: [
      Container(width: 28, height: 28,
        decoration: BoxDecoration(color: _sel, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _sel, width: 1.5))),
      const SizedBox(width: 10),
      Text('#${_sel.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)),
      const Spacer(),
      Text('seleccionado', style: TextStyle(color: _sel, fontFamily: 'monospace', fontSize: 10)),
    ]);
  }
}
