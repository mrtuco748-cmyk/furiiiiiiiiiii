import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../services/local_cache.dart';

class GalleryComment {
  final int? id;
  final int? galleryId;
  final String? userId;
  final String content;
  final DateTime createdAt;

  GalleryComment({
    this.id, this.galleryId, this.userId, required this.content, DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GalleryComment.fromMap(Map<String, dynamic> m) => GalleryComment(
    id: m['id'] as int?, galleryId: m['gallery_id'] as int?,
    userId: m['user_id'] as String?, content: m['content'] as String? ?? '',
    createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at'] as String) : DateTime.now(),
  );
}

class GalleryItem {
  final int? id;
  final String? userId;
  final String url;
  final String? thumbnail;
  final String type;
  final String? album;
  final String? label;
  final String? description;
  final Map<String, List<String>> reactions;
  final double rotation;
  final double size;
  final DateTime createdAt;

  GalleryItem({
    this.id, required this.url, this.thumbnail, this.type = 'photo',
    this.album, this.label, this.description, this.rotation = 0, this.size = 1.0,
    this.userId, Map<String, List<String>>? reactions, DateTime? createdAt,
  }) : reactions = reactions ?? const {},
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'url': url, 'thumbnail': thumbnail, 'type': type,
    'album': album, 'label': label, 'description': description,
    'reactions': reactions, 'rotation': rotation, 'size': size,
    'user_id': AppState.myId ?? '', 'created_at': createdAt.toIso8601String(),
  };

  factory GalleryItem.fromMap(Map<String, dynamic> m) => GalleryItem(
    id: m['id'] as int?, url: m['url'] as String? ?? '', thumbnail: m['thumbnail'] as String?,
    type: m['type'] as String? ?? 'photo', album: m['album'] as String?,
    label: m['label'] as String?, description: m['description'] as String?,
    reactions: parseReactions(m['reactions']),
    rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
    size: (m['size'] as num?)?.toDouble() ?? 1.0,
    userId: m['user_id'] as String?,
    createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
  );

  GalleryItem copyWith({String? description, Map<String, List<String>>? reactions}) => GalleryItem(
    id: id, userId: userId, url: url, thumbnail: thumbnail, type: type,
    album: album, label: label, description: description ?? this.description,
    reactions: reactions ?? this.reactions, rotation: rotation, size: size, createdAt: createdAt,
  );

  static Map<String, List<String>> parseReactions(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    final out = <String, List<String>>{};
    raw.forEach((k, v) {
      final key = k.toString();
      if (v is List) out[key] = v.map((e) => e.toString()).toList();
    });
    return out;
  }
}

class GalleryProvider extends ChangeNotifier {
  List<GalleryItem> _items = [];
  List<GalleryComment> _comments = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  /// Ids de galería cuyos comentarios ya se cargaron (para saber a quién
  /// refrescar cuando llega un comentario por realtime).
  final Set<int> _commentsLoaded = {};

  List<GalleryItem> get items => _items;
  List<GalleryComment> get comments => List.unmodifiable(_comments);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() { _error = null; notifyListeners(); }

  List<GalleryComment> commentsFor(int? galleryId) =>
      _comments.where((c) => c.galleryId == galleryId).toList();

