import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../models/gallery_item.dart';
import '../services/local_cache.dart';
import '../supabase_config.dart';
import 'helpers/gallery_comments_service.dart';
import 'helpers/gallery_reactions_helper.dart';

export '../models/gallery_item.dart';

class GalleryProvider extends ChangeNotifier {
  List<GalleryItem> _items = [];
  List<GalleryComment> _comments = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  final Set<int> _commentsLoaded = {};

  List<GalleryItem> get items => _items;
  List<GalleryComment> get comments => List.unmodifiable(_comments);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<GalleryComment> commentsFor(int? galleryId) =>
      _comments.where((c) => c.galleryId == galleryId).toList();

  List<String> get albums =>
      _items.map((i) => i.album ?? '✨').toSet().toList();
  List<GalleryItem> byAlbum(String album) =>
      _items.where((i) => (i.album ?? '✨') == album).toList();

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('gallery_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'gallery',
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.delete) {
              final deletedId = payload.oldRecord['id'] as int?;
              _items.removeWhere((i) => i.id == deletedId);
              notifyListeners();
              return;
            }
            final row = payload.newRecord;
            if (row.isEmpty) return;
            final remote = GalleryItem.fromMap(Map<String, dynamic>.from(row));
            final idx = _items.indexWhere((i) => i.id == remote.id);
            if (idx < 0) {
              _items.insert(0, remote);
            } else {
              final existing = _items[idx];
              final effectiveUrl =
                  remote.url.isNotEmpty ? remote.url : existing.url;
              final effectiveThumb =
                  (remote.thumbnail != null && remote.thumbnail!.isNotEmpty)
                      ? remote.thumbnail
                      : existing.thumbnail;
              _items[idx] = remote.copyWith(
                url: effectiveUrl,
                thumbnail: effectiveThumb,
                reactions: GalleryReactionsHelper.mergeReactions(
                    existing.reactions, remote.reactions),
              );
            }
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'gallery_comments',
          callback: (payload) {
            final row = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final gid = (row['gallery_id'] as num?)?.toInt();
            if (gid == null || !_commentsLoaded.contains(gid)) return;
            loadComments(gid);
          },
        )
        .subscribe();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    final cached = await LocalCache.getList('cache_gallery');
    if (cached.isNotEmpty) {
      _items = cached.map((m) => GalleryItem.fromMap(m)).toList();
      _loading = false;
      notifyListeners();
    }
    try {
      final res = await SupabaseConfig.client
          .from('gallery')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      _items = (res as List)
          .map((e) => GalleryItem.fromMap(e as Map<String, dynamic>))
          .toList();
      await LocalCache.setList(
          'cache_gallery', _items.map((i) => i.toMap()).toList());
      if (_channel == null) _subscribeRealtime();
    } catch (e) {
      if (_items.isEmpty) _error = 'No se pudieron cargar las fotos';
      debugPrint('GalleryProvider.load error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> uploadAndAdd(String filePath,
      {String? album, String? label}) async {
    _error = null;
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _error = 'Archivo no encontrado';
        notifyListeners();
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        _error = 'Imagen muy grande (max 2MB)';
        notifyListeners();
        return;
      }
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      debugPrint('Gallery: storing base64 image (${bytes.length} bytes)');

      await SupabaseConfig.client.from('gallery').insert({
        'user_id': AppState.myId ?? '',
        'url': b64,
        'thumbnail': b64,
        'type': 'photo',
        'album': album,
        'label': label ?? '📸',
        'size': 1.0,
      }).timeout(const Duration(seconds: 15));
      debugPrint('Gallery: insert OK');
    } catch (e) {
      _error = 'Error al subir: $e';
      debugPrint('GalleryProvider.uploadAndAdd ERROR: $e');
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> delete(int id) async {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('gallery')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar la foto';
      debugPrint('GalleryProvider.delete error: $e');
      await load();
      notifyListeners();
    }
  }

  Future<void> updateDescription(int id, String description) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final next = _items[idx].copyWith(description: description);
    _items[idx] = next;
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('gallery')
          .update({'description': description})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('GalleryProvider.updateDescription error: $e');
    }
  }

  Future<void> toggleReaction(int id, String key) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final current = _items[idx];
    final reactions = GalleryReactionsHelper.toggleUserReaction(
      currentReactions: current.reactions,
      key: key,
      userId: AppState.myId ?? '',
    );
    final next = current.copyWith(reactions: reactions);
    _items[idx] = next;
    notifyListeners();
    try {
      final res = await SupabaseConfig.client
          .rpc('toggle_reaction', params: {
            'target_table': 'gallery',
            'target_col': 'reactions',
            'row_id': id,
            'reaction_key': key,
            'user_id': AppState.myId ?? '',
          })
          .timeout(const Duration(seconds: 10));
      if (res != null) {
        final li = _items.indexWhere((i) => i.id == id);
        if (li >= 0) {
          _items[li] = _items[li]
              .copyWith(reactions: GalleryItem.parseReactions(res));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('GalleryProvider.toggleReaction RPC error: $e');
      try {
        await SupabaseConfig.client
            .from('gallery')
            .update({'reactions': reactions})
            .eq('id', id)
            .timeout(const Duration(seconds: 5));
      } catch (fallbackErr) {
        _items[idx] = current;
        debugPrint('GalleryProvider.toggleReaction fallback: $fallbackErr');
        notifyListeners();
      }
    }
  }

  Future<void> addComment(int galleryId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimisticComment = GalleryComment(
      id: tempId,
      galleryId: galleryId,
      userId: AppState.myId,
      content: text,
      createdAt: DateTime.now(),
    );

    _comments.add(optimisticComment);
    notifyListeners();

    final realComment = await GalleryCommentsService.addComment(
      galleryId: galleryId,
      userId: AppState.myId ?? '',
      content: text,
    );

    if (realComment != null) {
      final idx = _comments.indexWhere((c) => c.id == tempId);
      if (idx != -1) _comments[idx] = realComment;
      notifyListeners();
    }
  }

  Future<void> deleteComment(int id) async {
    _comments.removeWhere((c) => c.id == id);
    notifyListeners();
    await GalleryCommentsService.deleteComment(id);
  }

  Future<void> loadComments(int galleryId) async {
    final comments = await GalleryCommentsService.loadComments(galleryId);
    final existing =
        _comments.where((c) => c.galleryId != galleryId).toList();
    existing.addAll(comments);
    _comments = existing;
    _commentsLoaded.add(galleryId);
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
