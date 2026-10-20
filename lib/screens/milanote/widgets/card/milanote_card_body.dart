import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/board_element.dart';
import 'milanote_board_body.dart';
import 'milanote_checklist_body.dart';
import 'milanote_image_body.dart';

/// Renderizador del cuerpo de tarjeta de Milanote según tipo y modo de edición
class MilanoteCardBody extends StatelessWidget {
  final BoardElement element;
  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final Color textColor;
  final bool isEditing;
  final Function(BoardElement) onUpdate;
  final Function(int subBoardId, String title)? onOpenSubBoard;
  final VoidCallback onFieldChanged;

  const MilanoteCardBody({
    super.key,
    required this.element,
    required this.titleCtrl,
    required this.contentCtrl,
    required this.textColor,
    required this.isEditing,
    required this.onUpdate,
    required this.onOpenSubBoard,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return _buildEditingBody();
    } else {
      return _buildViewBody();
    }
  }

  Widget _buildViewBody() {
    switch (element.type) {
      case 'board':
        return MilanoteBoardBody(
          element: element,
          titleCtrl: titleCtrl,
          contentCtrl: contentCtrl,
          textColor: textColor,
          isEditing: false,
          onOpenSubBoard: onOpenSubBoard,
          onFieldChanged: onFieldChanged,
        );
      case 'checklist':
        return MilanoteChecklistViewBody(
          element: element,
          textColor: textColor,
          onUpdate: onUpdate,
        );
      case 'colorSwatch':
        return MilanoteColorSwatchBody(
          element: element,
          textColor: textColor,
          onUpdate: onUpdate,
        );
      case 'column':
        return MilanoteColumnBody(textColor: textColor);
      case 'drawing':
        return MilanoteDrawingBody(textColor: textColor);
      case 'image':
        return MilanoteImageBody(
          element: element,
          contentCtrl: contentCtrl,
          textColor: textColor,
          isEditing: false,
          onUpdate: onUpdate,
          onFieldChanged: onFieldChanged,
        );
      case 'note':
      default:
        return _buildViewNoteBody();
    }
  }

  Widget _buildEditingBody() {
    switch (element.type) {
      case 'board':
        return MilanoteBoardBody(
          element: element,
          titleCtrl: titleCtrl,
          contentCtrl: contentCtrl,
          textColor: textColor,
          isEditing: true,
          onOpenSubBoard: onOpenSubBoard,
          onFieldChanged: onFieldChanged,
        );
      case 'checklist':
        return MilanoteChecklistEditingBody(
          element: element,
          textColor: textColor,
          onUpdate: onUpdate,
        );
      case 'colorSwatch':
        return MilanoteColorSwatchBody(
          element: element,
          textColor: textColor,
          onUpdate: onUpdate,
        );
      case 'column':
        return MilanoteColumnBody(textColor: textColor);
      case 'drawing':
        return MilanoteDrawingBody(textColor: textColor);
      case 'image':
        return MilanoteImageBody(
          element: element,
          contentCtrl: contentCtrl,
          textColor: textColor,
          isEditing: true,
          onUpdate: onUpdate,
          onFieldChanged: onFieldChanged,
        );
      case 'note':
      default:
        return _buildEditingNoteBody();
    }
  }

  Widget _buildViewNoteBody() {
    final text = contentCtrl.text;
    final hasText = text.trim().isNotEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.topLeft,
      child: Text(
        hasText ? text : 'Toca una vez para editar...',
        style: GoogleFonts.plusJakartaSans(
          color: hasText
              ? textColor.withValues(alpha: 0.9)
              : textColor.withValues(alpha: 0.4),
          fontSize: 13,
          height: 1.45,
          fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildEditingNoteBody() {
    return TextField(
      controller: contentCtrl,
      autofocus: true,
      maxLines: null,
      minLines: 3,
      style: GoogleFonts.plusJakartaSans(
        color: textColor.withValues(alpha: 0.95),
        fontSize: 13,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText: 'Escribe aquí tu nota directamente...',
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textColor.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (_) => onFieldChanged(),
    );
  }
}
