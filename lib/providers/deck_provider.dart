import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../models/deck_card.dart';

class DeckProvider extends ChangeNotifier {
  List<DeckCard> _cards = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  DeckCard? _pendingMatch;

  List<DeckCard> get cards => _cards;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  DeckCard? get pendingMatch => _pendingMatch;

  @visibleForTesting
  void setCardsForTest(List<DeckCard> cards) {
    _cards = List.unmodifiable(cards);
    notifyListeners();
  }

  void consumeMatch() {
    _pendingMatch = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<DeckCard> pendingFor(String? userId) => userId == null
      ? _cards
      : _cards.where((c) => c.reactionOf(userId) == null).toList();

  List<DeckCard> historyFor(String? userId) =>
      _cards.where((c) => c.reactionOf(userId) != null).toList();

  List<DeckCard> get matches => _cards.where((c) => c.isMatch).toList();
  int get matchCount => matches.length;

  /// Logica pura: aplica cartas del cloud haciendo merge de las reacciones
  /// locales (evita que el realtime pise una reaccion propia en vuelo) y
  /// detecta transiciones a match.
  List<DeckCard> applyCloudCards(List<DeckCard> cloud) {
    final byId = {for (final c in _cards) if (c.id != null) c.id!: c};
    final result = <DeckCard>[];
    for (final c in cloud) {
      final local = c.id == null ? null : byId[c.id];
      final merged = local == null ? c : local.mergedFromCloud(c);
      if (local != null && !local.isMatch && merged.isMatch) {
        _pendingMatch = merged;
      }
      result.add(merged);
    }
    return result;
  }

  /// Actualiza la reaccion en memoria (parte sincrona de [react]).
  DeckCard reactLocal(DeckCard card, String reaction, String userId) {
    final updated = card.withReaction(userId, reaction);
    _replace(card, updated);
    if (!card.isMatch && updated.isMatch) {
      _pendingMatch = updated;
    }
    notifyListeners();
    return updated;
  }

  void _replace(DeckCard oldCard, DeckCard newCard) {
    final idx = _cards.indexWhere((c) =>
        (oldCard.id != null && c.id == oldCard.id) ||
        (oldCard.id == null && identical(c, oldCard)));
    if (idx == -1) return;
    final list = List<DeckCard>.of(_cards);
    list[idx] = newCard;
    _cards = List.unmodifiable(list);
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('deck_cards_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'deck_cards',
          callback: (_) => _reloadSilent(),
        )
        .subscribe();
  }

  Future<void> _reloadSilent() async {
    try {
      final res = await SupabaseConfig.client
          .from('deck_cards')
          .select()
          .order('created_at', ascending: false)
          .limit(200)
          .timeout(const Duration(seconds: 10));
      final cloud = (res as List)
          .map((e) => DeckCard.fromMap(e as Map<String, dynamic>))
          .toList();
      _cards = List.unmodifiable(applyCloudCards(cloud));
      notifyListeners();
    } catch (e) {
      debugPrint('DeckProvider.realtime reload error: $e');
    }
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await SupabaseConfig.client
          .from('deck_cards')
          .select()
          .order('created_at', ascending: false)
          .limit(200)
          .timeout(const Duration(seconds: 10));
      final cloud = (res as List)
          .map((e) => DeckCard.fromMap(e as Map<String, dynamic>))
          .toList();
      _cards = List.unmodifiable(applyCloudCards(cloud));
      _error = null;
      if (_channel == null) _subscribeRealtime();
    } catch (e) {
      _cards = [];
      _error = 'No se pudieron cargar las tarjetas del mazo';
      debugPrint('DeckProvider.load error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> add(String category, String content) async {
    _error = null;
    final card = DeckCard(category: category, content: content);
    try {
      await SupabaseConfig.client
          .from('deck_cards')
          .insert(card.toMap())
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo crear la tarjeta';
      debugPrint('DeckProvider.add error: $e');
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  Future<void> react(DeckCard card, String reaction) async {
    final userId = AppState.myId;
    final cardId = card.id;
    if (userId == null || cardId == null) return;
    reactLocal(card, reaction, userId);
    try {
      // Merge atómico en el servidor (RPC react_deck_card): forma {uid: emoji}.
      final res = await SupabaseConfig.client
          .rpc('react_deck_card', params: {
            'row_id': cardId,
            'user_id': userId,
            'reaction': reaction,
          })
          .timeout(const Duration(seconds: 10));
      final authoritative = _parseReactionMap(res);
      final li = _cards.indexWhere((c) => c.id == cardId);
      if (li >= 0) {
        final live = _cards[li];
        _replace(
          live,
          DeckCard(
            id: live.id,
            category: live.category,
            content: live.content,
            createdBy: live.createdBy,
            reactions: {...live.reactions, ...authoritative},
            createdAt: live.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'No se pudo guardar la reaccion';
      debugPrint('DeckProvider.react error: $e');
      await load();
    }
  }

  Map<String, String> _parseReactionMap(dynamic raw) {
    final out = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is String) out[k] = v;
      });
    }
    return out;
  }

  Future<void> delete(int id) async {
    _cards = List.unmodifiable(_cards.where((c) => c.id != id));
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('deck_cards')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar la tarjeta';
      debugPrint('DeckProvider.delete error: $e');
      await load();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
