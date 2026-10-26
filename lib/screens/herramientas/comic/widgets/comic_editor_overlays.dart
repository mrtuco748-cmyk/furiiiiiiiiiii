import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_bubble.dart';
import '../models/comic_interaction_mode.dart';
import '../models/comic_panel.dart';
import '../models/comic_sticker.dart';
import 'comic_floating_bubble_bar.dart';
import 'comic_floating_sfx_bar.dart';
import 'comic_floating_template_bar.dart';
import 'comic_panel_context_bar.dart';
import 'comic_panel_customizer_bar.dart';
import 'comic_sfx_editor_bar.dart';

/// Gestor de capas flotantes no invasivas para edición de viñetas, globos, SFX y plantillas.
class ComicEditorOverlays extends StatelessWidget {
  final ComicController controller;
  final ComicPanel? activePanel;
  final ComicBubble? editingBubble;
  final ComicSticker? editingSfx;
  final bool showBubbleBar;
  final bool showSfxBar;
  final bool showSfxEditor;
  final bool showPanelCustomizer;
  final bool showTemplateBar;
  final bool isImmersive;

  final VoidCallback onDrawInPanel;
  final VoidCallback onInsertDrawing;
  final VoidCallback? onPickGalleryImage;
  final VoidCallback onOpenPanelCustomizer;
  final VoidCallback onClosePanelCustomizer;
  final ValueChanged<ComicBubble> onSaveBubble;
  final ValueChanged<String> onDeleteBubble;
  final VoidCallback onCloseBubble;
  final ValueChanged<ComicSticker> onUpdateSfx;
  final VoidCallback onDeleteSfx;
  final VoidCallback onCloseSfxEditor;
  final void Function(String text, Color color) onStampSfx;
  final VoidCallback onCloseSfxBar;
  final VoidCallback onCloseTemplateBar;

  const ComicEditorOverlays({
    super.key,
    required this.controller,
    required this.activePanel,
    required this.editingBubble,
    required this.editingSfx,
    required this.showBubbleBar,
    required this.showSfxBar,
    required this.showSfxEditor,
    required this.showPanelCustomizer,
    required this.showTemplateBar,
    required this.isImmersive,
    required this.onDrawInPanel,
    required this.onInsertDrawing,
    this.onPickGalleryImage,
    required this.onOpenPanelCustomizer,
    required this.onClosePanelCustomizer,
    required this.onSaveBubble,
    required this.onDeleteBubble,
    required this.onCloseBubble,
    required this.onUpdateSfx,
    required this.onDeleteSfx,
    required this.onCloseSfxEditor,
    required this.onStampSfx,
    required this.onCloseSfxBar,
    required this.onCloseTemplateBar,
  });

  @override
  Widget build(BuildContext context) {
    if (isImmersive) return const SizedBox.shrink();

    return Stack(
      children: [
        // Barra de contexto de viñeta activa
        if (activePanel != null && !showPanelCustomizer)
          Positioned(
            bottom: 74,
            left: 0,
            right: 0,
            child: Center(
              child: ComicPanelContextBar(
                panel: activePanel!,
                onDraw: onDrawInPanel,
                onInsert: onInsertDrawing,
                onGallery: onPickGalleryImage,
                onCustomize: onOpenPanelCustomizer,
                onSlice: () => controller.setInteractionMode(
                  controller.interactionMode == ComicInteractionMode.slicePanel
                      ? ComicInteractionMode.normal
                      : ComicInteractionMode.slicePanel,
                ),
                onFrameContent: () => controller.setInteractionMode(
                  controller.interactionMode == ComicInteractionMode.frameContent
                      ? ComicInteractionMode.normal
                      : ComicInteractionMode.frameContent,
                ),
                onDelete: () => controller.deletePanel(activePanel!.id),
                onQuickBorder: (width, color) => controller.updatePanelBorder(
                  activePanel!.id,
                  borderWidth: width,
                  borderColor: color,
                ),
                onTransform: (scale, dx, dy) => controller.setPanelTransform(activePanel!.id, scale: scale, dx: dx, dy: dy),
                onClear: () => controller.setPanelDrawing(activePanel!.id, null, null),
                onClose: () => controller.selectPanel(null),
              ),
            ),
          ),

        // Barra de personalización dimensional y geométrica de viñeta
        if (activePanel != null && showPanelCustomizer)
          Positioned(
            bottom: 74,
            left: 0,
            right: 0,
            child: Center(
              child: ComicPanelCustomizerBar(
                panel: activePanel!,
                onUpdate: (updated) => controller.updatePanel(updated),
                onSplitH: () => controller.splitPanel(activePanel!.id, vertical: false),
                onSplitV: () => controller.splitPanel(activePanel!.id, vertical: true),
                onDelete: () {
                  controller.deletePanel(activePanel!.id);
                  onClosePanelCustomizer();
                },
                onClose: onClosePanelCustomizer,
              ),
            ),
          ),

        // Barra de globos de diálogo
        if (showBubbleBar || controller.selectedBubble != null)
          Positioned(
            bottom: 74,
            left: 0,
            right: 0,
            child: Center(
              child: ComicFloatingBubbleBar(
                bubble: controller.selectedBubble ?? editingBubble,
                onSave: onSaveBubble,
                onDelete: onDeleteBubble,
                onClose: onCloseBubble,
              ),
            ),
          ),

        // Editor de SFX seleccionado
        if ((showSfxEditor || controller.selectedSfx != null) && (controller.selectedSfx ?? editingSfx) != null)
          Positioned(
            bottom: 74,
            left: 0,
            right: 0,
            child: Center(
              child: ComicSfxEditorBar(
                sfx: (controller.selectedSfx ?? editingSfx)!,
                onUpdate: onUpdateSfx,
                onDelete: onDeleteSfx,
                onClose: onCloseSfxEditor,
              ),
            ),
          ),

        // Barra de estampado rápido de SFX
        if (showSfxBar)
          Positioned(
            bottom: 74,
            left: 0,
            right: 0,
            child: Center(
              child: ComicFloatingSfxBar(
                onStamp: onStampSfx,
                onClose: onCloseSfxBar,
              ),
            ),
          ),

        // Selector de Plantillas
        if (showTemplateBar)
          Positioned(
            bottom: 74,
            left: 0,
            right: 0,
            child: Center(
              child: ComicFloatingTemplateBar(
                onSelect: (t) {
                  controller.applyTemplateToActivePage(t);
                  onCloseTemplateBar();
                },
                onClose: onCloseTemplateBar,
              ),
            ),
          ),
      ],
    );
  }
}
