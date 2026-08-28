import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/favorites_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loca_screen.dart';
import '../../widgets/tap_tile.dart';
import '../../widgets/app_feedback.dart';

const _vc = Color(0xFF9D00FF);
const _bg = Color(0xFF0A0A0A);
const _panel = Color(0xFF1A0830);
const _light = Color(0xFFD4A8FF);
const _fav = Color(0xFFFFD700);
const _fg = Color(0xFFFFFFFF);
const _red = Color(0xFFFF0044);
const _facuT = Color(0xFFFF6B00);
const _rocioT = Color(0xFFFF1493);

const _catLabels = <String, String>{
  'movie': 'Pelis',
  'series': 'Series',
  'game': 'Juegos',
  'music': 'Música',
};

const _favoritosTheme = ThemeSet(
  a: Color(0xFF9D00FF),
  b: Color(0xFF6B0FB8),
  c: Color(0xFFFFD700),
  d: Color(0xFFB23BFF),
  e: Color(0xFF7B2D8E),
  dark: Color(0xFF0A0A0A),
  light: Color(0xFFD4A8FF),
  mid: Color(0xFF1A0830),
);

const _catMeta = <String, Map<String, dynamic>>{
  'movie': {'icon': Icons.movie, 'color': Color(0xFF9D00FF)},
  'series': {'icon': Icons.tv, 'color': Color(0xFF6B0FB8)},
  'game': {'icon': Icons.sports_esports, 'color': Color(0xFFB23BFF)},
  'music': {'icon': Icons.music_note, 'color': Color(0xFF7B2D8E)},
};

