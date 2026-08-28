import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/gallery_provider.dart';
import '../../app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loca_screen.dart';
import '../../widgets/tap_tile.dart';

const _c = Color(0xFFFF66C4);
const _dark = Color(0xFF1A0A14);
const _galeriaTheme = ThemeSet(
  a: Color(0xFFFF66C4),
  b: Color(0xFFD84AA0),
  c: Color(0xFFB23BFF),
  d: Color(0xFF993355),
  e: Color(0xFF3D1028),
  dark: Color(0xFF1A0A14),
  light: Color(0xFFFFFFFF),
  mid: Color(0xFF2A1422),
);

/// Galería estilo "Nosotros": un bloque-foto por foto (thumbnail en mosaico);
/// subir (+) fija en la columna lateral. Tap → detalle a pantalla completa
/// (descripción, reacciones, comentarios).
class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});
  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  int? _fullScreenId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<GalleryProvider>().load());
  }

  Future<void> _pickAndUpload() async {
    HapticFeedback.heavyImpact();
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 70);
    if (file == null) return;
    await context.read<GalleryProvider>().uploadAndAdd(file.path, album: null, label: 'Foto');
    final err = context.read<GalleryProvider>().error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err, style: GoogleFonts.bangers(fontSize: 12)), backgroundColor: const Color(0xFFFF4444), duration: const Duration(seconds: 4)));
    }
  }

  ImageProvider? _getImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) return MemoryImage(base64Decode(url.split(',').last));
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_fullScreenId != null) return _fullScreenView();
    return Consumer<GalleryProvider>(
      builder: (context, pv, _) {
        final items = pv.items;
        final entries = <LocaEntry>[
          if (pv.hasError)
            LocaEntry(icon: Icons.cloud_off, color: const Color(0xFFFF4444), onTap: () => context.read<GalleryProvider>().load()),
          // Mientras carga (sin cache) mostrar un tile en vez de vacío absoluto
          // (antes se veía igual a "no hay fotos" y a "rompió").
          if (pv.loading && items.isEmpty)
            LocaEntry(icon: Icons.hourglass_top, color: _c, iconColor: _dark),
          if (!pv.loading && !pv.hasError && items.isEmpty)
            LocaEntry(icon: Icons.camera_alt, color: _c, iconColor: _dark),
          for (var i = 0; i < items.length; i++)
            LocaEntry(
              icon: Icons.camera_alt,
              color: _c,
              iconColor: _dark,
              childBuilder: (_) => _photoTile(items[i]),
              onTap: () {
                if (_fullScreenId == null) {
                  setState(() => _fullScreenId = items[i].id);
                  if (items[i].id != null) context.read<GalleryProvider>().loadComments(items[i].id!);
                }
              },
            ),
          LocaEntry(
            icon: Icons.add_a_photo,
            color: _c,
            iconColor: _dark,
            label: 'subir',
            onTap: _pickAndUpload,
            isAction: true,
          ),
        ];
        return LocaScreen(
          seed: 47,
          theme: _galeriaTheme,
          entries: entries,
        );
      },
    );
  }

  Widget _photoTile(GalleryItem item) {
    final img = _getImage(item.url);
    final myInitial = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
    final partnerInitial = myInitial == 'F' ? 'R' : 'F';
    final ownerInitial = item.userId == AppState.myId ? myInitial : partnerInitial;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(fit: StackFit.expand, children: [
        if (img != null)
          Image(image: img, fit: BoxFit.cover),
        if (img == null)
          Center(child: Icon(Icons.broken_image, color: _dark.withValues(alpha: 0.3), size: 40)),
        Positioned(left: 4, top: 4, child: Container(
          width: 18, height: 18, alignment: Alignment.center,
          decoration: BoxDecoration(color: _dark.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
          child: Text(ownerInitial, style: GoogleFonts.bangers(color: _c, fontSize: 10, fontWeight: FontWeight.w900)),
        )),
      ]),
    );
  }

  Widget _fullScreenView() {
    final items = context.read<GalleryProvider>().items;
    final item = items.firstWhere((i) => i.id == _fullScreenId, orElse: () => GalleryItem(url: '', type: 'photo'));
    final img = _getImage(item.url);
    return Scaffold(backgroundColor: _dark, body: SafeArea(child: Stack(children: [
      Positioned.fill(child: img != null ? Image(image: img, fit: BoxFit.cover) : Icon(Icons.broken_image, color: _c, size: 80)),
      Positioned.fill(child: Container(color: const Color(0xFF000000).withValues(alpha: 0.45))),
      Align(alignment: Alignment.bottomCenter, child: _detailPanel(item)),
      Positioned(left: 12, top: 8, child: TapTile(onTap: () => setState(() => _fullScreenId = null), child: Container(width: 44, height: 44, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.arrow_back, color: Color(0xFF000000), size: 26)))),
      Positioned(right: 12, top: 8, child: TapTile(onTap: () async {
        final pv = context.read<GalleryProvider>();
        await pv.delete(_fullScreenId!);
        if (mounted) setState(() => _fullScreenId = null);
        final err = pv.error;
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err, style: GoogleFonts.bangers(fontSize: 12)), backgroundColor: const Color(0xFFFF4444), duration: const Duration(seconds: 4)));
        }
      }, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFF4444), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.delete, color: Colors.white, size: 24)))),
    ])));
  }

  Widget _detailPanel(GalleryItem item) {
    final pv = context.read<GalleryProvider>();
    final comments = pv.commentsFor(item.id);
    return Container(width: double.infinity, constraints: const BoxConstraints(maxHeight: 260), padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(color: Color(0xFF1A0A14), border: Border(top: BorderSide(color: Color(0xFF1A0A14), width: 2))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _descriptionRow(pv, item),
        if (comments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Flexible(child: ListView.builder(shrinkWrap: true, itemCount: comments.length, itemBuilder: (context, i) {
            final c = comments[i];
            return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_initialOf(c.userId), style: GoogleFonts.bangers(color: _c, fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(width: 6),
              Expanded(child: Text(c.content, style: GoogleFonts.bangers(color: Colors.white, fontSize: 12))),
              GestureDetector(onTap: () { if (c.id != null) pv.deleteComment(c.id!); }, child: Icon(Icons.close, color: const Color(0xFFFF4444), size: 14)),
            ]));
          })),
        ],
        const SizedBox(height: 8),
        _reactionsRow(pv, item),
        Row(children: [
          Expanded(child: TextField(
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(hintText: 'comentar...', hintStyle: GoogleFonts.bangers(color: Colors.white24, fontSize: 13),
              filled: true, fillColor: const Color(0xFF2A1422), isDense: true,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            onSubmitted: (t) { if (t.trim().isNotEmpty && item.id != null) pv.addComment(item.id!, t); },
          )),
        ]),
      ]));
  }

  String _initialOf(String? userId) {
    final mine = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
    if (userId == AppState.myId) return mine;
    return mine == 'F' ? 'R' : 'F';
  }

  Widget _descriptionRow(GalleryProvider pv, GalleryItem item) {
    final text = item.description ?? '';
    return Row(children: [
      Expanded(child: text.isEmpty
          ? Text('sin descripcion', style: GoogleFonts.bangers(color: Colors.white24, fontSize: 13))
          : Text(text, style: GoogleFonts.bangers(color: Colors.white, fontSize: 15))),
      TapTile(onTap: () => _editDescription(pv, item), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit, color: Color(0xFF000000), size: 20))),
    ]);
  }

  void _editDescription(GalleryProvider pv, GalleryItem item) {
    final ctrl = TextEditingController(text: item.description ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF2A1422),
      content: TextField(controller: ctrl, autofocus: true, maxLines: 3, style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(hintText: 'descripcion', hintStyle: GoogleFonts.bangers(color: Colors.white24, fontSize: 15),
          filled: true, fillColor: const Color(0xFF1A0A14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
      actions: [
        TapTile(onTap: () => Navigator.pop(ctx), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF2A1422), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.close, color: Colors.white, size: 22))),
        TapTile(onTap: () { if (item.id != null) pv.updateDescription(item.id!, ctrl.text); Navigator.pop(ctx); }, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.check, color: Color(0xFF000000), size: 22))),
      ],
    ));
  }

  Widget _reactionsRow(GalleryProvider pv, GalleryItem item) {
    final emojis = ['😍', '🥰', '😘', '🔥', '❤️', ':0'];
    return Row(children: [
      Wrap(spacing: 6, children: emojis.map((e) {
        final active = item.reactions[e]?.isNotEmpty ?? false;
        return TapTile(onTap: () { if (item.id != null) pv.toggleReaction(item.id!, e); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: active ? _c : const Color(0xFF2A1422), borderRadius: BorderRadius.circular(10)), child: Text(e, style: const TextStyle(fontSize: 16))));
      }).toList()),
    ]);
  }
}