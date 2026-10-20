import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/board_element.dart';

/// Imagen de Milanote: visualización y edición
class MilanoteImageBody extends StatelessWidget {
  final BoardElement element;
  final TextEditingController contentCtrl;
  final Color textColor;
  final bool isEditing;
  final Function(BoardElement) onUpdate;
  final VoidCallback onFieldChanged;

  const MilanoteImageBody({
    super.key,
    required this.element,
    required this.contentCtrl,
    required this.textColor,
    required this.isEditing,
    required this.onUpdate,
    required this.onFieldChanged,
  });

  Future<void> _pickImage(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 80,
    );
    if (file == null) return;

    final updatedData = Map<String, dynamic>.from(element.data);
    updatedData['imagePath'] = file.path;

    onUpdate(element.copyWith(
      data: updatedData,
      content: file.path,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final imgPath = element.data['imagePath']?.toString() ?? element.content;
    final hasImage = imgPath.isNotEmpty && File(imgPath).existsSync();

    final imageContainer = Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isEditing ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(File(imgPath), fit: BoxFit.cover)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEditing ? Icons.add_photo_alternate_rounded : Icons.image_rounded,
                    size: 32,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEditing ? 'Toca para subir imagen' : 'Sin imagen (Toca para editar)',
                    style: GoogleFonts.plusJakartaSans(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isEditing)
          GestureDetector(onTap: () => _pickImage(context), child: imageContainer)
        else
          imageContainer,
        const SizedBox(height: 6),
        if (isEditing)
          TextField(
            controller: contentCtrl,
            style: GoogleFonts.plusJakartaSans(
              color: textColor.withValues(alpha: 0.9),
              fontSize: 11,
            ),
            decoration: InputDecoration(
              hintText: 'Pie de foto / nota...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: textColor.withValues(alpha: 0.4),
                fontSize: 11,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => onFieldChanged(),
          )
        else if (contentCtrl.text.isNotEmpty)
          Text(
            contentCtrl.text,
            style: GoogleFonts.plusJakartaSans(
              color: textColor.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

/// Boceto creativo
class MilanoteDrawingBody extends StatelessWidget {
  final Color textColor;
  const MilanoteDrawingBody({super.key, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gesture_rounded,
              size: 34,
              color: textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Boceto creativo',
              style: GoogleFonts.plusJakartaSans(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Columna Milanote
class MilanoteColumnBody extends StatelessWidget {
  final Color textColor;
  const MilanoteColumnBody({super.key, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: Center(
        child: Text(
          'Columna Milanote\nOrganiza elementos arrastrándolos aquí',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: textColor.withValues(alpha: 0.4),
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
