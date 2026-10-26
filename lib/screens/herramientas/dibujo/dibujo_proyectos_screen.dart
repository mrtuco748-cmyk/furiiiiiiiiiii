import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../comic/widgets/comic_drawing_thumbnail.dart';
import '../widgets/canvas_dimensions_dialog.dart';
import 'dibujo_screen.dart';
import 'models/drawing_layer.dart';
import 'models/drawing_project.dart';
import 'services/drawing_storage_service.dart';

/// Pantalla de galería y proyectos de dibujo digital:
/// Muestra todos los lienzos guardados y una barra superior con botón '+' para crear.
class DibujoProyectosScreen extends StatefulWidget {
  const DibujoProyectosScreen({super.key});

  @override
  State<DibujoProyectosScreen> createState() => _DibujoProyectosScreenState();
}

class _DibujoProyectosScreenState extends State<DibujoProyectosScreen> {
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

  Future<void> _createNewDrawing() async {
    final size = await CanvasDimensionsDialog.show(context);
    if (size == null || !mounted) return;

    final newProj = DrawingProject(
      id: 'draw_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Dibujo ${_projects.length + 1}',
      canvasWidth: size.width,
      canvasHeight: size.height,
      layers: [DrawingLayer(id: 'layer_1', name: 'Capa 1', strokes: [])],
    );
    await DrawingStorageService.saveProject(newProj);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DibujoScreen(project: newProj, canvasSize: size)),
    );
    _load();
  }

  Future<void> _openProject(DrawingProject proj) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DibujoScreen(
          project: proj,
          canvasSize: Size(proj.canvasWidth, proj.canvasHeight),
        ),
      ),
    );
    _load();
  }

  Future<void> _renameProject(DrawingProject proj) async {
    final textController = TextEditingController(text: proj.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Renombrar Dibujo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Título del dibujo',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF282828),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
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
      await DrawingStorageService.saveProject(proj.copyWith(title: newTitle));
      _load();
    }
  }

  Widget _buildProjectCard(DrawingProject proj) {
    return GestureDetector(
      onTap: () => _openProject(proj),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Miniatura sobre lienzo blanco limpio
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  color: Colors.white,
                  child: ComicDrawingThumbnail(project: proj),
                ),
              ),
            ),
            // Pie con título y menú de opciones
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          proj.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${proj.canvasWidth.round()}x${proj.canvasHeight.round()} • ${proj.layers.length} cap.',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                    color: const Color(0xFF282828),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) async {
                      if (val == 'rename') _renameProject(proj);
                      if (val == 'duplicate') { await DrawingStorageService.duplicateProject(proj.id); _load(); }
                      if (val == 'delete') { await DrawingStorageService.deleteProject(proj.id); _load(); }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'rename', child: Text('Renombrar', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'duplicate', child: Text('Duplicar', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Color(0xFFFF453A)))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior brutalista con botón '+' destacado
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'MIS DIBUJOS',
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 26, letterSpacing: 1.2),
                    ),
                  ),
                  // Botón '+' para crear nuevo lienzo con dimensiones
                  GestureDetector(
                    onTap: _createNewDrawing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Color(0xFF111111), size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'NUEVO',
                            style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido: Cargando, Vacío o Grilla de Dibujos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)))
                  : _projects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.draw, size: 40, color: Color(0xFF00D4FF)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'NO HAY DIBUJOS AÚN',
                                style: GoogleFonts.bangers(color: Colors.white, fontSize: 22, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Creá tu primer lienzo con dimensiones personalizadas.',
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00D4FF),
                                  foregroundColor: const Color(0xFF111111),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _createNewDrawing,
                                icon: const Icon(Icons.add),
                                label: Text('CREAR LIENZO', style: GoogleFonts.bangers(fontSize: 16)),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: _projects.length,
                          itemBuilder: (context, i) => _buildProjectCard(_projects[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
