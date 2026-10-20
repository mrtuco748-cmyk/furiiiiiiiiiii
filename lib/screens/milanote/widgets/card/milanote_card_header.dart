import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

IconData milanoteTypeIcon(String type) {
  switch (type) {
    case 'board':
      return Icons.folder_rounded;
    case 'column':
      return Icons.view_column_rounded;
    case 'checklist':
      return Icons.checklist_rounded;
    case 'colorSwatch':
      return Icons.palette_rounded;
    case 'image':
      return Icons.image_rounded;
    case 'drawing':
      return Icons.brush_rounded;
    default:
      return Icons.sticky_note_2_rounded;
  }
}

String milanoteDefaultTitleForType(String type) {
  switch (type) {
    case 'board':
      return 'Sub-Tablero';
    case 'column':
      return 'Columna';
    case 'checklist':
      return 'Lista de Tareas';
    case 'colorSwatch':
      return 'Paleta de Color';
    case 'image':
      return 'Foto / Imagen';
    case 'drawing':
      return 'Boceto';
    default:
      return 'Nota';
  }
}

/// Encabezado estático / arrastrable para el modo lectura
class MilanoteCardDraggableHeader extends StatelessWidget {
  final String type;
  final String title;
  final Color textColor;
  final bool isDark;
  final bool isSelected;

  const MilanoteCardDraggableHeader({
    super.key,
    required this.type,
    required this.title,
    required this.textColor,
    required this.isDark,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Icon(
            milanoteTypeIcon(type),
            size: 15,
            color: textColor.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.isNotEmpty ? title : milanoteDefaultTitleForType(type),
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            Icon(
              Icons.touch_app_rounded,
              size: 14,
              color: textColor.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }
}

/// Encabezado interactivo con TextField y botón "Listo"
class MilanoteCardEditingHeader extends StatelessWidget {
  final String type;
  final TextEditingController titleCtrl;
  final Color textColor;
  final bool isDark;
  final VoidCallback onFinishEditing;
  final VoidCallback onFieldChanged;
  final VoidCallback onDragStart;
  final Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback onDragEnd;

  const MilanoteCardEditingHeader({
    super.key,
    required this.type,
    required this.titleCtrl,
    required this.textColor,
    required this.isDark,
    required this.onFinishEditing,
    required this.onFieldChanged,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onDragStart(),
      onPanUpdate: onDragUpdate,
      onPanEnd: (_) => onDragEnd(),
      onPanCancel: onDragEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
        ),
        child: Row(
          children: [
            Icon(
              milanoteTypeIcon(type),
              size: 15,
              color: textColor.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: titleCtrl,
                style: GoogleFonts.plusJakartaSans(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: milanoteDefaultTitleForType(type),
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => onFieldChanged(),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onFinishEditing,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: textColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Listo',
                      style: GoogleFonts.plusJakartaSans(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
