import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_item.dart';
import '../services/local_cache.dart';
import '../supabase_config.dart';

export '../models/favorite_item.dart';

class FavoritesProvider extends ChangeNotifier {
  List<FavoriteItem> _items = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  @visibleForTesting
  void setItemsForTest(List<FavoriteItem> items) {
    _items = List.unmodifiable(items);
    notifyListeners();
  }

  List<FavoriteItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<FavoriteItem> byCategory(String cat) =>
      _items.where((i) => i.category == cat).toList();
  List<String> get categories =>
      _items.map((i) => i.category).toSet().toList();
  int get wishlistCount => _items.where((i) => i.favorited).length;

  List<FavoriteItem> get allFavorited =>
      _items.where((i) => i.favorited).toList();

  double averageRatingFor(String category) {
    final catItems = byCategory(category).where((i) => i.hasAnyRating);
    if (catItems.isEmpty) return 0;
    return catItems.fold<double>(0, (s, i) => s + i.averageRating) /
        catItems.length;
  }

  static const categoryEmojis = {
    'movie': '🎬', 'series': '📺', 'anime': '🎌', 'song': '🎵', 'music': '🎵',
    'game': '🎮', 'book': '📖', 'recipe': '🍳', 'restaurant': '🍽️', 'place': '📍',
  };

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('favorites_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'favorites',
          callback: _onRealtime,
        )
        .subscribe();
  }

  void _onRealtime(PostgresChangePayload payload) {
    applyRealtimeRow(
      payload.newRecord as Map<String, dynamic>?,
      payload.oldRecord as Map<String, dynamic>?,
      payload.eventType,
    );
  }

  /// Aplica UN solo cambio de realtime al listado local SIN reemplazar toda
  /// la lista. Así un cambio de la pareja (o el echo de mi propio write) no
  /// pisa los edits optimistas que tengo en OTRAS filas (bug de Tanda 2:
  /// el callback hacia `load()` entero y borraba el estado optimista local).
  @visibleForTesting
  void applyRealtimeRow(
    Map<String, dynamic>? newRecord,
    Map<String, dynamic>? oldRecord,
    PostgresChangeEvent event,
  ) {
    if (event == PostgresChangeEvent.delete) {
      final id = oldRecord?['id'];
      if (id != null) {
        _items = _items.where((i) => i.id != id).toList();
        notifyListeners();
      }
      return;
    }
    if (newRecord == null) return;
    _mergeOne(FavoriteItem.fromMap(newRecord));
  }

  void _mergeOne(FavoriteItem item) {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx == -1) {
      _items = [item, ..._items];
    } else {
      final copy = List<FavoriteItem>.from(_items);
      copy[idx] = item;
      _items = copy;
    }
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    // Cache local (offline-first): mostramos lo último conocido de inmediato
    // para no mostrar un tile de carga al entrar a la sección.
    final cached = await LocalCache.getList('cache_favorites');
    if (cached.isNotEmpty) {
      _items = cached
          .map((m) => FavoriteItem.fromMap(m))
          .toList();
      _loading = false;
      notifyListeners();
    }
    try {
      final res = await SupabaseConfig.client
          .from('favorites')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      _items = (res as List)
          .map((e) => FavoriteItem.fromMap(e as Map<String, dynamic>))
          .toList();
      await LocalCache.setList(
          'cache_favorites', _items.map((i) => i.toMap()).toList());
      _error = null;
      if (_channel == null) _subscribeRealtime();
    } catch (e) {
      // Ante un fallo de red dejamos el cache (si lo había) y avisamos.
      if (_items.isEmpty) _error = 'No se pudieron cargar los favoritos';
      debugPrint('FavoritesProvider.load error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add(FavoriteItem item) async {
    _error = null;
    try {
      final data = await SupabaseConfig.client
          .from('favorites')
          .insert(item.toMap())
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      _mergeOne(FavoriteItem.fromMap(data));
    } catch (e) {
      _error = 'No se pudo guardar el favorito';
      debugPrint('FavoritesProvider.add error: $e');
      notifyListeners();
      return;
    }
  }

  Future<void> update(int id, FavoriteItem item) async {
    _error = null;
    try {
      final map = item.toMap();
      map.remove('id');
      map.remove('user_id');
      map.remove('created_at');
      final data = await SupabaseConfig.client
          .from('favorites')
          .update(map)
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      _mergeOne(FavoriteItem.fromMap(data));
    } catch (e) {
      _error = 'No se pudo actualizar el favorito';
      debugPrint('FavoritesProvider.update error: $e');
      notifyListeners();
      return;
    }
  }

  Future<void> toggleFav(int id, bool fav) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(favorited: fav);
    notifyListeners();
    try {
      final data = await SupabaseConfig.client
          .from('favorites')
          .update({'favorited': fav})
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      _mergeOne(FavoriteItem.fromMap(data));
    } catch (e) {
      _error = 'No se pudo actualizar el favorito';
      debugPrint('FavoritesProvider.toggleFav error: $e');
      await load();
    }
  }

  Future<void> setRating(int id, String identity, double rating) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final current = _items[idx];
    final updated = identity == 'Facu'
        ? current.copyWith(ratingFacu: rating)
        : current.copyWith(ratingRocio: rating);
    _items[idx] = updated;
    notifyListeners();
    try {
      final patch = identity == 'Facu'
          ? {'rating_facu': rating}
          : {'rating_rocio': rating};
      final data = await SupabaseConfig.client
          .from('favorites')
          .update(patch)
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      _mergeOne(FavoriteItem.fromMap(data));
    } catch (e) {
      _error = 'No se pudo guardar el rating';
      debugPrint('FavoritesProvider.setRating error: $e');
      await load();
    }
  }

  Future<void> setCritica(int id, String critica) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(critica: critica);
    notifyListeners();
    try {
      final data = await SupabaseConfig.client
          .from('favorites')
          .update({'critica': critica})
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      _mergeOne(FavoriteItem.fromMap(data));
    } catch (e) {
      _error = 'No se pudo guardar la critica';
      debugPrint('FavoritesProvider.setCritica error: $e');
      await load();
    }
  }

  Future<void> delete(int id) async {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('favorites')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar el favorito';
      debugPrint('FavoritesProvider.delete error: $e');
      await load();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
