import 'package:flutter/material.dart';

import '../../models/note_style_config.dart';
import '../pizarron_color_picker_area.dart';
import 'sidebar_common.dart';

/// Panel de capa de patrones de la nota con controles contextuales
class SidebarPatternLayerPanel extends StatefulWidget {
  final NoteStyleConfig config;
  final ValueChanged<NoteStyleConfig> onConfigChanged;

  const SidebarPatternLayerPanel({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<SidebarPatternLayerPanel> createState() => _SidebarPatternLayerPanelState();
}

class _SidebarPatternLayerPanelState extends State<SidebarPatternLayerPanel> {
  late TextEditingController _emojiPatternController;

  @override
  void initState() {
    super.initState();
    _emojiPatternController = TextEditingController(text: widget.config.patternEmojiText);
  }

  @override
  void didUpdateWidget(covariant SidebarPatternLayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.patternEmojiText != _emojiPatternController.text) {
      _emojiPatternController.text = widget.config.patternEmojiText;
    }
  }

  @override
  void dispose() {
    _emojiPatternController.dispose();
    super.dispose();
  }

  IconData _iconForPattern(NotePatternType type) {
    switch (type) {
      case NotePatternType.none:
        return Icons.block_rounded;
      case NotePatternType.chess:
        return Icons.apps_rounded;
      case NotePatternType.linesOblique:
        return Icons.texture_rounded;
      case NotePatternType.linesHorizontal:
        return Icons.reorder_rounded;
      case NotePatternType.linesVertical:
        return Icons.view_week_rounded;
      case NotePatternType.waves:
        return Icons.waves_rounded;
      case NotePatternType.circlesFilled:
        return Icons.bubble_chart_rounded;
      case NotePatternType.circlesEmpty:
        return Icons.radio_button_unchecked_rounded;
      case NotePatternType.dots:
        return Icons.grain_rounded;
      case NotePatternType.grid:
        return Icons.grid_4x4_rounded;
      case NotePatternType.emoji:
        return Icons.auto_awesome_rounded;
    }
  }

  Widget _buildPatternTile(NotePatternType type, bool selected) {
    return GestureDetector(
      onTap: () => widget.onConfigChanged(widget.config.copyWith(patternType: type)),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? SidebarColors.secondaryAccent : SidebarColors.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(_iconForPattern(type), color: Colors.white, size: 21),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in NotePatternType.values)
              _buildPatternTile(p, cfg.patternType == p),
          ],
        ),
        if (cfg.patternType != NotePatternType.none) ...[
          const SizedBox(height: 12),
          if (cfg.patternSupportsFillToggle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SidebarModeButton(
                  icon: Icons.circle,
                  isSelected: cfg.patternType == NotePatternType.circlesFilled,
                  onTap: () => widget.onConfigChanged(
                    cfg.copyWith(patternType: NotePatternType.circlesFilled),
                  ),
                ),
                const SizedBox(width: 10),
                SidebarModeButton(
                  icon: Icons.circle_outlined,
                  isSelected: cfg.patternType == NotePatternType.circlesEmpty,
                  onTap: () => widget.onConfigChanged(
                    cfg.copyWith(patternType: NotePatternType.circlesEmpty),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (cfg.patternSupportsEmojiInput) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final em in const ['✨', '❤️', '🔥', '⭐', '🌸', '🦊', '🌙', '⚡', '🎵', '💎'])
                  GestureDetector(
                    onTap: () {
                      _emojiPatternController.text = em;
                      widget.onConfigChanged(cfg.copyWith(patternEmojiText: em));
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cfg.patternEmojiText == em
                            ? SidebarColors.secondaryAccent
                            : SidebarColors.cardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(em, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: SidebarColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _emojiPatternController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      maxLength: 6,
                      decoration: const InputDecoration(
                        counterText: '',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                          widget.onConfigChanged(cfg.copyWith(patternEmojiText: val.trim()));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (cfg.patternSupportsStrokeWidth)
            SidebarIconSlider(
              icon: Icons.line_weight_rounded,
              value: cfg.patternStrokeWidth,
              min: 1.0,
              max: 12.0,
              onChanged: (v) => widget.onConfigChanged(cfg.copyWith(patternStrokeWidth: v)),
            ),
          if (cfg.patternSupportsSpacing)
            SidebarIconSlider(
              icon: Icons.space_bar_rounded,
              value: cfg.patternSpacing,
              min: 6.0,
              max: 64.0,
              onChanged: (v) => widget.onConfigChanged(cfg.copyWith(patternSpacing: v)),
            ),
          if (cfg.patternSupportsScale)
            SidebarIconSlider(
              icon: Icons.zoom_out_map_rounded,
              value: cfg.patternScale,
              min: 8.0,
              max: 48.0,
              onChanged: (v) => widget.onConfigChanged(cfg.copyWith(patternScale: v)),
            ),
          SidebarIconSlider(
            icon: Icons.opacity_rounded,
            value: cfg.patternOpacity,
            min: 0.05,
            max: 0.95,
            onChanged: (v) => widget.onConfigChanged(cfg.copyWith(patternOpacity: v)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SidebarModeButton(
                icon: Icons.lens_rounded,
                isSelected: !cfg.patternUseGradient,
                onTap: () => widget.onConfigChanged(cfg.copyWith(patternUseGradient: false)),
              ),
              const SizedBox(width: 10),
              SidebarModeButton(
                icon: Icons.gradient_rounded,
                isSelected: cfg.patternUseGradient,
                onTap: () => widget.onConfigChanged(cfg.copyWith(patternUseGradient: true)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PizarronColorPickerArea(
            currentColorHex: cfg.patternColor1,
            sampledColors: sampled,
            onColorChanged: (hex) => widget.onConfigChanged(cfg.copyWith(patternColor1: hex)),
          ),
          if (cfg.patternUseGradient) ...[
            const SizedBox(height: 10),
            PizarronColorPickerArea(
              currentColorHex: cfg.patternColor2,
              sampledColors: sampled,
              onColorChanged: (hex) => widget.onConfigChanged(cfg.copyWith(patternColor2: hex)),
            ),
          ],
        ],
      ],
    );
  }
}