/// Favoritos estilo "Nosotros": un tile por categoría (pelicula/serie/juego/
/// música) que abre el panel con su lista; tile guardados con swap (contador) y
/// alta (+) fija en la columna lateral.
class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});
  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, pv, _) {
        final cats = _catMeta.keys.toList();
        final entries = <LocaEntry>[
          for (var i = 0; i < cats.length; i++)
            LocaEntry(
              icon: _catMeta[cats[i]]!['icon'] as IconData,
              color: _catMeta[cats[i]]!['color'] as Color,
              label: _catLabels[cats[i]] ?? cats[i],
              panel: i,
            ),
          LocaEntry(
            icon: Icons.bookmark,
            color: _fav,
            iconColor: const Color(0xFF1A1A1A),
            label: 'guardados',
            swapBuilder: (_) => _wishSwap(pv),
            autoPlaySwap: pv.wishlistCount > 0,
            panel: cats.length,
          ),
          if (pv.hasError)
            LocaEntry(icon: Icons.cloud_off, color: _red, onTap: () => context.read<FavoritesProvider>().load()),
          LocaEntry(
            icon: Icons.add,
            color: _vc,
            label: 'agregar',
            onTap: () => _addOrEditFavorite(),
            isAction: true,
          ),
        ];
        return LocaScreen(
          seed: 59,
          theme: _favoritosTheme,
          entries: entries,
          panels: [
            for (var i = 0; i < cats.length; i++)
              (_, close) => _catPanel(close, cats[i], _catMeta[cats[i]]!['icon'] as IconData),
            (_, close) => _savedPanel(close, pv),
          ],
        );
      },
    );
  }

  Widget _wishSwap(FavoritesProvider pv) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${pv.wishlistCount}', style: GoogleFonts.bangers(color: const Color(0xFF1A1A1A), fontSize: 34, fontWeight: FontWeight.w900)),
          ),
          Text('guardados', style: GoogleFonts.bangers(color: const Color(0xFF1A1A1A).withValues(alpha: 0.6), fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _catPanel(VoidCallback close, String category, IconData icon) {
    final color = _catMeta[category]!['color'] as Color;
    return LocaScreen.panel(
      color: _panel,
      borderColor: color,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(children: [
            Icon(icon, color: _light, size: 22),
            const Spacer(),
            LocaScreen.closeIcon(close, color, Icons.close),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Consumer<FavoritesProvider>(
            builder: (context, pv, _) {
              final items = pv.byCategory(category);
              if (items.isEmpty) {
                return Center(child: Icon(icon, color: _light.withValues(alpha: 0.4), size: 60));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _favCard(items[index]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _savedPanel(VoidCallback close, FavoritesProvider pv) {
    return LocaScreen.panel(
      color: _panel,
      borderColor: _fav,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(children: [
            Icon(Icons.bookmark, color: _light, size: 22),
            const Spacer(),
            LocaScreen.closeIcon(close, _fav, Icons.close),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Consumer<FavoritesProvider>(
            builder: (context, innerPv, _) {
              final items = innerPv.allFavorited;
              if (items.isEmpty) {
                return Center(
                  child: Icon(Icons.bookmark_border,
                      color: _light.withValues(alpha: 0.4), size: 60),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _favCard(items[index]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _favCard(FavoriteItem item) {
    return TapTile(
      onTap: () => _showDetailModal(item),
      child: Container(
        decoration: BoxDecoration(
          color: _light,
          border: Border.all(color: _light, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title,
                  style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 13, color: _bg),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (item.critica != null && item.critica!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(item.critica!,
                      style: GoogleFonts.bangers(fontSize: 10, color: _bg.withValues(alpha: 0.6)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 4),
              _dualRatingRow(item, compact: true),
            ]),
          ),
          GestureDetector(
            onTap: () {
              if (item.id != null) {
                context.read<FavoritesProvider>().toggleFav(item.id!, !item.favorited);
              }
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: item.favorited ? _fav : _bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(item.favorited ? Icons.bookmark : Icons.bookmark_border,
                  color: item.favorited ? _bg : _fav, size: 16),
            ),
          ),
          GestureDetector(
            onTap: () => _addOrEditFavorite(existing: item),
            child: const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.edit, color: _bg, size: 16)),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(item),
            child: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.delete_outline, color: _red, size: 16)),
          ),
        ]),
      ),
    );
  }

  Widget _dualRatingRow(FavoriteItem item, {required bool compact}) {
    return Row(children: [
      _miniUserRating('F', item.ratingFacu, _facuT, compact),
      const SizedBox(width: 8),
      _miniUserRating('R', item.ratingRocio, _rocioT, compact),
      const Spacer(),
      if (item.bothRated)
        Text('avg ${item.averageRating.toStringAsFixed(1)}',
            style: GoogleFonts.bangers(fontSize: 11, fontWeight: FontWeight.bold, color: compact ? _bg : _light)),
    ]);
  }

  Widget _miniUserRating(String label, double rating, Color color, bool compact) {
    final iconColor = compact ? _bg : color;
    final labelColor = compact ? _bg.withValues(alpha: 0.7) : color;
    final size = compact ? 12.0 : 16.0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 16, height: 16, alignment: Alignment.center,
        decoration: BoxDecoration(color: labelColor, borderRadius: BorderRadius.circular(5)),
        child: Text(label, style: GoogleFonts.bangers(color: compact ? _light : _bg, fontSize: 10, fontWeight: FontWeight.w900)),
      ),
      const SizedBox(width: 3),
      ...List.generate(5, (i) => Icon(
            rating >= i + 1 ? Icons.star : (rating >= i + 0.5 ? Icons.star_half : Icons.star_border),
            color: iconColor, size: size)),
    ]);
  }

  Widget _catSelector(String category, ValueChanged<String> onChanged) {
    const allowed = {'movie', 'series', 'game', 'music'};
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: FavoritesProvider.categoryEmojis.entries
          .where((e) => allowed.contains(e.key))
          .map((e) {
        final selected = category == e.key;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: selected ? _vc : _bg, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(e.value, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(e.key, style: GoogleFonts.bangers(fontSize: 10, color: selected ? _bg : _light, fontWeight: FontWeight.bold)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  void _addOrEditFavorite({FavoriteItem? existing}) {
    String category = existing?.category ?? 'movie';
    double ratingFacu = existing?.ratingFacu ?? 0;
    double ratingRocio = existing?.ratingRocio ?? 0;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final criticaCtrl = TextEditingController(text: existing?.critica ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: _panel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(existing != null ? Icons.edit : Icons.add_circle, color: _vc, size: 26),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, autofocus: true, style: GoogleFonts.bangers(color: _fg, fontSize: 14), decoration: _fieldDecoration('titulo')),
              const SizedBox(height: 10),
              TextField(controller: criticaCtrl, maxLines: 3, style: GoogleFonts.bangers(color: _fg, fontSize: 14), decoration: _fieldDecoration('critica')),
              const SizedBox(height: 10),
              _catSelector(category, (cat) => setLocal(() => category = cat)),
              const SizedBox(height: 12),
              _ratingEditor('F', ratingFacu, _facuT, (v) => setLocal(() => ratingFacu = v)),
              _ratingEditor('R', ratingRocio, _rocioT, (v) => setLocal(() => ratingRocio = v)),
            ]),
          ),
          actions: [
            _dialogAction(Icons.close, () => Navigator.pop(ctx), bg: _bg, fg: _light),
            _dialogAction(existing != null ? Icons.check : Icons.add, () {
              if (titleCtrl.text.isEmpty) {
                Navigator.pop(ctx);
                return;
              }
              final pv = context.read<FavoritesProvider>();
              final item = FavoriteItem(
                id: existing?.id,
                category: category,
                title: titleCtrl.text,
                critica: criticaCtrl.text.isNotEmpty ? criticaCtrl.text : null,
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
              AppFeedback.saved(context, 'Guardado');
              Navigator.pop(ctx);
            }, bg: _vc, fg: _bg),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.bangers(color: _light.withValues(alpha: 0.4), fontSize: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _panel, width: 2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _vc, width: 2)),
      );

  Widget _ratingEditor(String label, double rating, Color color, ValueChanged<double> onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 24, height: 24, alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: GoogleFonts.bangers(color: _bg, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (i) => GestureDetector(
              onTap: () => onTap((i + 1).toDouble()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(rating >= i + 1 ? Icons.star : (rating >= i + 0.5 ? Icons.star_half : Icons.star_border), color: color, size: 28),
              ),
            )),
        const SizedBox(width: 8),
        ...List.generate(5, (i) => GestureDetector(
              onTap: () => onTap(i + 0.5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(width: 10, height: 16, decoration: BoxDecoration(color: (i + 0.5) <= rating ? color : Colors.transparent, borderRadius: BorderRadius.circular(3))),
              ),
            )),
      ]),
    );
  }

  Widget _dialogAction(IconData icon, VoidCallback onTap, {required Color bg, required Color fg}) {
    return TapTile(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(color: bg, border: Border.all(color: bg, width: 2), borderRadius: BorderRadius.circular(14)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.title,
                  style: GoogleFonts.bangers(color: _light, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(controller: criticaCtrl, maxLines: 4, style: GoogleFonts.bangers(color: _fg, fontSize: 14), decoration: _fieldDecoration('escribir critica compartida')),
              const SizedBox(height: 14),
              _ratingEditor('F', tempFacu, _facuT, (v) => setLocal(() => tempFacu = v)),
              _ratingEditor('R', tempRocio, _rocioT, (v) => setLocal(() => tempRocio = v)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                    'PROMEDIO: ${item.hasAnyRating ? item.averageRating.toStringAsFixed(1) : '0'}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bangers(color: _light, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          actions: [
            if (item.id != null)
              _dialogAction(Icons.delete_outline, () { Navigator.pop(ctx); _confirmDelete(item); }, bg: _red, fg: _bg),
            if (item.id != null)
              _dialogAction(Icons.bookmark, () {
                context.read<FavoritesProvider>().toggleFav(item.id!, !item.favorited);
                Navigator.pop(ctx);
              }, bg: _fav, fg: _bg),
            _dialogAction(Icons.check, () {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.delete_outline, color: _red, size: 32),
        actions: [
          _dialogAction(Icons.close, () => Navigator.pop(ctx), bg: _bg, fg: _light),
          _dialogAction(Icons.delete_outline, () {
            if (item.id != null) {
              context.read<FavoritesProvider>().delete(item.id!);
            }
            Navigator.pop(ctx);
          }, bg: _red, fg: _bg),
        ],
      ),
    );
  }
}