  List<String> get albums => _items.map((i) => i.album ?? '✨').toSet().toList();
  List<GalleryItem> byAlbum(String album) => _items.where((i) => (i.album ?? '✨') == album).toList();

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client.channel('gallery_changes').onPostgresChanges(
      event: PostgresChangeEvent.all, schema: 'public', table: 'gallery',
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.delete) {
          final deletedId = payload.oldRecord['id'] as int?;
          _items.removeWhere((i) => i.id == deletedId);
          notifyListeners();
        } else { load(); }
      },
    ).onPostgresChanges(
      // Comentarios en vivo: si la pareja comenta una foto que ya tengo
      // abierta/cargada, refrescar solo esos comentarios (antes no llegaban
      // hasta cerrar y reabrir la foto).
      event: PostgresChangeEvent.all, schema: 'public', table: 'gallery_comments',
      callback: (payload) {
        final row = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
        final gid = (row['gallery_id'] as num?)?.toInt();
        if (gid == null || !_commentsLoaded.contains(gid)) return;
        loadComments(gid);
      },
    ).subscribe();
  }
  Future<void> load() async {
    _loading = true;
    _error = null;
    // Cache local (offline-first): mostramos lo último conocido de inmediato.
    final cached = await LocalCache.getList('cache_gallery');
    if (cached.isNotEmpty) {
      _items = cached.map((m) => GalleryItem.fromMap(m)).toList();
      _loading = false;
      notifyListeners();
    }
    try {
      final res = await SupabaseConfig.client.from('gallery').select()
          .order('created_at', ascending: false).limit(50).timeout(const Duration(seconds: 10));
      _items = (res as List).map((e) => GalleryItem.fromMap(e as Map<String, dynamic>)).toList();
      await LocalCache.setList(
          'cache_gallery', _items.map((i) => i.toMap()).toList());
      if (_channel == null) _subscribeRealtime();
    } catch (e) {
      if (_items.isEmpty) _error = 'No se pudieron cargar las fotos';
      debugPrint('GalleryProvider.load error: $e');
    }
    _loading = false; notifyListeners();
  }
  Future<void> uploadAndAdd(String filePath, {String? album, String? label}) async {
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
    _items.removeWhere((i) => i.id == id); notifyListeners();
    try {
      await SupabaseConfig.client.from('gallery').delete().eq('id', id).timeout(const Duration(seconds: 10));
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
      await SupabaseConfig.client.from('gallery')
          .update({'description': description}).eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('GalleryProvider.updateDescription error: $e');
    }
  }

  Future<void> toggleReaction(int id, String key) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final current = _items[idx];
    final reactions = <String, List<String>>{};
    current.reactions.forEach((k, v) => reactions[k] = List<String>.from(v));
    final already = reactions[key]?.contains(AppState.myId) ?? false;
    final toRemove = <String>[];
    reactions.forEach((k, list) {
      list.remove(AppState.myId);
      if (list.isEmpty) toRemove.add(k);
    });
    for (final k in toRemove) { reactions.remove(k); }
    if (!already) {
      reactions.putIfAbsent(key, () => <String>[]).add(AppState.myId ?? '');
    }
    final next = current.copyWith(reactions: reactions);
    _items[idx] = next;
    notifyListeners();
    try {
      // Merge atómico en el servidor (RPC toggle_reaction).
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
          _items[li] = _items[li].copyWith(reactions: GalleryItem.parseReactions(res));
          notifyListeners();
        }
      }
    } catch (e) {
      _items[idx] = current;
      debugPrint('GalleryProvider.toggleReaction error: $e');
      notifyListeners();
    }
  }

  Future<void> addComment(int galleryId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return;
    try {
      final row = await SupabaseConfig.client.from('gallery_comments')
          .insert({
            'gallery_id': galleryId,
            'user_id': AppState.myId ?? '',
            'content': text,
          }).select().single().timeout(const Duration(seconds: 10));
      _comments.add(GalleryComment.fromMap(Map<String, dynamic>.from(row as Map)));
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo comentar';
      debugPrint('GalleryProvider.addComment error: $e');
      notifyListeners();
    }
  }

  Future<void> deleteComment(int id) async {
    _comments.removeWhere((c) => c.id == id); notifyListeners();
    try {
      await SupabaseConfig.client.from('gallery_comments').delete().eq('id', id).timeout(const Duration(seconds: 10));
    } catch (e) { debugPrint('GalleryProvider.deleteComment error: $e'); }
  }

  Future<void> loadComments(int galleryId) async {
    try {
      final res = await SupabaseConfig.client.from('gallery_comments')
          .select().eq('gallery_id', galleryId)
          .order('created_at', ascending: true).timeout(const Duration(seconds: 10));
      final existing = _comments.where((c) => c.galleryId != galleryId).toList();
      existing.addAll((res as List).map((e) => GalleryComment.fromMap(e as Map<String, dynamic>)));
      _comments = existing;
      _commentsLoaded.add(galleryId);
      notifyListeners();
    } catch (e) {
      debugPrint('GalleryProvider.loadComments error: $e');
    }
  }

  @override
  void dispose() { _channel?.unsubscribe(); super.dispose(); }
}
