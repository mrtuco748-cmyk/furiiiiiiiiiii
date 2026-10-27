import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_page.dart';
import '../models/comic_project.dart';
import '../models/comic_template.dart';
import '../services/comic_storage_service.dart';
import 'comic_page_thumbnail.dart';

/// Modal para explorar, abrir, duplicar y gestionar cómics e historietas guardadas en el dispositivo.
class ComicProjectsSheet extends StatefulWidget {
  final ComicController controller;

  const ComicProjectsSheet({super.key, required this.controller});

  @override
  State<ComicProjectsSheet> createState() => _ComicProjectsSheetState();
}

class _ComicProjectsSheetState extends State<ComicProjectsSheet> {
  List<ComicProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ComicStorageService.listProjects();
    if (mounted) {
      setState(() {
        _projects = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    await ComicStorageService.deleteProject(id);
    _load();
  }

  Future<void> _duplicate(String id) async {
    await ComicStorageService.duplicateProject(id);
    _load();
  }

  Future<void> _rename(ComicProject proj) async {
    final textController = TextEditingController(text: proj.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFFFFDE59), size: 20),
            SizedBox(width: 8),
            Text('Renombrar Cómic', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Nombre de la historieta',
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
            child: const Text('Guardar', style: TextStyle(color: Color(0xFFFFDE59), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      final updated = proj.copyWith(title: newTitle);
      await ComicStorageService.saveProject(updated);
      if (widget.controller.project.id == proj.id) {
        widget.controller.setTitle(newTitle);
      }
      _load();
    }
  }

  void _createNew() {
    ComicStorageService.saveProject(widget.controller.project);
    final newProject = ComicProject(
      id: 'comic_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Nuevo Cómic',
      pages: [
        ComicPage(
          id: 'page_1',
          pageNumber: 1,
          panels: ComicTemplateType.fourKoma.createPanels(),
          bubbles: [],
          sfxStickers: [],
        ),
      ],
    );
    widget.controller.loadProject(newProject);
    Navigator.of(context).pop();
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
                  'MIS CÓMICS (${_projects.length})',
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 22, letterSpacing: 0.8),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _createNew,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDE59),
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
                  child: CircularProgressIndicator(color: Color(0xFFFFDE59)),
                ),
              )
            else if (_projects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No hay historietas guardadas aún.\nTus creaciones se guardan automáticamente al editar.',
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
                    final isCurrent = widget.controller.project.id == proj.id;

                    return GestureDetector(
                      onTap: () {
                        ComicStorageService.saveProject(widget.controller.project);
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
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ComicPageThumbnail(project: proj),
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
                                    '${proj.pages.length} páginas • ${proj.updatedAt.day}/${proj.updatedAt.month}/${proj.updatedAt.year}',
                                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFFFDE59)),
                              tooltip: 'Renombrar',
                              onPressed: () => _rename(proj),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: Colors.white60),
                              tooltip: 'Duplicar',
                              onPressed: () => _duplicate(proj.id),
                            ),
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
