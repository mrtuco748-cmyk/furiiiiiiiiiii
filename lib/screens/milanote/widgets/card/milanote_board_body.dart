import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/board_element.dart';
import '../../milanote_colors.dart';

/// Sub-Tablero de Milanote: vista y edición
class MilanoteBoardBody extends StatelessWidget {
  final BoardElement element;
  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final Color textColor;
  final bool isEditing;
  final Function(int subBoardId, String title)? onOpenSubBoard;
  final VoidCallback onFieldChanged;

  const MilanoteBoardBody({
    super.key,
    required this.element,
    required this.titleCtrl,
    required this.contentCtrl,
    required this.textColor,
    required this.isEditing,
    required this.onOpenSubBoard,
    required this.onFieldChanged,
  });

  void _openBoard() {
    if (onOpenSubBoard != null && element.id != null) {
      HapticFeedback.mediumImpact();
      onOpenSubBoard!(
        element.id!,
        titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Sub-Tablero',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = contentCtrl.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isEditing) ...[
          TextField(
            controller: contentCtrl,
            maxLines: 2,
            style: GoogleFonts.plusJakartaSans(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: 'Descripción del tablero...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: textColor.withValues(alpha: 0.4),
                fontSize: 12,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => onFieldChanged(),
          ),
          const SizedBox(height: 10),
        ] else if (text.isNotEmpty) ...[
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _openBoard,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_open_rounded,
                  size: 16,
                  color: Color(0xFF00E5FF),
                ),
                const SizedBox(width: 6),
                Text(
                  'Entrar al Tablero',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Paleta de color interactiva
class MilanoteColorSwatchBody extends StatelessWidget {
  final BoardElement element;
  final Color textColor;
  final Function(BoardElement) onUpdate;

  const MilanoteColorSwatchBody({
    super.key,
    required this.element,
    required this.textColor,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final hexCode = element.data['hex']?.toString() ?? element.color;
    final parsed = MilanotePalette.parseHex(hexCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: parsed,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hexCode.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.firaCode(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: MilanotePalette.swatchColors.take(8).map((c) {
            return GestureDetector(
              onTap: () {
                final hex = MilanotePalette.toHex(c);
                final updatedData = Map<String, dynamic>.from(element.data);
                updatedData['hex'] = hex;
                onUpdate(element.copyWith(
                  data: updatedData,
                  color: hex,
                ));
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
