import 'package:flutter/material.dart';

import '../models/note_style_config.dart';
import 'pizarron_note_widget.dart';
import 'sidebar/sidebar_base_layer_panel.dart';
import 'sidebar/sidebar_common.dart';
import 'sidebar/sidebar_inline_image_panel.dart';
import 'sidebar/sidebar_pattern_layer_panel.dart';
import 'sidebar/sidebar_shape_border_panel.dart';
import 'sidebar/sidebar_typography_panel.dart';

export 'sidebar/sidebar_common.dart' show SidebarSection;

/// Barra lateral derecha de personalización (Overlay de edición).
/// Reglas de diseño:
/// - 100% guiada por íconos y previsualizaciones visuales (cero palabras/etiquetas de texto).
/// - Cero popups modales: todo se despliega suavemente junto al riel derecho.
/// - Bloques sólidos sin bordes negros puros (cumpliendo `skill_visual .md`).
class PizarronSidebarOverlay extends StatefulWidget {
  final NoteStyleConfig config;
  final ActiveTextTarget activeTarget;
  final ValueChanged<NoteStyleConfig> onConfigChanged;
  final ValueChanged<ActiveTextTarget> onTargetChanged;
  final VoidCallback onPickBackgroundImage;
  final VoidCallback onPickInlineImage;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onCloseEdit;

  const PizarronSidebarOverlay({
    super.key,
    required this.config,
    required this.activeTarget,
    required this.onConfigChanged,
    required this.onTargetChanged,
    required this.onPickBackgroundImage,
    required this.onPickInlineImage,
    required this.onDuplicate,
    required this.onDelete,
    required this.onCloseEdit,
  });

  @override
  State<PizarronSidebarOverlay> createState() => _PizarronSidebarOverlayState();
}

class _PizarronSidebarOverlayState extends State<PizarronSidebarOverlay> {
  SidebarSection? _activeSection;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_activeSection != null) ...[
              Container(
                width: 224,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.84,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SidebarColors.panelBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildActiveSubpanel(_activeSection!),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: SidebarColors.panelBg,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRailIcon(
                    icon: Icons.layers_rounded,
                    section: SidebarSection.baseLayer,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.grid_on_rounded,
                    section: SidebarSection.patternLayer,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.category_rounded,
                    section: SidebarSection.shape,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.border_style_rounded,
                    section: SidebarSection.border,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.text_fields_rounded,
                    section: SidebarSection.typography,
                  ),
                  const SizedBox(height: 8),
                  _buildRailIcon(
                    icon: Icons.image_rounded,
                    section: SidebarSection.inlineImage,
                  ),
                  const SizedBox(height: 14),
                  SidebarActionIcon(
                    icon: Icons.copy_rounded,
                    bgColor: SidebarColors.cardBg,
                    iconColor: Colors.white,
                    onTap: widget.onDuplicate,
                  ),
                  const SizedBox(height: 8),
                  SidebarActionIcon(
                    icon: Icons.delete_rounded,
                    bgColor: const Color(0xFF421C26),
                    iconColor: const Color(0xFFFF4D6D),
                    onTap: widget.onDelete,
                  ),
                  const SizedBox(height: 10),
                  SidebarActionIcon(
                    icon: Icons.check_rounded,
                    bgColor: SidebarColors.activeAccent,
                    iconColor: const Color(0xFF141820),
                    onTap: widget.onCloseEdit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRailIcon({
    required IconData icon,
    required SidebarSection section,
  }) {
    final selected = _activeSection == section;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_activeSection == section) {
            _activeSection = null;
          } else {
            _activeSection = section;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected ? SidebarColors.secondaryAccent : SidebarColors.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildActiveSubpanel(SidebarSection section) {
    switch (section) {
      case SidebarSection.baseLayer:
        return SidebarBaseLayerPanel(
          config: widget.config,
          onConfigChanged: widget.onConfigChanged,
          onPickBackgroundImage: widget.onPickBackgroundImage,
        );
      case SidebarSection.patternLayer:
        return SidebarPatternLayerPanel(
          config: widget.config,
          onConfigChanged: widget.onConfigChanged,
        );
      case SidebarSection.shape:
        return SidebarShapePanel(
          config: widget.config,
          onConfigChanged: widget.onConfigChanged,
        );
      case SidebarSection.border:
        return SidebarBorderPanel(
          config: widget.config,
          onConfigChanged: widget.onConfigChanged,
        );
      case SidebarSection.typography:
        return SidebarTypographyPanel(
          config: widget.config,
          activeTarget: widget.activeTarget,
          onConfigChanged: widget.onConfigChanged,
          onTargetChanged: widget.onTargetChanged,
        );
      case SidebarSection.inlineImage:
        return SidebarInlineImagePanel(
          config: widget.config,
          onConfigChanged: widget.onConfigChanged,
          onPickInlineImage: widget.onPickInlineImage,
        );
    }
  }
}
