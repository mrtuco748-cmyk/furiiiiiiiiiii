import 'package:flutter/material.dart';

import '../../models/note_style_config.dart';
import '../pizarron_color_picker_area.dart';
import '../pizarron_note_widget.dart';
import 'sidebar_common.dart';

/// Panel de tipografía, formatos de bloque y color de texto
class SidebarTypographyPanel extends StatelessWidget {
  final NoteStyleConfig config;
  final ActiveTextTarget activeTarget;
  final ValueChanged<NoteStyleConfig> onConfigChanged;
  final ValueChanged<ActiveTextTarget> onTargetChanged;

  const SidebarTypographyPanel({
    super.key,
    required this.config,
    required this.activeTarget,
    required this.onConfigChanged,
    required this.onTargetChanged,
  });

  void _applyTypographyChange({
    String? fontFamily,
    String? colorHex,
    double? fontSize,
    TextBlockFormat? format,
  }) {
    final cfg = config;
    final target = activeTarget;

    if (target.isTitle) {
      onConfigChanged(
        cfg.copyWith(
          titleFont: fontFamily ?? cfg.titleFont,
          titleColor: colorHex ?? cfg.titleColor,
          titleSize: fontSize ?? cfg.titleSize,
          titleFormat: format ?? cfg.titleFormat,
        ),
      );
    } else if (target.paragraphIndex != null) {
      final idx = target.paragraphIndex!;
      final nextOverrides = Map<int, ParagraphStyleOverride>.from(cfg.paragraphOverrides);
      final existing = nextOverrides[idx] ??
          ParagraphStyleOverride(
            fontFamily: cfg.bodyFont,
            colorHex: cfg.bodyColor,
            fontSize: cfg.bodySize,
            format: cfg.bodyFormat,
          );
      nextOverrides[idx] = existing.copyWith(
        fontFamily: fontFamily,
        colorHex: colorHex,
        fontSize: fontSize,
        format: format,
      );
      onConfigChanged(cfg.copyWith(paragraphOverrides: nextOverrides));
    } else {
      onConfigChanged(
        cfg.copyWith(
          bodyFont: fontFamily ?? cfg.bodyFont,
          bodyColor: colorHex ?? cfg.bodyColor,
          bodySize: fontSize ?? cfg.bodySize,
          bodyFormat: format ?? cfg.bodyFormat,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = config;
    final target = activeTarget;
    final sampled = getSidebarSampledColors(cfg);

    String currentFont = cfg.bodyFont;
    String currentColor = cfg.bodyColor;
    double currentSize = cfg.bodySize;
    TextBlockFormat currentFormat = cfg.bodyFormat;

    if (target.isTitle) {
      currentFont = cfg.titleFont;
      currentColor = cfg.titleColor;
      currentSize = cfg.titleSize;
      currentFormat = cfg.titleFormat;
    } else if (target.paragraphIndex != null) {
      final ov = cfg.paragraphOverrides[target.paragraphIndex!];
      currentFont = ov?.fontFamily ?? cfg.bodyFont;
      currentColor = ov?.colorHex ?? cfg.bodyColor;
      currentSize = ov?.fontSize ?? cfg.bodySize;
      currentFormat = ov?.format ?? cfg.bodyFormat;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SidebarModeButton(
              icon: Icons.title_rounded,
              isSelected: target.isTitle,
              onTap: () => onTargetChanged(const ActiveTextTarget.title()),
            ),
            SidebarModeButton(
              icon: Icons.notes_rounded,
              isSelected: !target.isTitle,
              onTap: () => onTargetChanged(
                target.paragraphIndex != null
                    ? ActiveTextTarget.paragraph(target.paragraphIndex!)
                    : const ActiveTextTarget.bodyDefault(),
              ),
            ),
            SidebarModeButton(
              icon: Icons.format_align_left_rounded,
              isSelected: cfg.textAlign == TextAlign.left,
              onTap: () => onConfigChanged(cfg.copyWith(textAlign: TextAlign.left)),
            ),
            SidebarModeButton(
              icon: Icons.format_align_center_rounded,
              isSelected: cfg.textAlign == TextAlign.center,
              onTap: () => onConfigChanged(cfg.copyWith(textAlign: TextAlign.center)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SidebarIconSlider(
          icon: Icons.format_size_rounded,
          value: currentSize.clamp(11.0, 38.0),
          min: 11.0,
          max: 38.0,
          onChanged: (v) => _applyTypographyChange(fontSize: v),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final fmt in TextBlockFormat.values)
              GestureDetector(
                onTap: () => _applyTypographyChange(format: fmt),
                child: Container(
                  width: 44,
                  height: 38,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: currentFormat == fmt ? SidebarColors.secondaryAccent : SidebarColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: BlockFormatMiniPainter(format: fmt),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final font in PizarronFontCatalog.fonts)
              GestureDetector(
                onTap: () => _applyTypographyChange(fontFamily: font),
                child: Container(
                  width: 44,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: currentFont == font ? SidebarColors.secondaryAccent : SidebarColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    PizarronFontCatalog.glyphFor(font),
                    style: PizarronFontCatalog.resolveFont(
                      font,
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        PizarronColorPickerArea(
          currentColorHex: currentColor,
          sampledColors: sampled,
          onColorChanged: (hex) => _applyTypographyChange(colorHex: hex),
        ),
      ],
    );
  }
}
