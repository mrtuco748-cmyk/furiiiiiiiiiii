import 'package:flutter/material.dart';

import '../../models/note_style_config.dart';

export 'sidebar_mini_painters.dart';

/// Categorías del panel lateral derecho de edición.
enum SidebarSection {
  baseLayer,
  patternLayer,
  shape,
  border,
  typography,
  inlineImage,
}

abstract class SidebarColors {
  static const Color panelBg = Color(0xFF1A1F2E);
  static const Color cardBg = Color(0xFF252C40);
  static const Color activeAccent = Color(0xFF2EE50F);
  static const Color secondaryAccent = Color(0xFF7B2CBF);
}

List<String> getSidebarSampledColors(NoteStyleConfig cfg) {
  final set = <String>{};
  if (cfg.solidColor.isNotEmpty) set.add(cfg.solidColor);
  if (cfg.gradientStartColor.isNotEmpty) set.add(cfg.gradientStartColor);
  if (cfg.gradientMidColor.isNotEmpty) set.add(cfg.gradientMidColor);
  if (cfg.gradientEndColor.isNotEmpty) set.add(cfg.gradientEndColor);
  if (cfg.patternColor1.isNotEmpty) set.add(cfg.patternColor1);
  if (cfg.patternColor2.isNotEmpty) set.add(cfg.patternColor2);
  if (cfg.borderColor.isNotEmpty) set.add(cfg.borderColor);
  if (cfg.titleColor.isNotEmpty) set.add(cfg.titleColor);
  if (cfg.bodyColor.isNotEmpty) set.add(cfg.bodyColor);
  set.add('#4FC3F7');
  set.add('#CE93D8');
  set.add('#2EE50F');
  set.add('#FFFFFF');
  set.add('#141820');
  return set.toList();
}

class SidebarModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const SidebarModeButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeColor = SidebarColors.secondaryAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : SidebarColors.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class SidebarActionIcon extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const SidebarActionIcon({
    super.key,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
    );
  }
}

class SidebarIconSlider extends StatelessWidget {
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const SidebarIconSlider({
    super.key,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: SidebarColors.activeAccent,
              inactiveTrackColor: SidebarColors.cardBg,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
