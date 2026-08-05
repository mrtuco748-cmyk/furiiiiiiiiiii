import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/favorites_provider.dart';
import '../../app_state.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/concrete_painter.dart';

const _c = Color(0xFF9D00FF);
const _dark = Color(0xFF000000);
const _lightPurple = Color(0xFFD4A8FF);

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});
  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  String _selectedCategory = 'movie';
  bool _showOnlyFavorited = false;

  @override
  void initState() { super.initState(); Future.microtask(() => context.read<FavoritesProvider>().load()); }

  void _addOrEditFavorite({FavoriteItem? existing}) {
    double rating = existing?.rating ?? 0;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subCtrl = TextEditingController(text: existing?.subtitle ?? '');
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
      backgroundColor: _c,
      title: Text(existing != null ? 'EDITAR' : 'FAVORITO', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, color: _dark, fontSize: 22)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, autofocus: true, style: GoogleFonts.bangers(color: _dark, fontSize: 14), decoration: InputDecoration(hintText: 'titulo', hintStyle: GoogleFonts.bangers(color: _dark.withValues(alpha: 0.5), fontSize: 14), enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF000000))), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF000000), width: 2)))),
        const SizedBox(height: 10),
        TextField(controller: subCtrl, style: GoogleFonts.bangers(color: _dark, fontSize: 14), decoration: InputDecoration(hintText: 'subtitulo', hintStyle: GoogleFonts.bangers(color: _dark.withValues(alpha: 0.5), fontSize: 14), enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF000000))), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF000000), width: 2)))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Rating: ', style: GoogleFonts.bangers(color: _dark, fontSize: 14)),
          ...List.generate(5, (i) => GestureDetector(onTap: () => setLocal(() => rating = (i + 1).toDouble()), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Icon(rating >= i + 1 ? Icons.star : (rating >= i + 0.5 ? Icons.star_half : Icons.star_border), color: _dark, size: 28)))),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(onTap: () => setLocal(() => rating = i + 0.5), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Container(width: 10, height: 16, decoration: BoxDecoration(color: (i + 0.5) <= rating ? _dark : Colors.transparent, borderRadius: BorderRadius.circular(3))))))),
      ]),
      actions: [
        GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(14)), child: Text('X', style: GoogleFonts.bangers(color: _c, fontSize: 16)))),
        GestureDetector(onTap: () {
          if (titleCtrl.text.isEmpty) { Navigator.pop(ctx); return; }
          final pv = context.read<FavoritesProvider>();
          if (existing != null && existing.id != null) {
            pv.update(existing.id!, FavoriteItem(id: existing.id, category: existing.category, title: titleCtrl.text, subtitle: subCtrl.text.isNotEmpty ? subCtrl.text : null, emoji: existing.emoji, rating: rating, favorited: existing.favorited, userId: existing.userId));
          } else {
            pv.add(FavoriteItem(category: _selectedCategory, title: titleCtrl.text, subtitle: subCtrl.text.isNotEmpty ? subCtrl.text : null, emoji: FavoritesProvider.categoryEmojis[_selectedCategory] ?? '⭐', rating: rating));
          }
          Navigator.pop(ctx);
        }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(14)), child: Text(existing != null ? 'OK' : '+', style: GoogleFonts.bangers(color: _c, fontWeight: FontWeight.bold, fontSize: 18)))),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _c, body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth; final h = constraints.maxHeight;
      return SizedBox(width: w, height: h, child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
        _headerBar(w, h), _catMovie(w, h), _catSeries(w, h), _catGames(w, h), _catMusic(w, h),
        _contentBlock(w, h), _wishlistBlock(w, h),
      ]));
    })));
  }

  Widget _headerBar(double w, double h) {
    final barH = h * 0.07;
    return Positioned(left: w * 0.03, top: h * 0.015, width: w * 0.94, height: barH, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(18)), child: Row(children: [
      Expanded(child: Center(child: Text('FAVORITOS', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 20, color: _dark)))),
      TapTile(onTap: () => _addOrEditFavorite(), child: Container(width: barH, height: barH, decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.add, color: Color(0xFF9D00FF), size: 26))),
    ]))));
  }

  Widget _catBlock(String category, IconData icon, double left, double top, double w) {
    final selected = _selectedCategory == category;
    return Positioned(left: left, top: top, width: w * 0.22, height: w * 0.13, child: TapTile(onTap: () { HapticFeedback.heavyImpact(); setState(() => _selectedCategory = category); }, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(color: selected ? _c : _dark, border: Border.all(color: _dark, width: 4), borderRadius: BorderRadius.circular(16)),
      child: FittedBox(fit: BoxFit.contain, child: Padding(padding: const EdgeInsets.all(10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: selected ? _dark : _c, size: 28),
        Text(category.toUpperCase(), style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 9, color: selected ? _dark : _c)),
      ])))))));
  }

  Widget _catMovie(double w, double h) => _catBlock('movie', Icons.movie, w * 0.03, _topCats(h), w);
  Widget _catSeries(double w, double h) => _catBlock('series', Icons.tv, w * 0.26, _topCats(h) + h * 0.003, w);
  Widget _catGames(double w, double h) => _catBlock('game', Icons.sports_esports, w * 0.50, _topCats(h) - h * 0.003, w);
  Widget _catMusic(double w, double h) => _catBlock('music', Icons.music_note, w * 0.74, _topCats(h) + h * 0.005, w);
  double _topCats(double h) => h * 0.015 + h * 0.07 + h * 0.015;

  Widget _contentBlock(double w, double h) {
    final top = _topCats(h) + w * 0.13 + h * 0.015;
    return Positioned(left: w * 0.03, top: top, width: w * 0.94, height: h * 0.50, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, border: Border.all(color: _dark, width: 4), borderRadius: BorderRadius.circular(18)),
      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Consumer<FavoritesProvider>(builder: (context, pv, _) {
        if (pv.loading) return Center(child: CircularProgressIndicator(color: _dark, strokeWidth: 3));
        final items = pv.byCategory(_selectedCategory);
        final shown = _showOnlyFavorited ? items.where((i) => i.favorited).toList() : items;
        if (shown.isEmpty) return Center(child: Text(_showOnlyFavorited ? 'Sin guardados' : 'Vacio', style: GoogleFonts.bangers(color: _dark.withValues(alpha: 0.5), fontSize: 14)));
        return ListView.builder(padding: const EdgeInsets.all(8), itemCount: shown.length, itemBuilder: (context, index) => Padding(padding: const EdgeInsets.only(bottom: 6), child: _favCard(shown[index])));
      })))),
    );
  }

  Widget _favCard(FavoriteItem item) {
    final myInitial = AppState.identity?.substring(0,1).toUpperCase() ?? '?';
    final partnerInitial = myInitial == 'F' ? 'R' : 'F';
    final ownerInitial = item.userId == AppState.myId ? myInitial : partnerInitial;
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _lightPurple, border: Border.all(color: _c, width: 3), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(12), border: Border.all(color: _c, width: 2)), child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 16, height: 16, alignment: Alignment.center, decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(5)), child: Text(ownerInitial, style: GoogleFonts.bangers(color: _c, fontSize: 10, fontWeight: FontWeight.w900))), const SizedBox(width: 5), Expanded(child: Text(item.title, style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 13, color: _dark), maxLines: 1, overflow: TextOverflow.ellipsis))]),
          if (item.subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(item.subtitle!, style: GoogleFonts.bangers(fontSize: 10, color: _dark.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Row(children: _buildStarRow(item.rating)),
        ])),
        GestureDetector(onTap: () { if (item.id != null) context.read<FavoritesProvider>().toggleFav(item.id!, !item.favorited); }, child: Container(width: 30, height: 30, decoration: BoxDecoration(color: item.favorited ? _c : _dark, borderRadius: BorderRadius.circular(8), border: Border.all(color: _c, width: 2)), child: Icon(item.favorited ? Icons.favorite : Icons.favorite_border, color: item.favorited ? _dark : _c, size: 16))),
        const SizedBox(width: 2),
        GestureDetector(onTap: () => _addOrEditFavorite(existing: item), child: Icon(Icons.edit, color: _dark.withValues(alpha: 0.5), size: 14)),
        GestureDetector(onTap: () { if (item.id != null) context.read<FavoritesProvider>().delete(item.id!); }, child: const Padding(padding: EdgeInsets.only(left: 2), child: Icon(Icons.close, color: Color(0xFFFF4444), size: 16))),
      ]),
    ));
  }

  List<Widget> _buildStarRow(double rating) => List.generate(5, (i) => Icon(rating >= i + 1 ? Icons.star : (rating >= i + 0.5 ? Icons.star_half : Icons.star_border), color: _c, size: 14));

  Widget _wishlistBlock(double w, double h) {
    return Positioned(
      left: w * 0.03, bottom: h * 0.02, width: w * 0.94, height: h * 0.07,
      child: GestureDetector(
        onTap: () { HapticFeedback.heavyImpact(); setState(() => _showOnlyFavorited = !_showOnlyFavorited); },
        child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _c,
            border: Border.all(color: _dark, width: 4),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Consumer<FavoritesProvider>(
            builder: (context, pv, _) => Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bookmark, color: Color(0xFF9D00FF), size: 20),
              ),
              const SizedBox(width: 10),
              Text('${pv.wishlistCount} GUARDADOS', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 14, color: _dark)),
              const Spacer(),
              const Icon(Icons.arrow_forward, color: Color(0xFF000000), size: 24),
            ]),
          ),
        ),
      ),
      ),
    );
  }
}
