import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/canvas_dimensions_dialog.dart';
import '../../dibujo/dibujo_screen.dart';
import '../../dibujo/models/drawing_project.dart';
import '../../dibujo/services/drawing_storage_service.dart';
import '../comic_reader_screen.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_panel.dart';
import '../widgets/comic_drawing_picker_sheet.dart';
import '../widgets/comic_export_dialog.dart';

/// Acciones de navegación, dibujo en viñeta, apertura de galería y exportación para ComicEditorScreen.
abstract final class ComicEditorActions {
  static Future<void> drawInPanel({
    required BuildContext context,
    required ComicController controller,
    required ComicPanel panel,
  }) async {
    DrawingProject? project;
    if (panel.drawingProjectId != null) {
      project = await DrawingStorageService.loadProject(panel.drawingProjectId!);
    }

    const baseW = 1200.0;
    const baseH = 1697.0;
    final defaultWidth = (panel.normalizedRect.width * baseW).clamp(300.0, 3840.0);
    final defaultHeight = (panel.normalizedRect.height * baseH).clamp(300.0, 3840.0);

    Size chosenSize = Size(defaultWidth, defaultHeight);
    if (project == null) {
      if (!context.mounted) return;
      final selected = await CanvasDimensionsDialog.show(
        context,
        initialSize: Size(defaultWidth, defaultHeight),
        panelAspectRatio: defaultWidth / defaultHeight,
      );
      if (selected == null) return;
      chosenSize = selected;
    } else {
      chosenSize = Size(project.canvasWidth, project.canvasHeight);
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DibujoScreen(
          project: project,
          canvasSize: chosenSize,
          panelGuideShape: panel.panelShape,
          panelGuidePolygon: panel.polygonPoints,
          panelGuideBorderRadius: panel.borderRadius,
          onSaveAndReturn: (savedProj, pngBytes) async {
            String? base64Str;
            if (pngBytes != null) {
              base64Str = base64Encode(pngBytes);
            }
            final projToSave = base64Str != null
                ? savedProj.copyWith(thumbnailBase64: base64Str)
                : savedProj;
            await DrawingStorageService.saveProject(projToSave);
            if (base64Str != null) {
              controller.setPanelDrawing(panel.id, savedProj.id, base64Str);
            }
          },
        ),
      ),
    );
  }

  static Future<void> pickImageFromGallery({
    required BuildContext context,
    required ComicController controller,
    required ComicPanel panel,
  }) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final base64Str = base64Encode(bytes);
      controller.setPanelDrawing(panel.id, null, base64Str);
    } catch (e) {
      debugPrint('Error picking gallery image for comic panel: $e');
    }
  }

  static void insertDrawing({
    required BuildContext context,
    required ComicController controller,
    required ComicPanel panel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ComicDrawingPickerSheet(
        onSelect: (drawing) {
          controller.setPanelDrawing(panel.id, drawing.id, drawing.thumbnailBase64);
        },
      ),
    );
  }

  static void openReader(BuildContext context, ComicController controller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComicReaderScreen(project: controller.project),
      ),
    );
  }

  static void openExport(BuildContext context, ComicController controller) {
    showDialog(
      context: context,
      builder: (_) => ComicExportDialog(controller: controller),
    );
  }
}
