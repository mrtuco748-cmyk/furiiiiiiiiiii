import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/comic_page.dart';
import 'models/comic_project.dart';
import 'painters/comic_page_painter.dart';

/// Modo Lector inmersivo de cómics y manga:
/// Navegación fluida página a página, soporte vertical y horizontal, e interfaz de pantalla completa.
class ComicReaderScreen extends StatefulWidget {
  final ComicProject project;

  const ComicReaderScreen({super.key, required this.project});

  @override
  State<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showControls = true;
  Axis _scrollDirection = Axis.horizontal;
  final Map<String, ui.Image> _decodedImages = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.project.activePageIndex;
    _pageController = PageController(initialPage: _currentPage);
    _decodeAllImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _decodeAllImages() {
    for (final page in widget.project.pages) {
      for (final panel in page.panels) {
        if (panel.drawingPngBase64 != null && !_decodedImages.containsKey(panel.id)) {
          try {
            final bytes = base64Decode(panel.drawingPngBase64!);
            ui.decodeImageFromList(bytes, (img) {
              if (mounted) {
                setState(() => _decodedImages[panel.id] = img);
              }
            });
          } catch (_) {}
        }
      }
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Widget _buildPage(ComicPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const pageAspect = 1.0 / 1.414;
        double targetWidth = constraints.maxWidth;
        double targetHeight = targetWidth / pageAspect;

        if (targetHeight > constraints.maxHeight) {
          targetHeight = constraints.maxHeight;
          targetWidth = targetHeight * pageAspect;
        }

        final pageSize = Size(targetWidth, targetHeight);

        return Center(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            child: Container(
              width: pageSize.width,
              height: pageSize.height,
              color: page.backgroundColor,
              child: CustomPaint(
                size: pageSize,
                painter: ComicPagePainter(
                  page: page,
                  panelImages: _decodedImages,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = widget.project.pages.length;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Lector de Páginas
            PageView.builder(
              controller: _pageController,
              scrollDirection: _scrollDirection,
              itemCount: totalPages,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return _buildPage(widget.project.pages[index]);
              },
            ),

            // Barra Superior
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: const Color(0xFF141414).withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.bangers(fontSize: 20, color: Colors.white, letterSpacing: 0.8),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _scrollDirection == Axis.horizontal ? Icons.swap_vert : Icons.swap_horiz,
                            color: const Color(0xFF00D4FF),
                          ),
                          tooltip: _scrollDirection == Axis.horizontal
                              ? 'Cambiar a lectura vertical (Webtoon)'
                              : 'Cambiar a lectura horizontal (Manga)',
                          onPressed: () {
                            setState(() {
                              _scrollDirection = _scrollDirection == Axis.horizontal ? Axis.vertical : Axis.horizontal;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Barra Inferior de Navegación
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: const Color(0xFF141414).withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Text(
                          '${_currentPage + 1} / $totalPages',
                          style: const TextStyle(
                            color: Color(0xFFFFDE59),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (totalPages > 1)
                          Expanded(
                            child: SliderTheme(
                              data: const SliderThemeData(
                                thumbColor: Color(0xFF00D4FF),
                                activeTrackColor: Color(0xFF00D4FF),
                                inactiveTrackColor: Color(0xFF333333),
                              ),
                              child: Slider(
                                value: _currentPage.toDouble().clamp(0.0, (totalPages - 1).toDouble()),
                                min: 0,
                                max: (totalPages - 1).toDouble(),
                                divisions: totalPages - 1,
                                onChanged: (val) {
                                  final target = val.toInt();
                                  _pageController.jumpToPage(target);
                                },
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
