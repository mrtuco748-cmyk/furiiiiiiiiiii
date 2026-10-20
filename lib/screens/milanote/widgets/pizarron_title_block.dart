import 'package:flutter/material.dart';
import '../models/active_text_target.dart';
import '../models/note_style_config.dart';
import 'pizarron_formatted_block.dart';

/// Bloque del título de la tarjeta de nota del Pizarrón.
class PizarronTitleBlock extends StatelessWidget {
  final NoteStyleConfig cfg;
  final bool isEditing;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ActiveTextTarget activeTarget;
  final VoidCallback onFocusRequested;
  final VoidCallback onSubmitted;
  final VoidCallback onChanged;

  const PizarronTitleBlock({
    super.key,
    required this.cfg,
    required this.isEditing,
    required this.controller,
    required this.focusNode,
    required this.activeTarget,
    required this.onFocusRequested,
    required this.onSubmitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = PizarronPalette.parseHex(cfg.titleColor);
    final style = PizarronFontCatalog.resolveFont(
      cfg.titleFont,
      fontSize: cfg.titleSize,
      color: titleColor,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );

    final isFocusedTitle = isEditing && activeTarget.isTitle;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onFocusRequested,
      child: PizarronFormattedBlockContainer(
        format: cfg.titleFormat,
        accentColor: titleColor,
        isHighlightedTarget: isFocusedTitle,
        child: IgnorePointer(
          ignoring: !isEditing,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: !isEditing,
            textAlign: cfg.textAlign,
            style: style,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: isEditing ? 'Título...' : '',
              hintStyle: style.copyWith(
                color: titleColor.withValues(alpha: 0.32),
              ),
            ),
            onChanged: (_) => onChanged(),
            onEditingComplete: onSubmitted,
          ),
        ),
      ),
    );
  }
}
