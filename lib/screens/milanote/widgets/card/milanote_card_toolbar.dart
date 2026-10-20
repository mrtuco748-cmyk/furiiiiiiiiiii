import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../milanote_colors.dart';

/// Barra de herramientas Milanote: Colores rápidos y acciones de tarjeta.
class MilanoteCardToolbar extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final VoidCallback onToggleCardWidth;
  final VoidCallback onStartConnect;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<Color> onSelectColor;

  const MilanoteCardToolbar({
    super.key,
    required this.isDark,
    required this.textColor,
    required this.onToggleCardWidth,
    required this.onStartConnect,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSelectColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _colorDot(MilanotePalette.noteYellow),
              _colorDot(MilanotePalette.notePeach),
              _colorDot(MilanotePalette.notePink),
              _colorDot(MilanotePalette.noteBlue),
              _colorDot(MilanotePalette.noteMint),
              _colorDot(MilanotePalette.notePurple),
              _colorDot(MilanotePalette.noteCharcoal),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: onToggleCardWidth,
                child: Tooltip(
                  message: 'Cambiar Ancho',
                  child: Icon(
                    Icons.aspect_ratio_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onStartConnect,
                child: Tooltip(
                  message: 'Conectar con otra tarjeta',
                  child: Icon(
                    Icons.alt_route_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDuplicate,
                child: Tooltip(
                  message: 'Duplicar tarjeta',
                  child: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Tooltip(
                  message: 'Eliminar tarjeta',
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFFF5252),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelectColor(color);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
