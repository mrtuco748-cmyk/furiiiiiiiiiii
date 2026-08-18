import 'package:flutter/material.dart';
import 'note_color_wheel.dart';

class GradientColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onPicked;

  const GradientColorPicker({
    super.key,
    required this.initialColor,
    required this.onPicked,
  });

  @override
  State<GradientColorPicker> createState() => _GradientColorPickerState();
}

class _GradientColorPickerState extends State<GradientColorPicker> {
  late Color _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          NoteColorWheel(
            initialColor: _picked,
            onColorChanged: (c) => setState(() => _picked = c),
          ),
          const SizedBox(height: 12),
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                ),
                child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white70, fontFamily: 'monospace')),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                widget.onPicked(_picked);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00D4FF), width: 1.5),
                ),
                child: const Text('Aceptar',
                  style: TextStyle(color: Color(0xFF0A0A0A),
                    fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
