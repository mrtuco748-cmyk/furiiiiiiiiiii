import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/gallery_provider.dart';
import 'galeria_reactions_row.dart';
import 'galeria_comments_list.dart';
import 'galeria_comment_input.dart';

class GaleriaDetailView extends StatelessWidget {
  final GalleryProvider provider;
  final GalleryItem item;
  final ImageProvider? image;
  final ScrollController scrollController;
  final TextEditingController commentController;
  final VoidCallback onBack;
  final ValueChanged<int> onSendComment;
  final ValueChanged<int> onDeletePhoto;

  const GaleriaDetailView({
    super.key,
    required this.provider,
    required this.item,
    required this.image,
    required this.scrollController,
    required this.commentController,
    required this.onBack,
    required this.onSendComment,
    required this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final comments = provider.commentsFor(item.id);

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
                    onTap: onBack,
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
                        if (confirm == true && item.id != null) {
                          onDeletePhoto(item.id!);
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
                controller: scrollController,
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
                      child: image != null
                          ? Image(
                              key: ValueKey('detail_img_${item.id}'),
                              image: image!,
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
                    GaleriaReactionsRow(provider: provider, item: item),
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

                    // Lista de comentarios extraída
                    GaleriaCommentsList(
                      comments: comments,
                      provider: provider,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // BARRA INFERIOR DE ENVÍO DE COMENTARIOS
            GaleriaCommentInput(
              controller: commentController,
              onSend: () {
                if (item.id != null) onSendComment(item.id!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
