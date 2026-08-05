import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/concrete_painter.dart';
import '../../widgets/responsive_wrapper.dart';

const _vc = Color(0xFF9D00FF);
const _bg = Color(0xFF0A0A0A);
const _panel = Color(0xFF1A0830);
const _light = Color(0xFFD4A8FF);
const _fav = Color(0xFFFFD700);
const _fg = Color(0xFFFFFFFF);
const _red = Color(0xFFFF0044);
const _facuT = Color(0xFFFF6B00);
const _rocioT = Color(0xFFFF1493);

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});
  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  String _selectedCategory = 'movie';
  bool _showOnlyFavorited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: ResponsiveWrapper(builder: (context, w, h) {
        return SizedBox(
          width: w,
          height: h,
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
            _headerBar(w, h),
            _catMovie(w, h),
            _catSeries(w, h),
            _catGames(w, h),
            _catMusic(w, h),
            _contentBlock(w, h),
            _wishlistBlock(w, h),
            _errorBanner(),
          ]),
        );
      }),
    );
  }

  double _topCats(double h) => h * 0.015 + h * 0.07 + h * 0.015;

  Widget _headerBar(double w, double h) {
    final barH = h * 0.07;
    return Positioned(
      left: w * 0.03,
      top: h * 0.015,
      width: w * 0.94,
      height: barH,
      child: Container(
        decoration: BoxDecoration(
          color: _vc,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Expanded(
            child: Center(
              child: Text('FAVORITOS',
                  style: GoogleFonts.bangers(
                      fontWeight: FontWeight.bold, fontSize: 20, color: _bg)),
            ),
          ),
          TapTile(
            onTap: () => _addOrEditFavorite(),
            child: Container(
              width: barH,
              height: barH,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: _vc, size: 26),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _catBlock(String category, IconData icon, double left, double top,
      double w) {
    final selected = _selectedCategory == category;
    final tileColor = selected ? _vc : _panel;
    final iconColor = selected ? _bg : _light;
    return Positioned(
      left: left,
      top: top,
      width: w * 0.22,
      height: w * 0.13,
      child: TapTile(
        onTap: () {
          HapticFeedback.heavyImpact();
          setState(() => _selectedCategory = category);
        },
        child: Container(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  Text(category.toUpperCase(),
                      style: GoogleFonts.bangers(
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          color: iconColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catMovie(double w, double h) =>
      _catBlock('movie', Icons.movie, w * 0.03, _topCats(h), w);
  Widget _catSeries(double w, double h) =>
      _catBlock('series', Icons.tv, w * 0.26, _topCats(h) + h * 0.003, w);
  Widget _catGames(double w, double h) =>
      _catBlock('game', Icons.sports_esports, w * 0.50, _topCats(h) - h * 0.003, w);
  Widget _catMusic(double w, double h) =>
      _catBlock('music', Icons.music_note, w * 0.74, _topCats(h) + h * 0.005, w);

  Widget _contentBlock(double w, double h) {
    final top = _topCats(h) + w * 0.13 + h * 0.015;
    return Positioned(
      left: w * 0.03,
      top: top,
      width: w * 0.94,
      height: h * 0.50,
      child: Container(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Consumer<FavoritesProvider>(builder: (context, pv, _) {
            if (pv.loading) {
              return const Center(
                  child: CircularProgressIndicator(color: _vc, strokeWidth: 3));
            }
            final items = pv.byCategory(_selectedCategory);
            final shown = _showOnlyFavorited
                ? items.where((i) => i.favorited).toList()
                : items;
            if (shown.isEmpty) {
              return Center(
                  child: Text(
                      _showOnlyFavorited ? 'Sin guardados' : 'Vacio',
                      style: GoogleFonts.bangers(
                          color: _light.withValues(alpha: 0.5), fontSize: 14)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: shown.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _favCard(shown[index]),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _favCard(FavoriteItem item) {
    return TapTile(
      onTap: () => _showDetailModal(item),
      child: Container(
        decoration: BoxDecoration(
          color: _light,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: GoogleFonts.bangers(
                        fontWeight: FontWeight.bold, fontSize: 13, color: _bg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.critica != null && item.critica!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.critica!,
                        style: GoogleFonts.bangers(
                            fontSize: 10,
                            color: _bg.withValues(alpha: 0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                const SizedBox(height: 4),
                _dualRatingRow(item, compact: true),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (item.id != null) {
                context
                    .read<FavoritesProvider>()
                    .toggleFav(item.id!, !item.favorited);
              }
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.favorited ? _fav : _bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.favorited ? Icons.bookmark : Icons.bookmark_border,
                color: item.favorited ? _bg : _fav,
                size: 16,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _addOrEditFavorite(existing: item),
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.edit, color: _bg, size: 16),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(item),
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.delete_outline, color: _red, size: 16),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _dualRatingRow(FavoriteItem item, {required bool compact}) {
    return Row(
      children: [
        _miniUserRating('F', item.ratingFacu, _facuT, compact),
        const SizedBox(width: 8),
        _miniUserRating('R', item.ratingRocio, _rocioT, compact),
        const Spacer(),
        if (item.bothRated)
          Text('avg ${item.averageRating.toStringAsFixed(1)}',
              style: GoogleFonts.bangers(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: compact ? _bg : _light)),
      ],
    );
  }

  Widget _miniUserRating(
      String label, double rating, Color color, bool compact) {
    final iconColor = compact ? _bg : color;
    final labelColor = compact ? _bg.withValues(alpha: 0.7) : color;
    final size = compact ? 12.0 : 16.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: labelColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label,
              style: GoogleFonts.bangers(
                  color: compact ? _light : _bg,
                  fontSize: 10,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 3),
        ...List.generate(
            5,
            (i) => Icon(
                  rating >= i + 1
                      ? Icons.star
                      : (rating >= i + 0.5 ? Icons.star_half : Icons.star_border),
                  color: iconColor,
                  size: size,
                )),
      ],
    );
  }

  void _addOrEditFavorite({FavoriteItem? existing}) {
    String category = existing?.category ?? _selectedCategory;
    double ratingFacu = existing?.ratingFacu ?? 0;
    double ratingRocio = existing?.ratingRocio ?? 0;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final criticaCtrl = TextEditingController(text: existing?.critica ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: _panel,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(existing != null ? Icons.edit : Icons.add_circle,
                color: _vc, size: 22),
            const SizedBox(width: 8),
            Text(existing != null ? 'EDITAR' : 'NUEVO',
                style: GoogleFonts.bangers(
                    fontWeight: FontWeight.bold, color: _light, fontSize: 22)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: GoogleFonts.bangers(color: _fg, fontSize: 14),
                decoration: _fieldDecoration('titulo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: criticaCtrl,
                maxLines: 3,
                style: GoogleFonts.bangers(color: _fg, fontSize: 14),
                decoration: _fieldDecoration('critica'),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('CATEGORIA',
                    style: GoogleFonts.bangers(
                        color: _light.withValues(alpha: 0.7), fontSize: 10)),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: FavoritesProvider.categoryEmojis.entries.map((e) {
                  final selected = category == e.key;
                  return GestureDetector(
                    onTap: () => setLocal(() => category = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected ? _vc : _bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(e.value, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(e.key,
                            style: GoogleFonts.bangers(
                                fontSize: 10,
                                color: selected ? _bg : _light,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('CALIFICAR',
                    style: GoogleFonts.bangers(
                        color: _light.withValues(alpha: 0.7), fontSize: 10)),
              ),
              _ratingEditor('F', ratingFacu, _facuT,
                  (v) => setLocal(() => ratingFacu = v)),
              _ratingEditor('R', ratingRocio, _rocioT,
                  (v) => setLocal(() => ratingRocio = v)),
            ]),
          ),
          actions: [
            _dialogAction(Icons.close, 'cancelar', () => Navigator.pop(ctx),
                bg: _bg, fg: _light),
            _dialogAction(
                existing != null ? Icons.check : Icons.add, 'guardar', () {
              if (titleCtrl.text.isEmpty) {
                Navigator.pop(ctx);
                return;
              }
              final pv = context.read<FavoritesProvider>();
              final item = FavoriteItem(
                id: existing?.id,
                category: category,
                title: titleCtrl.text,
                critica:
                    criticaCtrl.text.isNotEmpty ? criticaCtrl.text : null,
                emoji: FavoritesProvider.categoryEmojis[category] ?? '⭐',
                ratingFacu: ratingFacu,
                ratingRocio: ratingRocio,
                favorited: existing?.favorited ?? false,
                userId: existing?.userId,
              );
              if (existing != null && existing.id != null) {
                pv.update(existing.id!, item);
              } else {
                pv.add(item);
              }
              Navigator.pop(ctx);
            }, bg: _vc, fg: _bg),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.bangers(
            color: _light.withValues(alpha: 0.4), fontSize: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _panel, width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _vc, width: 2)),
      );

  Widget _ratingEditor(
      String label, double rating, Color color, ValueChanged<double> onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(label,
              style: GoogleFonts.bangers(
                  color: _bg, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 8),
        ...List.generate(
            5,
            (i) => GestureDetector(
                  onTap: () => onTap((i + 1).toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                        rating >= i + 1
                            ? Icons.star
                            : (rating >= i + 0.5
                                ? Icons.star_half
                                : Icons.star_border),
                        color: color,
                        size: 28),
                  ),
                )),
        const SizedBox(width: 8),
        ...List.generate(
            5,
            (i) => GestureDetector(
                  onTap: () => onTap(i + 0.5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                        width: 10,
                        height: 16,
                        decoration: BoxDecoration(
                            color: (i + 0.5) <= rating ? color : Colors.transparent,
                            borderRadius: BorderRadius.circular(3))),
                  ),
                )),
      ]),
    );
  }

  Widget _dialogAction(IconData icon, String semanticFallback, VoidCallback onTap,
      {required Color bg, required Color fg}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }

  void _showDetailModal(FavoriteItem item) {
    double tempFacu = item.ratingFacu;
    double tempRocio = item.ratingRocio;
    final criticaCtrl = TextEditingController(text: item.critica ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: _panel,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _bg, borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.title,
                  style: GoogleFonts.bangers(
                      color: _light, fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('CRITICA',
                    style: GoogleFonts.bangers(
                        color: _light.withValues(alpha: 0.6), fontSize: 10)),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: criticaCtrl,
                maxLines: 4,
                style: GoogleFonts.bangers(color: _fg, fontSize: 14),
                decoration: _fieldDecoration('escribir critica compartida'),
              ),
              const SizedBox(height: 14),
              _ratingEditor('F', tempFacu, _facuT,
                  (v) => setLocal(() => tempFacu = v)),
              _ratingEditor('R', tempRocio, _rocioT,
                  (v) => setLocal(() => tempRocio = v)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    color: _bg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                    'PROMEDIO: ${item.bothRated ? item.averageRating.toStringAsFixed(1) : (item.hasAnyRating ? item.averageRating.toStringAsFixed(1) : '0')}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bangers(
                        color: _light, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          actions: [
            if (item.id != null)
              _dialogAction(Icons.delete_outline, '', () {
                Navigator.pop(ctx);
                _confirmDelete(item);
              }, bg: _red, fg: _bg),
            if (item.id != null)
              _dialogAction(Icons.bookmark,
                  item.favorited ? 'unsave' : 'save', () {
                context
                    .read<FavoritesProvider>()
                    .toggleFav(item.id!, !item.favorited);
                Navigator.pop(ctx);
              }, bg: _fav, fg: _bg),
            _dialogAction(Icons.check, 'guardar', () {
              if (item.id != null) {
                final pv = context.read<FavoritesProvider>();
                pv.setRating(item.id!, 'Facu', tempFacu);
                pv.setRating(item.id!, 'Rocio', tempRocio);
                pv.setCritica(item.id!, criticaCtrl.text);
              }
              Navigator.pop(ctx);
            }, bg: _vc, fg: _bg),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(FavoriteItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ELIMINAR',
            style: GoogleFonts.bangers(
                color: _light, fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text('¿Eliminar "${item.title}"?',
            style: GoogleFonts.bangers(color: _fg, fontSize: 14)),
        actions: [
          _dialogAction(Icons.close, 'cancelar', () => Navigator.pop(ctx),
              bg: _bg, fg: _light),
          _dialogAction(Icons.delete_outline, 'eliminar', () {
            if (item.id != null) {
              context.read<FavoritesProvider>().delete(item.id!);
            }
            Navigator.pop(ctx);
          }, bg: _red, fg: _bg),
        ],
      ),
    );
  }

  Widget _wishlistBlock(double w, double h) {
    return Positioned(
      left: w * 0.03,
      bottom: h * 0.02,
      width: w * 0.94,
      height: h * 0.07,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          setState(() => _showOnlyFavorited = !_showOnlyFavorited);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _vc,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Consumer<FavoritesProvider>(
            builder: (context, pv, _) => Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: _bg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bookmark, color: _fav, size: 20),
              ),
              const SizedBox(width: 10),
              Text('${pv.wishlistCount} GUARDADOS',
                  style: GoogleFonts.bangers(
                      fontWeight: FontWeight.bold, fontSize: 14, color: _bg)),
              const Spacer(),
              Icon(_showOnlyFavorited ? Icons.filter_alt : Icons.filter_alt_off,
                  color: _bg, size: 22),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Consumer<FavoritesProvider>(
      builder: (context, pv, _) {
        if (!pv.hasError) return const SizedBox.shrink();
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: _bg, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(pv.error!,
                        style: GoogleFonts.bangers(color: _bg, fontSize: 12))),
                GestureDetector(
                  onTap: () => pv.clearError(),
                  child: const Icon(Icons.close, color: _bg, size: 18),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}