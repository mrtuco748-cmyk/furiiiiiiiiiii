import 'package:flutter/material.dart';

import '../../models/note_style_config.dart';
import '../pizarron_color_picker_area.dart';
import 'sidebar_common.dart';

/// Panel de selección de forma vectorial para la nota
class SidebarShapePanel extends StatelessWidget {
  final NoteStyleConfig config;
  final ValueChanged<NoteStyleConfig> onConfigChanged;

  const SidebarShapePanel({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = config;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final shape in NoteShapeType.values)
          GestureDetector(
            onTap: () {
              final shouldCenter = shape == NoteShapeType.diamond ||
                  shape == NoteShapeType.circle ||
                  shape == NoteShapeType.hexagon ||
                  shape == NoteShapeType.octagon ||
                  shape == NoteShapeType.shield;
              onConfigChanged(
                cfg.copyWith(
                  shapeType: shape,
                  textAlign: shouldCenter ? TextAlign.center : cfg.textAlign,
                ),
              );
            },
            child: Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cfg.shapeType == shape ? SidebarColors.secondaryAccent : SidebarColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: ShapeMiniPreviewPainter(shape: shape),
              ),
            ),
          ),
      ],
    );
  }
}

/// Panel de selección y configuración de borde de la nota
class SidebarBorderPanel extends StatelessWidget {
  final NoteStyleConfig config;
  final ValueChanged<NoteStyleConfig> onConfigChanged;

  const SidebarBorderPanel({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = config;
    final sampled = getSidebarSampledColors(cfg);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final bt in NoteBorderType.values)
              GestureDetector(
                onTap: () => onConfigChanged(cfg.copyWith(borderType: bt)),
                child: Container(
                  width: 58,
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cfg.borderType == bt ? SidebarColors.secondaryAccent : SidebarColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CustomPaint(
                    painter: BorderMiniPreviewPainter(borderType: bt),
                  ),
                ),
              ),
          ],
        ),
        if (cfg.borderType != NoteBorderType.none) ...[
          const SizedBox(height: 12),
          SidebarIconSlider(
            icon: Icons.line_weight_rounded,
            value: cfg.borderWidth,
            min: 1.5,
            max: 10.0,
            onChanged: (v) => onConfigChanged(cfg.copyWith(borderWidth: v)),
          ),
          if (cfg.borderType != NoteBorderType.solid)
            SidebarIconSlider(
              icon: Icons.space_bar_rounded,
              value: cfg.borderSpacing,
              min: 3.0,
              max: 24.0,
              onChanged: (v) => onConfigChanged(cfg.copyWith(borderSpacing: v)),
            ),
          const SizedBox(height: 8),
          PizarronColorPickerArea(
            currentColorHex: cfg.borderColor,
            sampledColors: sampled,
            onColorChanged: (hex) => onConfigChanged(cfg.copyWith(borderColor: hex)),
          ),
        ],
      ],
    );
  }
}
