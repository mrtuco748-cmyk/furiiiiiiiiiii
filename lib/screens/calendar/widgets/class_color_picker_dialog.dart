import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/tap_tile.dart';

const Color _c = Color(0xFF00D4FF);
const Color _near = Color(0xFF1A1A1A);

const List<Color> classColors = [
  Color(0xFF7B2D8E), Color(0xFF4CAF50), Color(0xFFE53935), Color(0xFFFF9800),
  Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFF00BCD4), Color(0xFF795548),
  Color(0xFFE91E63), Color(0xFF3F51B5), Color(0xFF009688), Color(0xFF673AB7),
  Color(0xFFFF5722), Color(0xFF607D8B), Color(0xFFCDDC39), Color(0xFF8BC34A),
];

class ClassColorPickerDialog extends StatefulWidget {
  const ClassColorPickerDialog({super.key});

  @override
  State<ClassColorPickerDialog> createState() => _ClassColorPickerDialogState();
}

class _ClassColorPickerDialogState extends State<ClassColorPickerDialog> {
  int _selected = 0xFF7B2D8E;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _near,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _c, width: 4),
      ),
      title: Text('Elegir color', style: GoogleFonts.bangers(color: _c, fontSize: 15)),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: classColors.map((c) => GestureDetector(
          onTap: () {
            _selected = c.toARGB32();
            Navigator.pop(context, _selected);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selected == c.toARGB32() ? _c : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        )).toList(),
      ),
      actions: [
        TapTile(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _near,
                border: Border.all(color: _c, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 22),
            ),
          ),
        ),
      ],
    );
  }
}
