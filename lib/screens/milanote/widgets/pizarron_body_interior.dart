import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/active_text_target.dart';
import '../models/note_style_config.dart';
import 'pizarron_formatted_block.dart';
import 'pizarron_inline_image.dart';

/// Área de contenido y párrafos de la tarjeta de nota del Pizarrón.
class PizarronBodyInterior extends StatelessWidget {
  final NoteStyleConfig cfg;
  final bool isEditing;
  final List<TextEditingController> paragraphControllers;
  final List<FocusNode> paragraphFocusNodes;
  final ActiveTextTarget activeTarget;
  final Uint8List? cachedInlineBytes;
  final double cardHeight;
  final void Function(int index, String value) onParagraphChanged;
  final void Function(ActiveTextTarget target) onTargetFocused;
  final VoidCallback onBodyAreaTapped;

  const PizarronBodyInterior({
    super.key,
    required this.cfg,
    required this.isEditing,
    required this.paragraphControllers,
    required this.paragraphFocusNodes,
    required this.activeTarget,
    required this.cachedInlineBytes,
    required this.cardHeight,
    required this.onParagraphChanged,
    required this.onTargetFocused,
    required this.onBodyAreaTapped,
  });

  CrossAxisAlignment _crossAxisForAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImg = cachedInlineBytes != null;
    final imgPos = cfg.inlineImagePosition;
    final imgHeight =
        (cardHeight * cfg.inlineImageHeightRatio).clamp(48.0, cardHeight * 0.55);

    final paraCount = paragraphControllers.length;
    final midSplit = (paraCount / 2).ceil();

    return Column(
      crossAxisAlignment: _crossAxisForAlign(cfg.textAlign),
      mainAxisSize: MainAxisSize.max,
      children: [
        if (hasImg && imgPos == InlineImagePosition.aboveBody) ...[
          PizarronInlineImageWidget(
            imageBytes: cachedInlineBytes,
            height: imgHeight,
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBodyAreaTapped,
            child: SingleChildScrollView(
              physics: isEditing
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: _crossAxisForAlign(cfg.textAlign),
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < paraCount; i++) ...[
                    if (hasImg &&
                        imgPos == InlineImagePosition.middleBody &&
                        i == midSplit) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: PizarronInlineImageWidget(
                          imageBytes: cachedInlineBytes,
                          height: imgHeight,
                        ),
                      ),
                    ],
                    _buildParagraphBlock(i),
                  ],
                  if (hasImg &&
                      imgPos == InlineImagePosition.middleBody &&
                      paraCount <= 1) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: PizarronInlineImageWidget(
                        imageBytes: cachedInlineBytes,
                        height: imgHeight,
                      ),
                    ),
                  ],
                  if (hasImg && imgPos == InlineImagePosition.belowBody) ...[
                    const SizedBox(height: 8),
                    PizarronInlineImageWidget(
                      imageBytes: cachedInlineBytes,
                      height: imgHeight,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (hasImg && imgPos == InlineImagePosition.footer) ...[
          const SizedBox(height: 6),
          PizarronInlineImageWidget(
            imageBytes: cachedInlineBytes,
            height: imgHeight * 0.85,
          ),
        ],
      ],
    );
  }

  Widget _buildParagraphBlock(int index) {
    final override = cfg.paragraphOverrides[index];
    final fontName = override?.fontFamily ?? cfg.bodyFont;
    final colorHex = override?.colorHex ?? cfg.bodyColor;
    final fontSize = override?.fontSize ?? cfg.bodySize;
    final format = (override != null && override.format != TextBlockFormat.none)
        ? override.format
        : cfg.bodyFormat;

    final textColor = PizarronPalette.parseHex(colorHex);
    final style = PizarronFontCatalog.resolveFont(
      fontName,
      fontSize: fontSize,
      color: textColor,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );

    final isTargetPara = isEditing &&
        !activeTarget.isTitle &&
        activeTarget.paragraphIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isEditing) {
          if (index < paragraphFocusNodes.length) {
            paragraphFocusNodes[index].requestFocus();
            onTargetFocused(ActiveTextTarget.paragraph(index));
          }
        } else {
          onTargetFocused(ActiveTextTarget.paragraph(index));
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: PizarronFormattedBlockContainer(
          format: format,
          accentColor: textColor,
          isHighlightedTarget: isTargetPara,
          child: IgnorePointer(
            ignoring: !isEditing,
            child: TextField(
              controller: paragraphControllers[index],
              focusNode: index < paragraphFocusNodes.length
                  ? paragraphFocusNodes[index]
                  : null,
              readOnly: !isEditing,
              textAlign: cfg.textAlign,
              style: style,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                border: InputBorder.none,
                hintText: (isEditing && index == 0) ? 'Escribe aquí...' : '',
                hintStyle: style.copyWith(
                  color: textColor.withValues(alpha: 0.28),
                ),
              ),
              onChanged: (val) => onParagraphChanged(index, val),
            ),
          ),
        ),
      ),
    );
  }
}
