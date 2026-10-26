import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../providers/gallery_provider.dart';
import '../controllers/comic_controller.dart';
import '../services/comic_storage_service.dart';

/// Diálogo para previsualizar y exportar la página del cómic en alta resolución.
class ComicExportDialog extends StatefulWidget {
  final ComicController controller;

  const ComicExportDialog({super.key, required this.controller});

  @override
  State<ComicExportDialog> createState() => _ComicExportDialogState();
}

class _ComicExportDialogState extends State<ComicExportDialog> {
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
      final bytes = await widget.controller.exportPageToPng(
        widget.controller.activePageIndex,
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
          _statusMessage = 'Error al renderizar página';
        });
      }
    }
  }

  Future<void> _saveLocal() async {
    if (_imageBytes == null) return;
    setState(() => _isSaving = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final comicDir = Directory('${dir.path}/furi_comics/exports');
      if (!await comicDir.exists()) {
        await comicDir.create(recursive: true);
      }

      final fileName = 'comic_p${widget.controller.activePageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${comicDir.path}/$fileName');
      await file.writeAsBytes(_imageBytes!);

      await ComicStorageService.saveProject(widget.controller.project);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = '¡Página guardada con éxito en tu dispositivo!';
        });
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
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/comic_upload_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(_imageBytes!);

      if (!mounted) return;
      final gallery = Provider.of<GalleryProvider>(context, listen: false);
      final label = 'Pág ${widget.controller.activePageIndex + 1} de ${widget.controller.project.title}';
      await gallery.uploadAndAdd(tempFile.path, album: 'Cómics', label: label);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = '¡Publicado con éxito en la Galería de Pareja!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Error al publicar en galería: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EXPORTAR PÁGINA',
                  style: GoogleFonts.bangers(fontSize: 22, color: Colors.white, letterSpacing: 1),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vista previa
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)))
                  : _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                        )
                      : const Center(
                          child: Text('No se pudo generar la imagen', style: TextStyle(color: Colors.white54)),
                        ),
            ),
            const SizedBox(height: 12),

            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF39FF14), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Botón Guardar en Local
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving || _isLoading ? null : _saveLocal,
              icon: const Icon(Icons.download, size: 20),
              label: const Text(
                'GUARDAR EN DISPOSITIVO',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 8),

            // Botón Compartir en Galería
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF00FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving || _isLoading ? null : _shareToGallery,
              icon: const Icon(Icons.favorite, size: 20),
              label: const Text(
                'COMPARTIR EN NUESTRA GALERÍA',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
