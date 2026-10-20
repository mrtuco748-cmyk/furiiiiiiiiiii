import 'package:flutter/material.dart';

import '../../models/note_style_config.dart';
import 'sidebar_common.dart';

/// Panel de imagen integrada en la nota (4 posiciones + slider de tamaño)
class SidebarInlineImagePanel extends StatelessWidget {
  final NoteStyleConfig config;
  final ValueChanged<NoteStyleConfig> onConfigChanged;
  final VoidCallback onPickInlineImage;

  const SidebarInlineImagePanel({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.onPickInlineImage,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = config;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SidebarActionIcon(
              icon: Icons.add_photo_alternate_rounded,
              bgColor: SidebarColors.secondaryAccent,
              iconColor: Colors.white,
              onTap: onPickInlineImage,
            ),
            if (cfg.hasInlineImage)
              SidebarActionIcon(
                icon: Icons.delete_sweep_rounded,
                bgColor: const Color(0xFF421C26),
                iconColor: const Color(0xFFFF4D6D),
                onTap: () => onConfigChanged(
                  cfg.copyWith(clearInlineImage: true),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final pos in InlineImagePosition.values)
              GestureDetector(
                onTap: () => onConfigChanged(cfg.copyWith(inlineImagePosition: pos)),
                child: Container(
                  width: 44,
                  height: 48,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cfg.inlineImagePosition == pos
                        ? SidebarColors.secondaryAccent
                        : SidebarColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CustomPaint(
                    painter: ImagePositionMiniPainter(position: pos),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SidebarIconSlider(
          icon: Icons.height_rounded,
          value: cfg.inlineImageHeightRatio,
          min: 0.20,
          max: 0.55,
          onChanged: (v) => onConfigChanged(cfg.copyWith(inlineImageHeightRatio: v)),
        ),
      ],
    );
  }
}
