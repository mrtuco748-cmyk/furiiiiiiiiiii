import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _shapes = [
  ('Rectángulo', Icons.rectangle_outlined),
  ('Cuadrado', Icons.square_outlined),
  ('Círculo', Icons.circle_outlined),
  ('Óvalo', Icons.egg_outlined),
  ('Diamante', Icons.diamond_outlined),
  ('Hexágono', Icons.hexagon_outlined),
];

class NoteShapeEditor extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onShapeSelected;

  const NoteShapeEditor({
    super.key,
    required this.selected,
    required this.onShapeSelected,
  });

  @override
  State<NoteShapeEditor> createState() => _NoteShapeEditorState();
}

class _NoteShapeEditorState extends State<NoteShapeEditor> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  void didUpdateWidget(covariant NoteShapeEditor old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      setState(() => _current = widget.selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final s in _shapes)
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _current = s.$1);
            widget.onShapeSelected(s.$1);
            Navigator.of(context).pop();
          },
          child: _shapeTile(s.$1, s.$2),
        ),
    ]);
  }

  Widget _shapeTile(String label, IconData icon) {
    final isSel = _current == label;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isSel ? const Color(0xFF39FF14) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSel ? const Color(0xFF39FF14) : const Color(0xFF1A1A1A),
          width: isSel ? 2.5 : 1.5,
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: isSel ? const Color(0xFF0A0A0A) : Colors.white70, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          color: isSel ? const Color(0xFF0A0A0A) : Colors.white54,
          fontFamily: 'monospace', fontSize: 9)),
      ]),
    );
  }
}
