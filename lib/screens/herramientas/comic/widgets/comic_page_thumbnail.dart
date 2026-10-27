import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../helpers/comic_image_cache.dart';
import '../models/comic_project.dart';
import '../painters/comic_page_painter.dart';

/// Previsualizador de la primera hoja de un cómic o historieta.
/// Si existe portada PNG en caché la despliega directamente;
/// en su defecto, renderiza vectorialmente la primera página (viñetas, fondos,
/// marcos, globos y dibujos incrustados).
class ComicPageThumbnail extends StatefulWidget {
  final ComicProject project;

  const ComicPageThumbnail({super.key, required this.project});

  @override
  State<ComicPageThumbnail> createState() => _ComicPageThumbnailState();
}

class _ComicPageThumbnailState extends State<ComicPageThumbnail> {
  final Map<String, ui.Image> _panelImages = {};

  @override
  void initState() {
    super.initState();
    _loadImagesIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ComicPageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id ||
        oldWidget.project.updatedAt != widget.project.updatedAt) {
      _loadImagesIfNeeded();
    }
  }

  void _loadImagesIfNeeded() {
    if (widget.project.pages.isNotEmpty && widget.project.coverImageBase64 == null) {
      ComicImageCache.decodeAll(
        widget.project.pages.first,
        _panelImages,
        () {
          if (mounted) setState(() {});
        },
      );
    }
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.auto_stories, color: Colors.white24, size: 36),
    );
  }

  Widget _buildVectorPreview() {
    if (widget.project.pages.isEmpty) return _buildPlaceholder();
    final firstPage = widget.project.pages.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: firstPage.backgroundColor,
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: ComicPagePainter(
              page: firstPage,
              panelImages: _panelImages,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.project.coverImageBase64;
    if (cover != null && cover.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(cover),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildVectorPreview(),
        );
      } catch (_) {
        return _buildVectorPreview();
      }
    }
    return _buildVectorPreview();
  }
}
