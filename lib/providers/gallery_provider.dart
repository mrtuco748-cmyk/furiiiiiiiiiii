import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../app_state.dart';

class GalleryItem {
  final int? id;
  final String? userId;
  final String url;
  final String? thumbnail;
  final String type;
  final String? album;
  final String? label;
  final double rotation;
  final double size;
  final DateTime createdAt;

  GalleryItem({
    this.id, required this.url, this.thumbnail, this.type = 'photo',
    this.album, this.label, this.rotation = 0, this.size = 1.0, this.userId, DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'url': url, 'thumbnail': thumbnail, 'type': type,
    'album': album, 'label': label, 'rotation': rotation, 'size': size,
    'user_id': AppState.myId ?? '', 'created_at': createdAt.toIso8601String(),
  };

  factory GalleryItem.fromMap(Map<String, dynamic> m) => GalleryItem(
    id: m['id'] as int?, url: m['url'] as String? ?? '', thumbnail: m['thumbnail'] as String?,
    type: m['type'] as String? ?? 'photo', album: m['album'] as String?,
    label: m['label'] as String?, rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
    size: (m['size'] as num?)?.toDouble() ?? 1.0,
    userId: m['user_id'] as String?,
    createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
  );
}

class GalleryProvider extends ChangeNotifier {
  List<GalleryItem> _items = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<GalleryItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() { _error = null; notifyListeners(); }

  List<String> get albums => _items.map((i) => i.album ?? '✨').toSet().toList();
  List<GalleryItem> byAlbum(String album) => _items.where((i) => (i.album ?? '✨') == album).toList();

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client.channel('gallery_changes').onPostgresChanges(
      event: PostgresChangeEvent.all, schema: 'public', table: 'gallery',
      callback: (payload) {
        final row = payload.newRecord;
        if (payload.eventType == PostgresChangeEvent.delete) {
          _items.removeWhere((i) => i.id == (row?['id'] as int?));
        } else { load(); }
      },
    ).subscribe();
  }

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await SupabaseConfig.client.from('gallery').select()
          .order('created_at', ascending: false).limit(50).timeout(const Duration(seconds: 10));
      _items = (res as List).map((e) => GalleryItem.fromMap(e as Map<String, dynamic>)).toList();
      if (_channel == null) _subscribeRealtime();
    } catch (e) {
      _items = [];
      _error = 'No se pudieron cargar las fotos';
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
    } catch (e) { await load(); }
  }

  @override
  void dispose() { _channel?.unsubscribe(); super.dispose(); }
}
