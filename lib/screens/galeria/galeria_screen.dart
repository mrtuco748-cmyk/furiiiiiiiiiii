import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/gallery_provider.dart';
import 'widgets/galeria_top_bar.dart';
import 'widgets/galeria_empty_state.dart';
import 'widgets/galeria_pin_card.dart';
import 'widgets/galeria_detail_view.dart';

/// Galería de fotos con lienzo infinito / scroll infinito estilo Pinterest
/// en 3 columnas de diferentes tamaños y formas, con vista de detalle modular.
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
    Future.microtask(() {
      if (mounted) context.read<GalleryProvider>().load();
    });
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
    if (!mounted) return;
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
    if (_imageCache.length > 30) {
      _imageCache.remove(_imageCache.keys.first);
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
    switch (index % 5) {
      case 0:
        return 0.75;
      case 1:
        return 1.0;
      case 2:
        return 1.35;
      case 3:
        return 0.85;
      case 4:
      default:
        return 1.15;
    }
  }

  void _sendComment(int photoId) {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    HapticFeedback.lightImpact();
    context.read<GalleryProvider>().addComment(photoId, text);
  }

  Future<void> _deletePhoto(int photoId) async {
    await context.read<GalleryProvider>().delete(photoId);
    if (mounted) {
      setState(() => _selectedPhotoId = null);
    }
  }

  Widget _buildPinterestGrid(GalleryProvider pv) {
    final items = pv.items;
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
          child: GaleriaPinCard(
            item: item,
            index: idx,
            image: _getImage(item.url),
            aspectRatio: _getAspectRatio(idx),
            onTap: () {
              setState(() => _selectedPhotoId = item.id);
              if (item.id != null) {
                context.read<GalleryProvider>().loadComments(item.id!);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<GalleryProvider>();

    if (_selectedPhotoId != null) {
      final currentItem = pv.items.where((i) => i.id == _selectedPhotoId).firstOrNull;
      if (currentItem != null) {
        _lastSelectedPhoto = currentItem;
      }
      final itemToRender = currentItem ?? _lastSelectedPhoto;

      if (itemToRender != null) {
        return GaleriaDetailView(
          provider: pv,
          item: itemToRender,
          image: _getImage(itemToRender.url),
          scrollController: _detailScrollCtrl,
          commentController: _commentCtrl,
          onBack: () => setState(() => _selectedPhotoId = null),
          onSendComment: _sendComment,
          onDeletePhoto: _deletePhoto,
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            GaleriaTopBar(
              provider: pv,
              onClearCache: () => _imageCache.clear(),
            ),
            Expanded(
              child: pv.loading && pv.items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF66C4),
                        strokeWidth: 2.5,
                      ),
                    )
                  : pv.items.isEmpty
                      ? const GaleriaEmptyState()
                      : _buildPinterestGrid(pv),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUpload,
        backgroundColor: const Color(0xFFFF1493),
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_a_photo_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
