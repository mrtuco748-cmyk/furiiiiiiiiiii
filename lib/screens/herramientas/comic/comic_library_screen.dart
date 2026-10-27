import 'package:flutter/material.dart';
import 'comic_editor_screen.dart';
import 'models/comic_page.dart';
import 'models/comic_project.dart';
import 'models/comic_template.dart';
import 'services/comic_storage_service.dart';
import 'widgets/comic_chapter_card.dart';

/// Pantalla de Biblioteca de Cómics organizada por carpetas (series) y capítulos.
class ComicLibraryScreen extends StatefulWidget {
  const ComicLibraryScreen({super.key});

  @override
  State<ComicLibraryScreen> createState() => _ComicLibraryScreenState();
}

class _ComicLibraryScreenState extends State<ComicLibraryScreen> {
  List<ComicProject> _allProjects = [];
  List<String> _folders = ['General'];
  String _selectedFolder = 'General';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final projects = await ComicStorageService.listProjects();
    final folders = await ComicStorageService.listFolders();
    if (!folders.contains('General')) folders.insert(0, 'General');

    if (mounted) {
      setState(() {
        _allProjects = projects;
        _folders = folders;
        if (!_folders.contains(_selectedFolder)) {
          _selectedFolder = _folders.first;
        }
        _isLoading = false;
      });
    }
  }

  List<ComicProject> get _currentFolderProjects =>
      _allProjects.where((p) => p.folderName == _selectedFolder).toList();

  Future<void> _createFolderDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nueva Carpeta / Serie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ej. Temporada 1, Manga, Tiras', hintStyle: const TextStyle(color: Colors.white38),
            filled: true, fillColor: const Color(0xFF282828),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFDE59), foregroundColor: Colors.black),
            onPressed: () { final v = ctrl.text.trim(); if (v.isNotEmpty) Navigator.pop(ctx, v); },
            child: const Text('CREAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        if (!_folders.contains(name)) _folders.add(name);
        _selectedFolder = name;
      });
    }
  }

  Future<void> _renameChapter(ComicProject proj) async {
    final textController = TextEditingController(text: proj.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Renombrar Capítulo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Título del capítulo', hintStyle: const TextStyle(color: Colors.white38),
            filled: true, fillColor: const Color(0xFF282828),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () { final t = textController.text.trim(); if (t.isNotEmpty) Navigator.of(ctx).pop(t); },
            child: const Text('Guardar', style: TextStyle(color: Color(0xFFFFDE59), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await ComicStorageService.saveProject(proj.copyWith(title: newTitle));
      _loadData();
    }
  }

  Future<void> _createNewChapter() async {
    final titleCtrl = TextEditingController(text: 'Capítulo ${_currentFolderProjects.length + 1}');
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuevo Capítulo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Título del Capítulo',
            labelStyle: const TextStyle(color: Color(0xFFFFDE59)),
            filled: true,
            fillColor: const Color(0xFF282828),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39FF14), foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('COMENZAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (res == true && mounted) {
      final title = titleCtrl.text.trim().isEmpty ? 'Nuevo Capítulo' : titleCtrl.text.trim();
      final newProj = ComicProject(
        id: 'comic_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        folderName: _selectedFolder,
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
      await ComicStorageService.saveProject(newProj);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComicEditorScreen(initialProject: newProj)));
      _loadData();
    }
  }

  Future<void> _openComic(ComicProject project) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComicEditorScreen(initialProject: project)));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('BIBLIOTECA DE CÓMIC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, color: Color(0xFFFFDE59)),
            tooltip: 'Nueva Carpeta',
            onPressed: _createFolderDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Color(0xFF39FF14)),
            tooltip: 'Nuevo Capítulo',
            onPressed: _createNewChapter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFDE59)))
          : Column(
              children: [
                _buildFolderBar(),
                Expanded(child: _buildChapterGrid()),
              ],
            ),
    );
  }

  Widget _buildFolderBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _folders.map((folder) {
            final isSelected = folder == _selectedFolder;
            final count = _allProjects.where((p) => p.folderName == folder).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$folder ($count)'),
                selected: isSelected,
                selectedColor: const Color(0xFFFFDE59),
                backgroundColor: const Color(0xFF282828),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => _selectedFolder = folder),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChapterGrid() {
    final list = _currentFolderProjects;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories, size: 64, color: Colors.white24),
            const SizedBox(height: 12),
            Text('No hay capítulos en "$_selectedFolder"', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFDE59), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('CREAR PRIMER CAPÍTULO', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _createNewChapter,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return ComicChapterCard(
          project: p,
          onTap: () => _openComic(p),
          onRename: () => _renameChapter(p),
          onDelete: () async {
            await ComicStorageService.deleteProject(p.id);
            _loadData();
          },
        );
      },
    );
  }
}
