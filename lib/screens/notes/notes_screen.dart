import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/note.dart';
import '../../../providers/notes_provider.dart';
import '../../../widgets/tap_tile.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildNotesGrid()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _fabKey,
        onPressed: () => _showNoteEditor(context, null),
        backgroundColor: const Color(0xFF9D00FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 24),
        label: Text('Nota', style: GoogleFonts.bangers(fontSize: 18)),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(Icons.note_add, color: const Color(0xFF9D00FF), size: 28),
          const SizedBox(width: 10),
          Text('Mis Notas',
              style: GoogleFonts.bangers(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Spacer(),
          Consumer<NotesProvider>(
            builder: (context, pv, _) {
              if (pv.notes.isEmpty) return const SizedBox.shrink();
              return TapTile(
                onTap: () => _showDeleteAllDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A0A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF2A0A2A), width: 2),
                  ),
                  child: const Icon(Icons.delete_sweep,
                      color: Color(0xFFFF5757), size: 20),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesGrid() {
    return Consumer<NotesProvider>(
      builder: (context, pv, _) {
        if (pv.loading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF9D00FF)));
        }
        if (pv.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
                const SizedBox(height: 12),
                TapTile(
                  onTap: pv.load,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D00FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF9D00FF), width: 2),
                    ),
                    child: const Icon(Icons.refresh,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          );
        }
        if (pv.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.note_outlined,
                    color: Colors.white38, size: 64),
                const SizedBox(height: 16),
                Text('Sin notas aún',
                    style: GoogleFonts.bangers(
                        color: Colors.white38, fontSize: 18)),
                const SizedBox(height: 8),
                Text('Toca el botón + para crear',
                    style: GoogleFonts.bangers(
                        color: Colors.white38.withValues(alpha: 0.5),
                        fontSize: 12)),
              ],
            ),
          );
        }
        final notes = pv.notes;
        final crossAxisCount = _getCrossAxisCount(context);
        return Padding(
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            padding: const EdgeInsets.all(8),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(
                note: note,
                onEdit: () => _showNoteEditor(context, note),
                onDelete: () => _showDeleteConfirm(context, note),
              );
            },
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return 4;
    if (w > 400) return 3;
    return 2;
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF9D00FF), width: 3)),
        title: Text('¿Borrar todas las notas?',
            style: GoogleFonts.bangers(
                color: Colors.white, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<NotesProvider>().deleteAll();
              Navigator.pop(ctx);
            },
            child: const Text('Borrar todo',
                style: TextStyle(color: Color(0xFFFF5757))),
          ),
        ],
      ),
    );
  }

  void _showNoteEditor(BuildContext context, Note? note) {
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    String selectedColor = note?.color ?? '#FFF9C4';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF9D00FF), width: 3)),
            title: Text(note == null ? 'Nueva Nota' : 'Editar Nota',
                style: GoogleFonts.bangers(
                    color: Colors.white, fontSize: 20)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.bangers(
                        color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Título...',
                      hintStyle:
                          GoogleFonts.bangers(color: Colors.white38, fontSize: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF9D00FF), width: 2)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF9D00FF), width: 3)),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    style: GoogleFonts.bangers(
                        color: Colors.white, fontSize: 14),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu nota...',
                      hintStyle:
                          GoogleFonts.bangers(color: Colors.white38, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF9D00FF), width: 2)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF9D00FF), width: 3)),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Color',
                      style: GoogleFonts.bangers(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._noteColors.map((color) {
                        final isSelected = selectedColor == color['hex'];
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedColor = color['hex']!;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(int.parse(color['hex']!.replaceFirst('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2A2A2A),
                                width: isSelected ? 3 : 2,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Icon(Icons.close, color: Colors.white70),
              ),
              if (note != null)
                TextButton(
                  onPressed: () {
                    context
                        .read<NotesProvider>()
                        .update(Note(
                          id: note.id,
                          title: titleCtrl.text,
                          content: contentCtrl.text,
                          color: selectedColor,
                          updatedAt: DateTime.now().toIso8601String(),
                        ));
                    Navigator.pop(ctx);
                  },
                  child: const Icon(Icons.save, color: Color(0xFF39FF14)),
                ),
              TextButton(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty || contentCtrl.text.isNotEmpty) {
                    context.read<NotesProvider>().add(Note(
                          title: titleCtrl.text,
                          content: contentCtrl.text,
                          color: selectedColor,
                          createdAt: DateTime.now().toIso8601String(),
                          updatedAt: DateTime.now().toIso8601String(),
                        ));
                  }
                  Navigator.pop(ctx);
                },
                child: const Icon(Icons.check, color: Color(0xFF39FF14)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF5757), width: 3)),
        title: Text('¿Borrar nota?',
            style: GoogleFonts.bangers(
                color: Colors.white, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<NotesProvider>().delete(note.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Borrar',
                style: TextStyle(color: Color(0xFFFF5757))),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(int.parse('0xFF${note.color.replaceFirst('#', '')}'));
    return GestureDetector(
      onLongPress: onDelete,
      child: TapTile(
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardColor, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.title.isNotEmpty)
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bangers(
                        color: _isLightColor(cardColor)
                            ? const Color(0xFF0A0A0A)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                if (note.title.isNotEmpty && note.content.isNotEmpty)
                  const SizedBox(height: 4),
                if (note.content.isNotEmpty)
                  Text(
                    note.content.length > 80
                        ? '${note.content.substring(0, 80)}...'
                        : note.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bangers(
                        color: _isLightColor(cardColor)
                            ? const Color(0xFF0A0A0A)
                            : Colors.white.withValues(alpha: 0.85),
                        fontSize: 12),
                  ),
                const Spacer(),
                if (note.updatedAt != null && note.updatedAt!.isNotEmpty)
                  Text(
                    _formatDate(note.updatedAt!),
                    style: GoogleFonts.bangers(
                        color: _isLightColor(cardColor)
                            ? const Color(0xFF0A0A0A)
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 10),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isLightColor(Color color) {
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue);
    return luminance > 128;
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

const _noteColors = [
  {'hex': '#FFF9C4', 'name': 'Amarillo'},
  {'hex': '#C8E6C9', 'name': 'Verde'},
  {'hex': '#BBDEFB', 'name': 'Azul'},
  {'hex': '#FFCDD2', 'name': 'Rojo'},
  {'hex': '#E1BEE7', 'name': 'Morado'},
  {'hex': '#FFE0B2', 'name': 'Naranja'},
  {'hex': '#B2DFDB', 'name': 'Turquesa'},
  {'hex': '#D7CCC8', 'name': 'Gris'},
];