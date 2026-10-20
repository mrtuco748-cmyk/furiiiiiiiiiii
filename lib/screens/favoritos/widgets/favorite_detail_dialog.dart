import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/favorites_provider.dart';
import '../../../widgets/tap_tile.dart';
import '../favoritos_style.dart';

/// Modal de detalle de un favorito y confirmación de eliminación.
class FavoriteDetailDialog {
  static void show(BuildContext context, FavoriteItem item) {
    double tempFacu = item.ratingFacu;
    double tempRocio = item.ratingRocio;
    final criticaCtrl = TextEditingController(text: item.critica ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: FavoritosStyle.panel,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FavoritosStyle.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.bangers(
                    color: FavoritosStyle.light,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: criticaCtrl,
                  maxLines: 4,
                  style: GoogleFonts.bangers(
                      color: FavoritosStyle.fg, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'escribir critica compartida',
                    hintStyle: GoogleFonts.bangers(
                        color: FavoritosStyle.light.withValues(alpha: 0.4),
                        fontSize: 14),
                    filled: true,
                    fillColor: FavoritosStyle.bg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                _ratingEditor('F', tempFacu, FavoritosStyle.facuT,
                    (v) => setLocal(() => tempFacu = v)),
                _ratingEditor('R', tempRocio, FavoritosStyle.rocioT,
                    (v) => setLocal(() => tempRocio = v)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: FavoritosStyle.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'PROMEDIO: ${item.hasAnyRating ? item.averageRating.toStringAsFixed(1) : '0'}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bangers(
                      color: FavoritosStyle.light,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (item.id != null)
              _dialogAction(
                Icons.delete_outline,
                () {
                  Navigator.pop(ctx);
                  confirmDelete(context, item);
                },
                bg: FavoritosStyle.red,
                fg: FavoritosStyle.bg,
              ),
            if (item.id != null)
              _dialogAction(
                Icons.bookmark,
                () {
                  context
                      .read<FavoritesProvider>()
                      .toggleFav(item.id!, !item.favorited);
                  Navigator.pop(ctx);
                },
                bg: FavoritosStyle.fav,
                fg: FavoritosStyle.bg,
              ),
            _dialogAction(
              Icons.check,
              () {
                if (item.id != null) {
                  final pv = context.read<FavoritesProvider>();
                  pv.setRating(item.id!, 'Facu', tempFacu);
                  pv.setRating(item.id!, 'Rocio', tempRocio);
                  pv.setCritica(item.id!, criticaCtrl.text);
                }
                Navigator.pop(ctx);
              },
              bg: FavoritosStyle.vc,
              fg: FavoritosStyle.bg,
            ),
          ],
        ),
      ),
    );
  }

  static void confirmDelete(BuildContext context, FavoriteItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FavoritosStyle.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.delete_outline,
            color: FavoritosStyle.red, size: 32),
        actions: [
          _dialogAction(
            Icons.close,
            () => Navigator.pop(ctx),
            bg: FavoritosStyle.bg,
            fg: FavoritosStyle.light,
          ),
          _dialogAction(
            Icons.delete_outline,
            () {
              if (item.id != null) {
                context.read<FavoritesProvider>().delete(item.id!);
              }
              Navigator.pop(ctx);
            },
            bg: FavoritosStyle.red,
            fg: FavoritosStyle.bg,
          ),
        ],
      ),
    );
  }

  static Widget _ratingEditor(
      String label, double rating, Color color, ValueChanged<double> onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(
              label,
              style: GoogleFonts.bangers(
                  color: FavoritosStyle.bg,
                  fontSize: 12,
                  fontWeight: FontWeight.w900),
            ),
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
                      : (rating >= i + 0.5 ? Icons.star_half : Icons.star_border),
                  color: color,
                  size: 28,
                ),
              ),
            ),
          ),
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
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dialogAction(IconData icon, VoidCallback onTap,
      {required Color bg, required Color fg}) {
    return TapTile(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}
