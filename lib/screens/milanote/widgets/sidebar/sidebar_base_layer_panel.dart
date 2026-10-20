import 'package:flutter/material.dart';

import '../../models/note_style_config.dart';
import '../pizarron_color_picker_area.dart';
import 'sidebar_common.dart';

/// Panel de capa base: Sólido / Degradado 3 partes / Imagen + Brillo
class SidebarBaseLayerPanel extends StatefulWidget {
  final NoteStyleConfig config;
  final ValueChanged<NoteStyleConfig> onConfigChanged;
  final VoidCallback onPickBackgroundImage;

  const SidebarBaseLayerPanel({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.onPickBackgroundImage,
  });

  @override
  State<SidebarBaseLayerPanel> createState() => _SidebarBaseLayerPanelState();
}

class _SidebarBaseLayerPanelState extends State<SidebarBaseLayerPanel> {
  int _gradientStopIndex = 0; // 0 = inicial, 1 = medio, 2 = final

  Widget _buildGradientStopDot(int index, String hex) {
    final isSelected = _gradientStopIndex == index;
    final color = PizarronPalette.parseHex(hex);
    return GestureDetector(
      onTap: () => setState(() => _gradientStopIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isSelected ? 30 : 22,
        height: isSelected ? 30 : 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0x55141820),
              blurRadius: isSelected ? 6 : 2,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.adjust_rounded,
                size: 16,
                color: color.computeLuminance() > 0.5
                    ? const Color(0xFF141820)
                    : Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildAngleButton(double angle, IconData icon, NoteStyleConfig cfg) {
    final selected = (cfg.gradientAngle - angle).abs() < 1.0;
    return GestureDetector(
      onTap: () => widget.onConfigChanged(cfg.copyWith(gradientAngle: angle)),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? SidebarColors.secondaryAccent : SidebarColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final sampled = getSidebarSampledColors(cfg);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SidebarModeButton(
              icon: Icons.circle,
              isSelected: cfg.baseMode == 'solid',
              onTap: () => widget.onConfigChanged(cfg.copyWith(baseMode: 'solid')),
            ),
            SidebarModeButton(
              icon: Icons.gradient_rounded,
              isSelected: cfg.baseMode == 'gradient',
              onTap: () => widget.onConfigChanged(cfg.copyWith(baseMode: 'gradient')),
            ),
            SidebarModeButton(
              icon: Icons.photo_camera_back_rounded,
              isSelected: cfg.baseMode == 'image',
              onTap: () {
                widget.onConfigChanged(cfg.copyWith(baseMode: 'image'));
                if (!cfg.hasBgImage) widget.onPickBackgroundImage();
              },
            ),
            SidebarModeButton(
              icon: Icons.auto_awesome_rounded,
              isSelected: cfg.hasShine,
              activeColor: const Color(0xFFFFB703),
              onTap: () => widget.onConfigChanged(cfg.copyWith(hasShine: !cfg.hasShine)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (cfg.baseMode == 'solid') ...[
          PizarronColorPickerArea(
            currentColorHex: cfg.solidColor,
            sampledColors: sampled,
            onColorChanged: (hex) => widget.onConfigChanged(cfg.copyWith(solidColor: hex)),
          ),
        ] else if (cfg.baseMode == 'gradient') ...[
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  PizarronPalette.parseHex(cfg.gradientStartColor),
                  PizarronPalette.parseHex(cfg.gradientMidColor),
                  PizarronPalette.parseHex(cfg.gradientEndColor),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGradientStopDot(0, cfg.gradientStartColor),
                _buildGradientStopDot(1, cfg.gradientMidColor),
                _buildGradientStopDot(2, cfg.gradientEndColor),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAngleButton(0.0, Icons.arrow_forward_rounded, cfg),
              _buildAngleButton(45.0, Icons.south_east_rounded, cfg),
              _buildAngleButton(90.0, Icons.arrow_downward_rounded, cfg),
              _buildAngleButton(135.0, Icons.south_west_rounded, cfg),
            ],
          ),
          const SizedBox(height: 12),
          PizarronColorPickerArea(
            currentColorHex: _gradientStopIndex == 0
                ? cfg.gradientStartColor
                : (_gradientStopIndex == 1 ? cfg.gradientMidColor : cfg.gradientEndColor),
            sampledColors: sampled,
            onColorChanged: (hex) {
              if (_gradientStopIndex == 0) {
                widget.onConfigChanged(cfg.copyWith(gradientStartColor: hex));
              } else if (_gradientStopIndex == 1) {
                widget.onConfigChanged(cfg.copyWith(gradientMidColor: hex));
              } else {
                widget.onConfigChanged(cfg.copyWith(gradientEndColor: hex));
              }
            },
          ),
        ] else if (cfg.baseMode == 'image') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SidebarActionIcon(
                icon: Icons.add_photo_alternate_rounded,
                bgColor: SidebarColors.secondaryAccent,
                iconColor: Colors.white,
                onTap: widget.onPickBackgroundImage,
              ),
              if (cfg.hasBgImage)
                SidebarActionIcon(
                  icon: Icons.hide_image_rounded,
                  bgColor: const Color(0xFF421C26),
                  iconColor: const Color(0xFFFF4D6D),
                  onTap: () => widget.onConfigChanged(
                    cfg.copyWith(clearBgImage: true, baseMode: 'solid'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SidebarIconSlider(
            icon: Icons.opacity_rounded,
            value: cfg.bgImageOpacity,
            min: 0.15,
            max: 1.0,
            onChanged: (v) => widget.onConfigChanged(cfg.copyWith(bgImageOpacity: v)),
          ),
        ],
      ],
    );
  }
}
