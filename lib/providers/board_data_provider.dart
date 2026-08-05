import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../app_state.dart';

class BoardElement {
  final int? id;
  final String type;
  final String content;
  final double x, y, width, height, rotation;
  final String? color;
  final String? userId;
  final DateTime createdAt;

  BoardElement({
    this.id, required this.type, this.content = '', this.x = 20, this.y = 20,
    this.width = 100, this.height = 80, this.rotation = 0, this.color, this.userId, DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'type': type, 'content': content,
    'x': x, 'y': y, 'width': width, 'height': height, 'rotation': rotation,
    'color': color, 'user_id': AppState.myId ?? '', 'created_at': createdAt.toIso8601String(),
  };

  factory BoardElement.fromMap(Map<String, dynamic> m) => BoardElement(
    id: m['id'] as int?, type: m['type'] as String? ?? 'note',
    content: m['content'] as String? ?? '', x: (m['x'] as num?)?.toDouble() ?? 20,
    y: (m['y'] as num?)?.toDouble() ?? 20, width: (m['width'] as num?)?.toDouble() ?? 100,
    height: (m['height'] as num?)?.toDouble() ?? 80, rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
    color: m['color'] as String?, userId: m['user_id'] as String?,
    createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
  );

  BoardElement copyWith({double? x, double? y}) => BoardElement(
    id: id, type: type, content: content, x: x ?? this.x, y: y ?? this.y,
    width: width, height: height, rotation: rotation, color: color, userId: userId, createdAt: createdAt,
  );

  bool get isMine => userId == AppState.myId;
}

class BoardDataProvider extends ChangeNotifier {
  List<BoardElement> _elements = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  final Map<int, _PendingMove> _pendingMoves = {};
  DateTime _lastSync = DateTime.now();

  List<BoardElement> get elements => _elements;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() { _error = null; notifyListeners(); }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('board_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_elements',
          callback: (payload) {
            final row = payload.newRecord;
            if (row == null) {
              load();
              return;
            }
            final el = BoardElement.fromMap(row as Map<String, dynamic>);
            final idx = _elements.indexWhere((e) => e.id == el.id);
            if (payload.eventType == PostgresChangeEvent.delete) {
              _elements.removeWhere((e) => e.id == el.id);
              notifyListeners();
            } else if (idx >= 0) {
              _elements[idx] = el;
              notifyListeners();
            } else {
              _elements.insert(0, el);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await SupabaseConfig.client.from('board_elements').select()
          .order('created_at', ascending: false).timeout(const Duration(seconds: 10));
      _elements = (res as List).map((e) => BoardElement.fromMap(e as Map<String, dynamic>)).toList();
      _error = null;
      if (_channel == null) _subscribeRealtime();
    } catch (e) {
      _elements = [];
      _error = 'No se pudieron cargar los elementos de la pizarra';
      debugPrint('BoardDataProvider.load error: $e');
    }
    _loading = false; notifyListeners();
  }

  Future<void> add(BoardElement el) async {
    _error = null;
    _elements.insert(0, el);
    notifyListeners();
    try {
      await SupabaseConfig.client.from('board_elements').insert(el.toMap()).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo agregar el elemento';
      debugPrint('BoardDataProvider.add error: $e');
      notifyListeners();
    }
  }

  Future<void> update(BoardElement el) async {
    if (el.id == null) return;
    try {
      await SupabaseConfig.client.from('board_elements').update(el.toMap()).eq('id', el.id!).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo actualizar el elemento';
      debugPrint('BoardDataProvider.update error: $e');
      notifyListeners();
    }
  }

  Future<void> move(int id, double x, double y) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    if (id == 0) return;
    _elements[idx] = _elements[idx].copyWith(x: x, y: y);
    _pendingMoves[id] = _PendingMove(x, y);
    notifyListeners();

    final now = DateTime.now();
    if (now.difference(_lastSync).inMilliseconds < 300) return;
    _lastSync = now;
    await _flushMoves();
  }

  Future<void> _flushMoves() async {
    if (_pendingMoves.isEmpty) return;
    final moves = Map<int, _PendingMove>.from(_pendingMoves);
    _pendingMoves.clear();
    for (final entry in moves.entries) {
      try {
        await SupabaseConfig.client.from('board_elements')
            .update({'x': entry.value.x, 'y': entry.value.y})
            .eq('id', entry.key)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('BoardDataProvider._flushMoves error: $e');
      }
    }
  }

  Future<void> updateContent(int id, String content) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _elements[idx] = BoardElement(
      id: _elements[idx].id, type: _elements[idx].type,
      content: content, x: _elements[idx].x, y: _elements[idx].y,
      width: _elements[idx].width, height: _elements[idx].height,
      rotation: _elements[idx].rotation, color: _elements[idx].color,
      userId: _elements[idx].userId, createdAt: _elements[idx].createdAt,
    );
    notifyListeners();
    try {
      await SupabaseConfig.client.from('board_elements').update({'content': content}).eq('id', id).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('BoardDataProvider.updateContent error: $e');
    }
  }

  Future<void> delete(int id) async {
    _elements.removeWhere((e) => e.id == id); notifyListeners();
    try {
      await SupabaseConfig.client.from('board_elements').delete().eq('id', id).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar el elemento';
      debugPrint('BoardDataProvider.delete error: $e');
      await load();
    }
  }

  @override
  void dispose() {
    _flushMoves();
    _channel?.unsubscribe();
    super.dispose();
  }
}

class _PendingMove {
  final double x, y;
  _PendingMove(this.x, this.y);
}
