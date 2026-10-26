import 'dart:convert';
import 'package:flutter/material.dart';
import '../../controllers/drawing_controller.dart';
import '../../models/drawing_layer.dart';
import '../../models/drawing_project.dart';
import '../../services/drawing_storage_service.dart';
import '../drawing_brush_cursor_card.dart';
import '../drawing_predictive_stroke_card.dart';

/// Popover de Opciones de Infinite Painter (Screenshot 3)
class DrawingOptionsPopover extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback onOpenProjects;
  final VoidCallback onExport;
  final VoidCallback onClose;

  const DrawingOptionsPopover({
    super.key,
    required this.controller,
    required this.onOpenProjects,
    required this.onExport,
    required this.onClose,
  });

  Future<void> _showRenameDialog(BuildContext context) async {
    final textController = TextEditingController(text: controller.projectTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF00D4FF), size: 20),
            SizedBox(width: 8),
            Text('Renombrar Proyecto', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Nombre del dibujo',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF282828),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final t = textController.text.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      controller.setTitle(newTitle);
      final png = await controller.exportToPng(size: const Size(200, 200));
      final thumb = png != null ? base64Encode(png) : null;
      await DrawingStorageService.saveProject(controller.toProject(thumbnailBase64: thumb));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Renombrado a "$newTitle"'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF1E1E1E),
          ),
        );
      }
    }
  }

  Widget _buildGridItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Opciones',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DrawingPredictiveStrokeCard(controller: controller),
              const SizedBox(height: 10),
              DrawingBrushCursorCard(controller: controller),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
              _buildGridItem(
                icon: Icons.add,
                label: 'Nuevo',
                onTap: () {
                  onClose();
                  controller.loadProject(DrawingProject(
                    id: 'draw_${DateTime.now().millisecondsSinceEpoch}',
                    title: 'Nuevo Dibujo',
                    canvasWidth: controller.canvasWidth,
                    canvasHeight: controller.canvasHeight,
                    layers: [DrawingLayer(id: 'layer_${DateTime.now().microsecondsSinceEpoch}', name: 'Capa 1', strokes: [])],
                  ));
                },
              ),
              _buildGridItem(
                icon: Icons.folder_open,
                label: 'Abrir',
                onTap: () {
                  onClose();
                  onOpenProjects();
                },
              ),
              _buildGridItem(
                icon: Icons.save,
                label: 'Guardar',
                onTap: () async {
                  onClose();
                  final png = await controller.exportToPng(size: const Size(200, 200));
                  final thumb = png != null ? base64Encode(png) : null;
                  await DrawingStorageService.saveProject(controller.toProject(thumbnailBase64: thumb));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Proyecto "${controller.projectTitle}" guardado'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: const Color(0xFF1E1E1E),
                      ),
                    );
                  }
                },
              ),
              _buildGridItem(
                icon: Icons.edit,
                label: 'Renombrar',
                onTap: () {
                  onClose();
                  _showRenameDialog(context);
                },
              ),
              _buildGridItem(
                icon: Icons.history,
                label: 'Registro',
                onTap: () {
                  onClose();
                  final totalStrokes = controller.layers.fold<int>(0, (sum, l) => sum + l.strokes.length);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: Color(0xFF00D4FF), size: 20),
                          SizedBox(width: 8),
                          Text('Detalles del Lienzo', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Título: ${controller.project.title}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Capas activas: ${controller.layers.length}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Trazos totales: $totalStrokes', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Resolución: ${controller.canvasWidth.toInt()} x ${controller.canvasHeight.toInt()} px', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Fondo: ${controller.backgroundType.displayName}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cerrar', style: TextStyle(color: Color(0xFF00D4FF))),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildGridItem(
                icon: Icons.share,
                label: 'Exportar',
                onTap: () {
                  onClose();
                  onExport();
                },
              ),
              _buildGridItem(
                icon: Icons.texture,
                label: 'Fondo',
                onTap: () {
                  onClose();
                  controller.cycleBackgroundPattern();
                },
              ),
              _buildGridItem(
                icon: Icons.layers,
                label: 'Nueva Capa',
                onTap: () {
                  onClose();
                  controller.addLayer();
                },
              ),
              _buildGridItem(
                icon: Icons.refresh,
                label: 'Limpiar',
                onTap: () {
                  onClose();
                  controller.clearActiveLayer();
                },
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
  }
}
