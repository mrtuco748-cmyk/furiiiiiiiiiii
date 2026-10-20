import 'package:flutter/material.dart';
import '../../../widgets/tap_tile.dart';

const Color _near = Color(0xFF1A1A1A);

class ClassDeleteConfirmDialog extends StatelessWidget {
  const ClassDeleteConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const ClassDeleteConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _near,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.red, width: 4),
      ),
      title: const Icon(Icons.delete_forever, color: Colors.red, size: 40),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TapTile(
          onTap: () => Navigator.pop(context, false),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _near,
                border: Border.all(color: _near, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
              ),
              child: const Icon(Icons.close, color: Color(0xFF00D4FF), size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TapTile(
          onTap: () => Navigator.pop(context, true),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red,
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
              ),
              child: const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 24),
            ),
          ),
        ),
      ],
    );
  }
}
