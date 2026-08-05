import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../app_state.dart';

class FavoriteItem {
  final int? id;
  final String? userId;
  final String category;
  final String title;
  final String? critica;
  final String emoji;
  final double ratingFacu;
  final double ratingRocio;
  final bool favorited;
  final DateTime createdAt;

  FavoriteItem({
    this.id,
    required this.category,
    required this.title,
    this.critica,
    this.emoji = '⭐',
    this.ratingFacu = 0,
    this.ratingRocio = 0,
    this.favorited = false,
    this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category': category,
    'title': title,
    'critica': critica,
    'emoji': emoji,
    'rating_facu': ratingFacu,
    'rating_rocio': ratingRocio,
    'favorited': favorited,
    'user_id': userId ?? AppState.myId ?? '',
    'created_at': createdAt.toIso8601String(),
  };

  factory FavoriteItem.fromMap(Map<String, dynamic> m) {
    final ratingFacu = (m['rating_facu'] as num?)?.toDouble()
        ?? (m['rating'] as num?)?.toDouble()
        ?? 0;
    final ratingRocio = (m['rating_rocio'] as num?)?.toDouble() ?? 0;
    return FavoriteItem(
      id: m['id'] as int?,
      category: m['category'] as String? ?? '',
      title: m['title'] as String? ?? '',
      critica: (m['critica'] as String?) ?? (m['subtitle'] as String?),
      emoji: m['emoji'] as String? ?? '⭐',
      ratingFacu: ratingFacu,
      ratingRocio: ratingRocio,
      favorited: m['favorited'] as bool? ?? false,
      userId: m['user_id'] as String?,
      createdAt: m['created_at'] != null
          ? DateTime.parse(m['created_at'] as String)
          : DateTime.now(),
    );
  }

  FavoriteItem copyWith({
    bool? favorited,
    double? ratingFacu,
    double? ratingRocio,
    String? critica,
    String? emoji,
    String? category,
    String? title,
  }) =>
      FavoriteItem(
        id: id,
        category: category ?? this.category,
        title: title ?? this.title,
        critica: critica ?? this.critica,
        emoji: emoji ?? this.emoji,
        ratingFacu: ratingFacu ?? this.ratingFacu,
        ratingRocio: ratingRocio ?? this.ratingRocio,
        favorited: favorited ?? this.favorited,
        userId: userId,
        createdAt: createdAt,
      );

  double ratingFor(String identity) {
    if (identity == 'Facu') return ratingFacu;
    if (identity == 'Rocio') return ratingRocio;
    return 0;
  }

  bool get hasFacuRating => ratingFacu > 0;
  bool get hasRocioRating => ratingRocio > 0;
  bool get hasAnyRating => hasFacuRating || hasRocioRating;
  bool get bothRated => hasFacuRating && hasRocioRating;

  double get averageRating {
    if (bothRated) return (ratingFacu + ratingRocio) / 2;
    if (hasFacuRating) return ratingFacu;
    if (hasRocioRating) return ratingRocio;
    return 0;
  }
}

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
          callback: (_) => load(),
        )
        .subscribe();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await SupabaseConfig.client
          .from('favorites')
          .select()
          .order('created_at', ascending: false)
          .limit(200)
          .timeout(const Duration(seconds: 10));
      _items = (res as List)
          .map((e) => FavoriteItem.fromMap(e as Map<String, dynamic>))
          .toList();
      _error = null;
      if (_channel == null) _subscribeRealtime();
    } catch (e) {
      _items = [];
      _error = 'No se pudieron cargar los favoritos';
      debugPrint('FavoritesProvider.load error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add(FavoriteItem item) async {
    _error = null;
    try {
      await SupabaseConfig.client
          .from('favorites')
          .insert(item.toMap())
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo guardar el favorito';
      debugPrint('FavoritesProvider.add error: $e');
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> update(int id, FavoriteItem item) async {
    _error = null;
    try {
      final map = item.toMap();
      map.remove('id');
      map.remove('user_id');
      map.remove('created_at');
      await SupabaseConfig.client
          .from('favorites')
          .update(map)
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo actualizar el favorito';
      debugPrint('FavoritesProvider.update error: $e');
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> toggleFav(int id, bool fav) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(favorited: fav);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('favorites')
          .update({'favorited': fav})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
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
      await SupabaseConfig.client
          .from('favorites')
          .update(patch)
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
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
      await SupabaseConfig.client
          .from('favorites')
          .update({'critica': critica})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
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