import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:furi_app/providers/favorites_provider.dart';

void main() {
  late FavoritesProvider pv;

  setUp(() {
    pv = FavoritesProvider();
  });

  FavoriteItem makeItem({
    String category = 'movie',
    String title = 'X',
    bool favorited = false,
    double ratingFacu = 0,
    double ratingRocio = 0,
  }) =>
      FavoriteItem(
        category: category,
        title: title,
        favorited: favorited,
        ratingFacu: ratingFacu,
        ratingRocio: ratingRocio,
      );

  test('byCategory filtra solo la categoria solicitada', () {
    pv.setItemsForTest([
      makeItem(category: 'movie', title: 'A'),
      makeItem(category: 'game', title: 'B'),
      makeItem(category: 'movie', title: 'C'),
    ]);
    final movies = pv.byCategory('movie');
    expect(movies.length, 2);
    expect(movies.map((m) => m.title), containsAll(['A', 'C']));
  });

  test('categories devuelve un Set de categorias unicas', () {
    pv.setItemsForTest([
      makeItem(category: 'movie'),
      makeItem(category: 'game'),
      makeItem(category: 'movie'),
      makeItem(category: 'book'),
    ]);
    expect(pv.categories.toSet(), {'movie', 'game', 'book'});
  });

  test('wishlistCount cuenta solo los favorited=true', () {
    pv.setItemsForTest([
      makeItem(title: 'a', favorited: true),
      makeItem(title: 'b', favorited: false),
      makeItem(title: 'c', favorited: true),
    ]);
    expect(pv.wishlistCount, 2);
  });

  test('allFavorited retorna listado completo de marcados', () {
    pv.setItemsForTest([
      makeItem(title: 'a', favorited: true),
      makeItem(title: 'b', favorited: false),
      makeItem(title: 'c', favorited: true),
    ]);
    final favs = pv.allFavorited;
    expect(favs.length, 2);
    expect(favs.map((f) => f.title), containsAll(['a', 'c']));
  });

  test('averageRatingFor retorna 0 sin ratings en categoria', () {
    pv.setItemsForTest([makeItem(category: 'movie')]);
    expect(pv.averageRatingFor('movie'), 0);
  });

  test('averageRatingFor promedia solo items con algun rating', () {
    pv.setItemsForTest([
      makeItem(category: 'game', ratingFacu: 5, ratingRocio: 3),
      makeItem(category: 'game', ratingFacu: 0, ratingRocio: 0),
      makeItem(category: 'game', ratingFacu: 4, ratingRocio: 4),
    ]);
    final avg = pv.averageRatingFor('game');
    expect(avg, 4);
  });

  test('averageRatingFor ignora otras categorias', () {
    pv.setItemsForTest([
      makeItem(category: 'movie', ratingFacu: 5, ratingRocio: 5),
      makeItem(category: 'game', ratingFacu: 1, ratingRocio: 3),
    ]);
    expect(pv.averageRatingFor('game'), 2);
    expect(pv.averageRatingFor('movie'), 5);
  });

  // Tanda 2 #1: el realtime NO debe pisar el estado optimista local de las
  // demás filas. Antes el callback hacia load() entero y borraba los edits
  // locales de otras filas.
  test('applyRealtimeRow actualiza solo esa fila y preserva el resto', () {
    final a = FavoriteItem(id: 1, title: 'A', category: 'movie', userId: 'u1');
    final b = FavoriteItem(id: 2, title: 'B', category: 'series', userId: 'u1');
    pv.setItemsForTest([a, b]);
    pv.applyRealtimeRow(
      {
        'id': 1,
        'title': 'A2',
        'category': 'movie',
        'user_id': 'u2',
        'favorited': true,
        'rating_facu': 3.0,
        'rating_rocio': 4.0,
        'critica': 'x',
      },
      null,
      PostgresChangeEvent.update,
    );
    expect(pv.items.length, 2); // no se duplica ni se pierde B
    expect(pv.items.firstWhere((i) => i.id == 1).title, 'A2');
    expect(pv.items.firstWhere((i) => i.id == 2).title, 'B'); // intacta
  });

  test('applyRealtimeRow inserta fila nueva sin duplicar', () {
    pv.setItemsForTest([]);
    pv.applyRealtimeRow(
      {'id': 5, 'title': 'N', 'category': 'game', 'user_id': 'u9'},
      null,
      PostgresChangeEvent.insert,
    );
    expect(pv.items.length, 1);
    expect(pv.items.first.id, 5);
  });

  test('applyRealtimeRow borra fila por oldRecord', () {
    pv.setItemsForTest([FavoriteItem(id: 7, title: 'X', category: 'music', userId: 'u1')]);
    pv.applyRealtimeRow(null, {'id': 7}, PostgresChangeEvent.delete);
    expect(pv.items.isEmpty, isTrue);
  });
}