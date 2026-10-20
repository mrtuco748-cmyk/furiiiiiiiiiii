import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/favorites_provider.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/tap_tile.dart';
import '../favoritos_style.dart';

/// Diálogo de creación y edición de elementos favoritos.
class FavoriteEditDialog {
  static void showAddOrEdit(BuildContext context, {FavoriteItem? existing}) {
    String category = existing?.category ?? 'movie';
    double ratingFacu = existing?.ratingFacu ?? 0;
    double ratingRocio = existing?.ratingRocio ?? 0;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final criticaCtrl = TextEditingController(text: existing?.critica ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: FavoritosStyle.panel,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(
            existing != null ? Icons.edit : Icons.add_circle,
            color: FavoritosStyle.vc,
            size: 26,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style:
                      GoogleFonts.bangers(color: FavoritosStyle.fg, fontSize: 14),
                  decoration: _fieldDecoration('titulo'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: criticaCtrl,
                  maxLines: 3,
                  style:
                      GoogleFonts.bangers(color: FavoritosStyle.fg, fontSize: 14),
                  decoration: _fieldDecoration('critica'),
                ),
                const SizedBox(height: 10),
                _catSelector(category, (cat) => setLocal(() => category = cat)),
                const SizedBox(height: 12),
                _ratingEditor(
                    'F', ratingFacu, FavoritosStyle.facuT, (v) => setLocal(() => ratingFacu = v)),
                _ratingEditor(
                    'R', ratingRocio, FavoritosStyle.rocioT, (v) => setLocal(() => ratingRocio = v)),
              ],
            ),
          ),
          actions: [
            _dialogAction(
              Icons.close,
              () => Navigator.pop(ctx),
              bg: FavoritosStyle.bg,
              fg: FavoritosStyle.light,
            ),
            _dialogAction(
              existing != null ? Icons.check : Icons.add,
              () {
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
                AppFeedback.saved(context, 'Guardado');
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

  static InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.bangers(
            color: FavoritosStyle.light.withValues(alpha: 0.4), fontSize: 14),
        filled: true,
        fillColor: FavoritosStyle.bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );

  static Widget _catSelector(String category, ValueChanged<String> onChanged) {
    const allowed = {'movie', 'series', 'game', 'music'};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FavoritesProvider.categoryEmojis.entries
          .where((e) => allowed.contains(e.key))
          .map((e) {
        final selected = category == e.key;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? FavoritosStyle.vc : FavoritosStyle.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.value,
                  style: GoogleFonts.bangers(
                    fontSize: 20,
                    color: selected ? FavoritosStyle.bg : FavoritosStyle.light,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  e.key,
                  style: GoogleFonts.bangers(
                    fontSize: 14,
                    color: selected ? FavoritosStyle.bg : FavoritosStyle.light,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
