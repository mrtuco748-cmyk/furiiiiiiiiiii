import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../milanote_colors.dart';

enum MilanoteToolType {
  note,
  board,
  column,
  checklist,
  connect,
  colorSwatch,
  image,
  drawing,
}

/// Barra de herramientas flotante estilo Milanote (Dock)
class MilanoteDock extends StatelessWidget {
  final Function(MilanoteToolType) onToolSelected;
  final bool isConnectingMode;
  final VoidCallback onCancelConnect;

  const MilanoteDock({
    super.key,
    required this.onToolSelected,
    this.isConnectingMode = false,
    required this.onCancelConnect,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnectingMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_right_alt, color: Color(0xFF39FF14), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Toca la tarjeta de destino...',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onCancelConnect,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2F36),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white70, size: 16),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: MilanotePalette.dockBackground,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dockButton(
              icon: Icons.note_alt_outlined,
              label: 'Nota',
              type: MilanoteToolType.note,
              color: MilanotePalette.noteYellow,
            ),
            _dockButton(
              icon: Icons.folder_open_rounded,
              label: 'Tablero',
              type: MilanoteToolType.board,
              color: const Color(0xFF00E5FF),
            ),
            _dockButton(
              icon: Icons.view_column_outlined,
              label: 'Columna',
              type: MilanoteToolType.column,
              color: const Color(0xFFFF9800),
            ),
            _dockButton(
              icon: Icons.checklist_rtl_rounded,
              label: 'Tareas',
              type: MilanoteToolType.checklist,
              color: const Color(0xFF39FF14),
            ),
            _dockButton(
              icon: Icons.alt_route_rounded,
              label: 'Conectar',
              type: MilanoteToolType.connect,
              color: const Color(0xFFFF5252),
            ),
            _dockButton(
              icon: Icons.palette_outlined,
              label: 'Color',
              type: MilanoteToolType.colorSwatch,
              color: const Color(0xFFE1BEE7),
            ),
            _dockButton(
              icon: Icons.image_outlined,
              label: 'Imagen',
              type: MilanoteToolType.image,
              color: const Color(0xFFBBDEFB),
            ),
            _dockButton(
              icon: Icons.brush_outlined,
              label: 'Dibujo',
              type: MilanoteToolType.drawing,
              color: const Color(0xFFF8BBD0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dockButton({
    required IconData icon,
    required String label,
    required MilanoteToolType type,
    required Color color,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onToolSelected(type);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
