import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/providers/favorites_provider.dart';

void main() {
  test('FavoriteItem serializa y deserializa con rating dual + critica', () {
    final original = FavoriteItem(
      id: 7,
      category: 'movie',
      title: 'Blade Runner 2049',
      critica: 'Visualmente impresionante',
      emoji: '🎬',
      ratingFacu: 4.5,
      ratingRocio: 5,
      userId: 'facu-uuid',
    );

    final map = original.toMap();
    expect(map['id'], 7);
    expect(map['category'], 'movie');
    expect(map['title'], 'Blade Runner 2049');
    expect(map['critica'], 'Visualmente impresionante');
    expect(map['emoji'], '🎬');
    expect(map['rating_facu'], 4.5);
    expect(map['rating_rocio'], 5);
    expect(map['favorited'], false);
    expect(map['user_id'], 'facu-uuid');

    final restored = FavoriteItem.fromMap(map);
    expect(restored.id, 7);
    expect(restored.category, 'movie');
    expect(restored.title, 'Blade Runner 2049');
    expect(restored.critica, 'Visualmente impresionante');
    expect(restored.emoji, '🎬');
    expect(restored.ratingFacu, 4.5);
    expect(restored.ratingRocio, 5);
    expect(restored.favorited, false);
    expect(restored.userId, 'facu-uuid');
  });

  test('FavoriteItem fromMap tolera datos legacy sin rating dual ni critica', () {
    final legacy = FavoriteItem.fromMap({
      'id': 1,
      'user_id': 'facu-uuid',
      'category': 'series',
      'title': 'Severance',
      'emoji': '📺',
      'favorited': true,
    });

    expect(legacy.ratingFacu, 0);
    expect(legacy.ratingRocio, 0);
    expect(legacy.critica, isNull);
    expect(legacy.favorited, true);
  });

  test('FavoriteItem.fromMap migra rating viejo a rating_facu si existe', () {
    final legacy = FavoriteItem.fromMap({
      'id': 2,
      'category': 'game',
      'title': 'Hades',
      'rating': 4,
    });

    expect(legacy.ratingFacu, 4,
        reason: 'rating legacy se conserva en rating_facu');
    expect(legacy.ratingRocio, 0);
  });

  test('copyWith permite actualizar rating de cada usuario por separado', () {
    final base = FavoriteItem(
      category: 'book',
      title: 'Dune',
      ratingFacu: 3,
      ratingRocio: 4,
      critica: 'original',
    );

    final facuUpdate = base.copyWith(ratingFacu: 5);
    expect(facuUpdate.ratingFacu, 5);
    expect(facuUpdate.ratingRocio, 4, reason: 'no debe pisar el rating del otro');
    expect(facuUpdate.critica, 'original');

    final rocioUpdate = base.copyWith(ratingRocio: 2);
    expect(rocioUpdate.ratingRocio, 2);
    expect(rocioUpdate.ratingFacu, 3);

    final criticaUpdate = base.copyWith(critica: 'nueva critica');
    expect(criticaUpdate.critica, 'nueva critica');
    expect(criticaUpdate.ratingFacu, 3);
    expect(criticaUpdate.ratingRocio, 4);
  });

  test('copyWith mantiene favorited (regresion)', () {
    final base = FavoriteItem(
      category: 'song',
      title: 'Bohemian Rhapsody',
      favorited: true,
    );
    final updated = base.copyWith(ratingFacu: 5);
    expect(updated.favorited, true,
        reason: 'favorited no debe resetearse al actualizar rating');
  });

  test('averageRating retorna 0 si nadie califico', () {
    final item = FavoriteItem(category: 'place', title: 'Cafeteria X');
    expect(item.averageRating, 0);
  });

  test('averageRating retorna el rating del unico que califico', () {
    final facu = FavoriteItem(
      category: 'place',
      title: 'Cafeteria X',
      ratingFacu: 4,
    );
    expect(facu.averageRating, 4);

    final rocio = FavoriteItem(
      category: 'place',
      title: 'Cafeteria X',
      ratingRocio: 3,
    );
    expect(rocio.averageRating, 3);
  });

  test('averageRating promedia cuando ambos calificaron', () {
    final item = FavoriteItem(
      category: 'place',
      title: 'Cafeteria X',
      ratingFacu: 5,
      ratingRocio: 3,
    );
    expect(item.averageRating, 4);
  });

  test('ratingFor devuelve rating correcto segun identidad', () {
    final item = FavoriteItem(
      category: 'movie',
      title: 'Interstellar',
      ratingFacu: 4,
      ratingRocio: 5,
    );
    expect(item.ratingFor('Facu'), 4);
    expect(item.ratingFor('Rocio'), 5);
    expect(item.ratingFor('Desconocido'), 0,
        reason: 'identidad no reconocida retorna 0');
  });

  test('hasRating de cada usuario se REPORTA correctamente', () {
    final item = FavoriteItem(
      category: 'movie',
      title: 'X',
      ratingFacu: 0,
      ratingRocio: 4,
    );
    expect(item.hasFacuRating, isFalse);
    expect(item.hasRocioRating, isTrue);
  });
}