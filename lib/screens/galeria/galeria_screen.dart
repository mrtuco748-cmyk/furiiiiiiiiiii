import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/gallery_provider.dart';
import '../../app_state.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';

const _c = Color(0xFFFF66C4);
const _dark = Color(0xFF000000);

class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});
  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  String? _selectedAlbum;
  int? _fullScreenId;
  bool _uploading = false;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<GalleryProvider>().load());
  }

  Future<void> _pickAndUpload() async {
    HapticFeedback.heavyImpact();
    final picker = ImagePicker();
    setState(() => _uploadStatus = 'Seleccionando...');
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 70);
    if (file == null) { setState(() => _uploadStatus = ''); return; }
    setState(() { _uploading = true; _uploadStatus = 'Subiendo...'; });
    await context.read<GalleryProvider>().uploadAndAdd(file.path, album: _selectedAlbum, label: 'Foto');
    final err = context.read<GalleryProvider>().error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err, style: GoogleFonts.bangers(fontSize: 12)), backgroundColor: const Color(0xFFFF4444), duration: const Duration(seconds: 4)));
    }
    if (mounted) setState(() { _uploading = false; _uploadStatus = ''; });
  }

  ImageProvider? _getImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) return MemoryImage(base64Decode(url.split(',').last));
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_fullScreenId != null) return _fullScreenView();
    return Scaffold(backgroundColor: _c, body: ResponsiveWrapper(builder: (context, w, h) {
      return SizedBox(width: w, height: h, child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
        _headerBar(w, h),
        _albumStrip(w, h),
        _mosaicBlock(w, h),
        _fab(w, h),
      ]));
    }));
  }

  Widget _fullScreenView() {
    final items = context.read<GalleryProvider>().items;
    final item = items.firstWhere((i) => i.id == _fullScreenId, orElse: () => GalleryItem(url: '', type: 'photo'));
    final img = _getImage(item.url);
    return Scaffold(backgroundColor: _dark, body: SafeArea(child: Stack(children: [
      Center(child: img != null ? Image(image: img, fit: BoxFit.contain, width: double.infinity, height: double.infinity) : Icon(Icons.broken_image, color: _c, size: 80)),
      Positioned(left: 12, top: 8, child: TapTile(onTap: () => setState(() => _fullScreenId = null), child: Container(width: 44, height: 44, decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.arrow_back, color: Color(0xFF000000), size: 26)))),
      Positioned(right: 12, top: 8, child: TapTile(onTap: () { context.read<GalleryProvider>().delete(_fullScreenId!); setState(() => _fullScreenId = null); }, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFF4444), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.delete, color: Colors.white, size: 24)))),
    ])));
  }

  Widget _headerBar(double w, double h) {
    final barH = h * 0.07;
    return Positioned(left: w * 0.03, top: h * 0.015, width: w * 0.94, height: barH, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, border: Border.all(color: _dark, width: 4), borderRadius: BorderRadius.circular(18)), child: Row(children: [
      Expanded(child: Center(child: Text('GALERIA', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 20, color: _dark)))),
      TapTile(onTap: _pickAndUpload, child: Container(width: barH, height: barH, decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.cloud_upload, color: Color(0xFFFF66C4), size: 24))),
    ]))));
  }

  Widget _albumStrip(double w, double h) {
    final barH = h * 0.07;
    return Positioned(left: w * 0.03, top: h * 0.015 + barH + h * 0.015, width: w * 0.94, height: h * 0.08,
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, border: Border.all(color: _dark, width: 3), borderRadius: BorderRadius.circular(18)),
        child: Consumer<GalleryProvider>(builder: (context, pv, _) {
          final albums = pv.albums;
          if (albums.isEmpty) return const Center(child: Icon(Icons.photo_album, color: Color(0xFF993355), size: 24));
          return ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), itemCount: albums.length, itemBuilder: (context, index) {
            final album = albums[index]; final selected = album == _selectedAlbum;
            return Padding(padding: const EdgeInsets.only(right: 8), child: TapTile(onTap: () { HapticFeedback.heavyImpact(); setState(() => _selectedAlbum = selected ? null : album); }, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: selected ? _dark : _c, border: Border.all(color: _dark, width: 2), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.photo_album, color: selected ? _c : _dark, size: 20), const SizedBox(width: 4), Text(album, style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 11, color: selected ? _c : _dark))])))));
          });
        }))));
  }

  Widget _mosaicBlock(double w, double h) {
    final barH = h * 0.07;
    final top = h * 0.015 + barH + h * 0.015 + h * 0.08 + h * 0.01;
    return Positioned(left: w * 0.03, top: top, width: w * 0.94, height: h * 0.70,
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, border: Border.all(color: _dark, width: 4), borderRadius: BorderRadius.circular(18)),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Consumer<GalleryProvider>(builder: (context, pv, _) {
          if (pv.loading || _uploading) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: _dark, strokeWidth: 4),
            if (_uploadStatus.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_uploadStatus, style: GoogleFonts.bangers(color: _dark, fontSize: 12))),
          ]));
          final items = _selectedAlbum != null ? pv.byAlbum(_selectedAlbum!) : pv.items;
          if (items.isEmpty) return Center(child: Icon(Icons.camera_alt, color: _dark.withValues(alpha: 0.3), size: 56));
          return GridView.builder(padding: const EdgeInsets.all(6), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6), itemCount: items.length, itemBuilder: (context, i) {
            final item = items[i];
            final myInitial = (AppState.identity?.substring(0, 1).toUpperCase() ?? '?');
            final partnerInitial = myInitial == 'F' ? 'R' : 'F';
            final ownerInitial = item.userId == AppState.myId ? myInitial : partnerInitial;
            final img = _getImage(item.url);
            return GestureDetector(onTap: () => setState(() => _fullScreenId = item.id), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(decoration: BoxDecoration(color: _c.withValues(alpha: 0.5), border: Border.all(color: _dark, width: 2), borderRadius: BorderRadius.circular(12)),
              child: Stack(children: [
                if (img != null) Positioned.fill(child: Image(image: img, fit: BoxFit.cover)),
                if (img == null) Center(child: Icon(Icons.broken_image, color: _dark.withValues(alpha: 0.3), size: 30)),
                Positioned(left: 4, top: 4, child: Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: _dark.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)), child: Text(ownerInitial, style: GoogleFonts.bangers(color: _c, fontSize: 10, fontWeight: FontWeight.w900)))),
                Positioned(right: 2, top: 2, child: GestureDetector(onTap: () { if (item.id != null) context.read<GalleryProvider>().delete(item.id!); }, child: Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFFFF4444).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.close, color: Colors.white, size: 14)))),
              ])),
            ));
          });
        })))),
    );
  }

  Widget _fab(double w, double h) {
    return Positioned(right: w * 0.05, bottom: h * 0.03, child: TapTile(onTap: _pickAndUpload, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(width: w * 0.13, height: w * 0.13, decoration: BoxDecoration(color: _dark, border: Border.all(color: _c, width: 4), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]), child: const Center(child: Icon(Icons.add_a_photo, color: Color(0xFFFF66C4), size: 28))))));
  }
}
