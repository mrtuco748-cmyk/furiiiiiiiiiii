import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../comic/widgets/comic_drawing_thumbnail.dart';
import '../controllers/drawing_controller.dart';
import '../models/drawing_project.dart';
import '../services/drawing_storage_service.dart';

/// Modal para explorar, abrir, duplicar y gestionar lienzos y proyectos de dibujo guardados.
class DrawingProjectsSheet extends StatefulWidget {
  final DrawingController controller;

  const DrawingProjectsSheet({super.key, required this.controller});

  @override
  State<DrawingProjectsSheet> createState() => _DrawingProjectsSheetState();
}

class _DrawingProjectsSheetState extends State<DrawingProjectsSheet> {
  List<DrawingProject> _projects = [];
  bool _isLoading = true;

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
        _isLoading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    await DrawingStorageService.deleteProject(id);
    _load();
  }

  Future<void> _duplicate(String id) async {
    await DrawingStorageService.duplicateProject(id);
    _load();
  }

  Future<void> _rename(DrawingProject proj) async {
    final textController = TextEditingController(text: proj.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF00D4FF), size: 20),
            SizedBox(width: 8),
            Text('Renombrar Dibujo', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Nombre del proyecto',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF282828),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final trimmed = textController.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(ctx).pop(trimmed);
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      await DrawingStorageService.saveProject(proj.copyWith(title: newTitle));
      if (widget.controller.projectId == proj.id) {
        widget.controller.setTitle(newTitle);
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'MIS DIBUJOS (${_projects.length})',
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 22, letterSpacing: 0.8),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    widget.controller.loadProject(DrawingProject(
                      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
                      title: 'Nuevo Dibujo',
                      layers: [],
                    ));
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16, color: Color(0xFF111111)),
                        const SizedBox(width: 4),
                        Text(
                          'NUEVO',
                          style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
                ),
              )
            else if (_projects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No hay dibujos guardados aún.\nGuarda tu lienzo actual con el botón guardar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _projects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final proj = _projects[i];
                    final isCurrent = widget.controller.projectId == proj.id;

                    return GestureDetector(
                      onTap: () {
                        widget.controller.loadProject(proj);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF282828) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail sobre fondo blanco de lienzo
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ComicDrawingThumbnail(project: proj),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    proj.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${proj.layers.length} capas • ${proj.updatedAt.day}/${proj.updatedAt.month}/${proj.updatedAt.year}',
                                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // Botón renombrar
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF00D4FF)),
                              tooltip: 'Renombrar',
                              onPressed: () => _rename(proj),
                            ),
                            // Botón duplicar
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: Colors.white60),
                              tooltip: 'Duplicar',
                              onPressed: () => _duplicate(proj.id),
                            ),
                            // Botón eliminar
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5252)),
                              tooltip: 'Eliminar',
                              onPressed: () => _delete(proj.id),
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
      ),
    );
  }
}
