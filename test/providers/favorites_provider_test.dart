import 'package:flutter_test/flutter_test.dart';
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
}