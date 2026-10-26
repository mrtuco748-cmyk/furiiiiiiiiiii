import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../dibujo/models/drawing_project.dart';
import '../../dibujo/services/drawing_storage_service.dart';
import 'comic_drawing_thumbnail.dart';

/// Modal para seleccionar e insertar un dibujo existente en una viñeta del cómic.
class ComicDrawingPickerSheet extends StatefulWidget {
  final ValueChanged<DrawingProject> onSelect;

  const ComicDrawingPickerSheet({super.key, required this.onSelect});

  @override
  State<ComicDrawingPickerSheet> createState() => _ComicDrawingPickerSheetState();
}

class _ComicDrawingPickerSheetState extends State<ComicDrawingPickerSheet> {
  List<DrawingProject> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DrawingStorageService.listProjects();
    if (mounted) {
      setState(() {
        _projects = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, color: Color(0xFF39FF14), size: 24),
              const SizedBox(width: 10),
              Text(
                'INSERTAR DIBUJO EN VIÑETA',
                style: GoogleFonts.bangers(fontSize: 22, color: Colors.white, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Toca un dibujo guardado para incrustarlo en la viñeta seleccionada:',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
                : _projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.draw_outlined, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            const Text(
                              'Aún no tienes dibujos guardados.',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Dibuja uno nuevo con "Dibujar en esta viñeta".',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              widget.onSelect(project);
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF262626),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ComicDrawingThumbnail(project: project),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      project.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
