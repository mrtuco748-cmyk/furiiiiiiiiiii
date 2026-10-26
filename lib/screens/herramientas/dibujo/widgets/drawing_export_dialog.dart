import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../providers/gallery_provider.dart';
import '../controllers/drawing_controller.dart';
import '../services/drawing_storage_service.dart';

/// Diálogo modal para previsualizar y exportar el dibujo realizado:
/// 1. Guardar localmente en el dispositivo como archivo PNG.
/// 2. Publicar en la Galería compartida de la pareja (F.U.R.I).
class DrawingExportDialog extends StatefulWidget {
  final DrawingController controller;

  const DrawingExportDialog({super.key, required this.controller});

  @override
  State<DrawingExportDialog> createState() => _DrawingExportDialogState();
}

class _DrawingExportDialogState extends State<DrawingExportDialog> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _renderPreview();
  }

  Future<void> _renderPreview() async {
    try {
      final bytes = await widget.controller.exportToPng(
        size: const Size(1200, 1200),
      );
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error al renderizar el dibujo';
        });
      }
    }
  }

  Future<void> _saveLocal() async {
    if (_imageBytes == null) return;
    setState(() => _isSaving = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final furiDrawingsDir = Directory('${dir.path}/furi_drawings');
      if (!await furiDrawingsDir.exists()) {
        await furiDrawingsDir.create(recursive: true);
      }

      final fileName = 'furi_dibujo_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${furiDrawingsDir.path}/$fileName');
      await file.writeAsBytes(_imageBytes!);

      final base64Thumb = base64Encode(_imageBytes!);
      await DrawingStorageService.saveProject(
        widget.controller.toProject(thumbnailBase64: base64Thumb),
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = '¡Guardado con éxito!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dibujo guardado: $fileName'),
            backgroundColor: const Color(0xFF39FF14),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Error al guardar: $e';
        });
      }
    }
  }

  Future<void> _shareToGallery() async {
    if (_imageBytes == null) return;
    setState(() => _isSaving = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(_imageBytes!);

      if (mounted) {
        final galleryPv = context.read<GalleryProvider>();
        await galleryPv.uploadAndAdd(
          tempFile.path,
          album: 'Dibujos',
          label: '🎨',
        );

        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Dibujo compartido en la Galería de Pareja!'),
              backgroundColor: Color(0xFF00D4FF),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Error al compartir: $e';
        });
      }
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.bangers(color: textColor, fontSize: 16, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'EXPORTAR DIBUJO',
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 20),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white54, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Previsualización
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
                  : _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                      : const Center(
                          child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
                        ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusMessage!,
                style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            // Botones de acción
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
              )
            else ...[
              _buildActionButton(
                label: 'GUARDAR EN DISPOSITIVO',
                icon: Icons.download,
                color: const Color(0xFF39FF14),
                textColor: const Color(0xFF111111),
                onTap: _saveLocal,
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                label: 'COMPARTIR EN GALERÍA',
                icon: Icons.favorite,
                color: const Color(0xFF00D4FF),
                textColor: const Color(0xFF111111),
                onTap: _shareToGallery,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
