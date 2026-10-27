import 'package:flutter/material.dart';
import '../models/comic_project.dart';
import 'comic_page_thumbnail.dart';

/// Tarjeta visual para un capítulo de cómic en la biblioteca.
class ComicChapterCard extends StatelessWidget {
  final ComicProject project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRename;

  const ComicChapterCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFF252525),
                child: ComicPageThumbnail(project: project),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${project.pages.length} pág.',
                        style: const TextStyle(
                          color: Color(0xFFFFDE59),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onRename != null) ...[
                            GestureDetector(
                              onTap: onRename,
                              child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFFFDE59)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          GestureContextPill(onDelete: onDelete),
                        ],
                      ),
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
}

/// Píldora de confirmación para eliminar un capítulo.
class GestureContextPill extends StatelessWidget {
  final VoidCallback onDelete;
  const GestureContextPill({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('¿Eliminar capítulo?', style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (ok == true) onDelete();
      },
      child: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
    );
  }
}
