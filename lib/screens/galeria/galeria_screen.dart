import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/gallery_provider.dart';
import '../../app_state.dart';
import '../../router.dart';

/// Galería de fotos con lienzo infinito / scroll infinito estilo Pinterest
/// en 3 columnas de diferentes tamaños y formas, con vista de detalle
/// (foto arriba, comentarios abajo y envío optimista instantáneo).
class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  int? _selectedPhotoId;
  GalleryItem? _lastSelectedPhoto;
  final TextEditingController _commentCtrl = TextEditingController();
  final ScrollController _detailScrollCtrl = ScrollController();
  static final Map<String, ImageProvider> _imageCache = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<GalleryProvider>().load());
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _detailScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;

    await context.read<GalleryProvider>().uploadAndAdd(
      file.path,
      album: null,
      label: 'Foto',
    );
    final err = context.read<GalleryProvider>().error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          backgroundColor: const Color(0xFFFF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  ImageProvider? _getImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }
    ImageProvider provider;
    if (url.startsWith('data:')) {
      final base64String = url.split(',').last;
      provider = MemoryImage(base64Decode(base64String));
    } else {
      provider = NetworkImage(url);
    }
    _imageCache[url] = provider;
    return provider;
  }

  double _getAspectRatio(int index) {
    // Variedad de alturas / proporciones estilo Pinterest (tall, square, wide, medium)
    switch (index % 5) {
      case 0:
        return 0.75; // Alta
      case 1:
        return 1.0; // Cuadrada
      case 2:
        return 1.35; // Apaisada
      case 3:
        return 0.85; // Media-alta
      case 4:
      default:
        return 1.15; // Estándar
    }
  }

  void _sendComment(int photoId) {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    HapticFeedback.lightImpact();

    context.read<GalleryProvider>().addComment(photoId, text);

    // Scroll suave hacia abajo para ver el nuevo comentario
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_detailScrollCtrl.hasClients) {
        _detailScrollCtrl.animateTo(
          _detailScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryProvider>(
      builder: (context, pv, _) {
        if (_selectedPhotoId != null) {
          final item = pv.items.firstWhere(
            (i) => i.id == _selectedPhotoId,
            orElse: () => _lastSelectedPhoto ?? GalleryItem(url: '', type: 'photo'),
          );
          if (item.url.isNotEmpty) {
            _lastSelectedPhoto = item;
          }
          return _buildPinterestDetail(pv, item);
        }

        return Scaffold(
          backgroundColor: const Color(0xFF141414), // Fondo sólido sin negro puro
          body: SafeArea(
            child: Column(
              children: [
                // Encabezado limpio de la Galería
                _buildHeader(pv),

                // Lienzo infinito con scroll vertical de 3 columnas (Pinterest)
                Expanded(
                  child: pv.loading && pv.items.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF1493),
                          ),
                        )
                      : pv.items.isEmpty
                          ? _buildEmptyState()
                          : _buildPinterestGrid(pv),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFFF1493),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: _pickAndUpload,
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(GalleryProvider pv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Botón Atrás
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF222222),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Título
          Text(
            'GALERÍA',
            style: GoogleFonts.bangers(
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),

          // Badge con conteo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${pv.items.length}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF66C4),
              ),
            ),
          ),

          const Spacer(),

          // Botón temático Pinterest (Abre la vista integrada)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(RouterRoutes.pinterest);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE60023), // Rojo sólido Pinterest
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.push_pin_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Pinterest',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón refrescar
          GestureDetector(
            onTap: () => pv.load(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF222222),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF222222),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 36,
              color: Color(0xFFFF66C4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no hay fotos en el lienzo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca el botón rosa para subir recuerdos juntos',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinterestGrid(GalleryProvider pv) {
    final items = pv.items;

    // Distribuir en 3 columnas de cascada (Pinterest layout)
    final col0 = <int>[];
    final col1 = <int>[];
    final col2 = <int>[];

    for (var i = 0; i < items.length; i++) {
      if (i % 3 == 0) {
        col0.add(i);
      } else if (i % 3 == 1) {
        col1.add(i);
      } else {
        col2.add(i);
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 90),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildColumnPins(pv, col0)),
          const SizedBox(width: 8),
          Expanded(child: _buildColumnPins(pv, col1)),
          const SizedBox(width: 8),
          Expanded(child: _buildColumnPins(pv, col2)),
        ],
      ),
    );
  }

  Widget _buildColumnPins(GalleryProvider pv, List<int> indexes) {
    return Column(
      children: indexes.map((idx) {
        final item = pv.items[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildPinterestPin(item, idx),
        );
      }).toList(),
    );
  }

  Widget _buildPinterestPin(GalleryItem item, int index) {
    final img = _getImage(item.url);
    final ratio = _getAspectRatio(index);

    final isMine = item.userId == AppState.myId;
    final initial = isMine
        ? (AppState.identity?.substring(0, 1).toUpperCase() ?? 'F')
        : (AppState.identity?.toUpperCase().startsWith('F') == true ? 'R' : 'F');
    final tagColor = isMine ? const Color(0xFF00F0FF) : const Color(0xFFFF1493);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPhotoId = item.id);
        if (item.id != null) {
          context.read<GalleryProvider>().loadComments(item.id!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Bloque sólido sin bordes
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (img != null)
                Image(
                  image: img,
                  fit: BoxFit.cover,
                )
              else
                const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white24,
                    size: 28,
                  ),
                ),

              // Badge de autor
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: tagColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.bangers(
                        color: const Color(0xFF121212),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Reacciones al pie si existen
              if (item.reactions.isNotEmpty)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 11,
                          color: Color(0xFFFF1493),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${item.reactions.values.fold<int>(0, (sum, list) => sum + list.length)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DETALLE ESTILO PINTEREST (Foto arriba, comentarios abajo y envío optimista) ---
  Widget _buildPinterestDetail(GalleryProvider pv, GalleryItem item) {
    final img = _getImage(item.url);
    final comments = pv.commentsFor(item.id);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior del detalle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedPhotoId = null),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF222222),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.id != null)
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: Text(
                              '¿Eliminar foto?',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'Esta foto se borrará del lienzo.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: Color(0xFFFF4444)),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await pv.delete(item.id!);
                          setState(() => _selectedPhotoId = null);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2A1C1C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFFF5252),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Contenido escroleable: Foto ARRIBA, Comentarios ABAJO (como Pinterest)
            Expanded(
              child: SingleChildScrollView(
                controller: _detailScrollCtrl,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // FOTO PRINCIPAL ARRIBA
                    Container(
                      key: ValueKey('detail_wrap_${item.id}'),
                      constraints: const BoxConstraints(maxHeight: 420),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: img != null
                          ? Image(
                              key: ValueKey('detail_img_${item.id}'),
                              image: img,
                              fit: BoxFit.contain,
                            )
                          : const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white24,
                                size: 60,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Barra de reacciones con emojis
                    _buildReactionsRow(pv, item),
                    const SizedBox(height: 14),

                    // SECCIÓN DE COMENTARIOS ABAJO (ESTILO PINTEREST)
                    Row(
                      children: [
                        Text(
                          'Comentarios',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF242424),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${comments.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF66C4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Lista de comentarios
                    if (comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Sé el primero en comentar esta foto 💕',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = comments[i];
                          final isMine = c.userId == AppState.myId;
                          final initial = isMine
                              ? (AppState.identity?.substring(0, 1).toUpperCase() ?? 'F')
                              : (AppState.identity?.toUpperCase().startsWith('F') == true
                                  ? 'R'
                                  : 'F');
                          final userColor = isMine
                              ? const Color(0xFF00F0FF)
                              : const Color(0xFFFF1493);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E), // Bloque sólido sin bordes
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar inicial
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: userColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.bangers(
                                        color: const Color(0xFF121212),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Texto del comentario
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMine
                                            ? 'Tú'
                                            : (AppState.identity == 'Facu'
                                                ? 'Rocío'
                                                : 'Facu'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: userColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        c.content,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Botón eliminar si es mío
                                if (isMine && c.id != null)
                                  GestureDetector(
                                    onTap: () => pv.deleteComment(c.id!),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // BARRA INFERIOR DE ENVÍO DE COMENTARIOS (OPTIMISTA E INSTANTÁNEO)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentCtrl,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Añadir un comentario...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) {
                          if (item.id != null) _sendComment(item.id!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botón Enviar destacado en rosa sólido
                  GestureDetector(
                    onTap: () {
                      if (item.id != null) _sendComment(item.id!);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF1493),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsRow(GalleryProvider pv, GalleryItem item) {
    final emojis = ['❤️', '🔥', '😍', '🥰', '✨'];

    return Row(
      children: emojis.map((e) {
        final active = item.reactions[e]?.isNotEmpty ?? false;
        final count = item.reactions[e]?.length ?? 0;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (item.id != null) {
                HapticFeedback.selectionClick();
                pv.toggleReaction(item.id!, e);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF1493)
                    : const Color(0xFF222222), // Bloque sólido sin bordes
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e, style: const TextStyle(fontSize: 16)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}