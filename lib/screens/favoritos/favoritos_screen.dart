import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/favorites_provider.dart';
import '../../widgets/loca_screen.dart';
import 'favoritos_style.dart';
import 'widgets/favorite_card_tile.dart';
import 'widgets/favorite_detail_dialog.dart';
import 'widgets/favorite_edit_dialog.dart';

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
        final cats = FavoritosStyle.catMeta.keys.toList();
        final entries = <LocaEntry>[
          for (var i = 0; i < cats.length; i++)
            LocaEntry(
              icon: FavoritosStyle.catMeta[cats[i]]!['icon'] as IconData,
              color: FavoritosStyle.catMeta[cats[i]]!['color'] as Color,
              label: FavoritosStyle.catLabels[cats[i]] ?? cats[i],
              panel: i,
            ),
          LocaEntry(
            icon: Icons.bookmark,
            color: FavoritosStyle.fav,
            iconColor: const Color(0xFF1A1A1A),
            label: 'guardados',
            swapBuilder: (_) => _wishSwap(pv),
            autoPlaySwap: pv.wishlistCount > 0,
            panel: cats.length,
          ),
          if (pv.hasError)
            LocaEntry(
              icon: Icons.cloud_off,
              color: FavoritosStyle.red,
              onTap: () => context.read<FavoritesProvider>().load(),
            ),
          LocaEntry(
            icon: Icons.add,
            color: FavoritosStyle.vc,
            label: 'agregar',
            onTap: () => FavoriteEditDialog.showAddOrEdit(context),
            isAction: true,
          ),
        ];
        return LocaScreen(
          seed: 59,
          theme: FavoritosStyle.theme,
          entries: entries,
          panels: [
            for (var i = 0; i < cats.length; i++)
              (_, close) => _catPanel(
                  close, cats[i], FavoritosStyle.catMeta[cats[i]]!['icon'] as IconData),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${pv.wishlistCount}',
                style: GoogleFonts.bangers(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'guardados',
              style: GoogleFonts.bangers(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catPanel(VoidCallback close, String category, IconData icon) {
    final color = FavoritosStyle.catMeta[category]!['color'] as Color;
    return LocaScreen.panel(
      color: FavoritosStyle.panel,
      borderColor: color,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                Icon(icon, color: FavoritosStyle.light, size: 22),
                const Spacer(),
                LocaScreen.closeIcon(close, color, Icons.close),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Consumer<FavoritesProvider>(
              builder: (context, pv, _) {
                final items = pv.byCategory(category);
                if (items.isEmpty) {
                  return Center(
                    child: Icon(
                      icon,
                      color: FavoritosStyle.light.withValues(alpha: 0.4),
                      size: 60,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildItemTile(items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedPanel(VoidCallback close, FavoritesProvider pv) {
    return LocaScreen.panel(
      color: FavoritosStyle.panel,
      borderColor: FavoritosStyle.fav,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                Icon(Icons.bookmark, color: FavoritosStyle.light, size: 22),
                const Spacer(),
                LocaScreen.closeIcon(close, FavoritosStyle.fav, Icons.close),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Consumer<FavoritesProvider>(
              builder: (context, innerPv, _) {
                final items = innerPv.allFavorited;
                if (items.isEmpty) {
                  return Center(
                    child: Icon(
                      Icons.bookmark_border,
                      color: FavoritosStyle.light.withValues(alpha: 0.4),
                      size: 60,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildItemTile(items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(FavoriteItem item) {
    return FavoriteCardTile(
      item: item,
      onDetailTap: () => FavoriteDetailDialog.show(context, item),
      onToggleFav: () {
        if (item.id != null) {
          context.read<FavoritesProvider>().toggleFav(item.id!, !item.favorited);
        }
      },
      onEdit: () => FavoriteEditDialog.showAddOrEdit(context, existing: item),
      onDelete: () => FavoriteDetailDialog.confirmDelete(context, item),
    );
  }
}
