import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/favorite_item.dart';
import '../../../widgets/tap_tile.dart';
import '../favoritos_style.dart';

/// Card individual que muestra un ítem favorito con sus ratings de Facu y Rocío.
class FavoriteCardTile extends StatelessWidget {
  final FavoriteItem item;
  final VoidCallback onDetailTap;
  final VoidCallback onToggleFav;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FavoriteCardTile({
    super.key,
    required this.item,
    required this.onDetailTap,
    required this.onToggleFav,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: onDetailTap,
      child: Container(
        decoration: BoxDecoration(
          color: FavoritosStyle.light,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FavoritosStyle.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.bangers(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: FavoritosStyle.bg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.critica != null && item.critica!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.critica!,
                        style: GoogleFonts.bangers(
                          fontSize: 10,
                          color: FavoritosStyle.bg.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  _dualRatingRow(item, compact: true),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggleFav,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: item.favorited ? FavoritosStyle.fav : FavoritosStyle.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.favorited ? Icons.bookmark : Icons.bookmark_border,
                  color: item.favorited ? FavoritosStyle.bg : FavoritosStyle.fav,
                  size: 16,
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.edit, color: FavoritosStyle.bg, size: 16),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.delete_outline,
                    color: FavoritosStyle.red, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _dualRatingRow(FavoriteItem item, {required bool compact}) {
    return Row(
      children: [
        _miniUserRating('F', item.ratingFacu, FavoritosStyle.facuT, compact),
        const SizedBox(width: 8),
        _miniUserRating('R', item.ratingRocio, FavoritosStyle.rocioT, compact),
        const Spacer(),
        if (item.bothRated)
          Text(
            'avg ${item.averageRating.toStringAsFixed(1)}',
            style: GoogleFonts.bangers(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: compact ? FavoritosStyle.bg : FavoritosStyle.light,
            ),
          ),
      ],
    );
  }

  static Widget _miniUserRating(
      String label, double rating, Color color, bool compact) {
    final iconColor = compact ? FavoritosStyle.bg : color;
    final labelColor =
        compact ? FavoritosStyle.bg.withValues(alpha: 0.7) : color;
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
          child: Text(
            label,
            style: GoogleFonts.bangers(
              color: compact ? FavoritosStyle.light : FavoritosStyle.bg,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
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
          ),
        ),
      ],
    );
  }
}
