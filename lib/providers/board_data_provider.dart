import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/board_element.dart';

class BoardDataProvider extends ChangeNotifier {
  List<BoardElement> _elements = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  final Map<int, _PendingMove> _pendingMoves = {};
  final Map<int, _PendingResize> _pendingResizes = {};
  DateTime _lastSync = DateTime.now();

  // ---- Tableros anidados ----
  int _boardId = 1;
  List<Map<String, dynamic>> _boards = [];

  int get boardId => _boardId;
  List<Map<String, dynamic>> get boards => _boards;
  String get boardName {
    for (final b in _boards) {
      if (b['id'] == _boardId) return b['name'] as String? ?? 'Pizarra';
    }
    return 'Pizarra';
  }

  void setBoard(int id) {
    if (id == _boardId) return;
    _boardId = id;
    load();
  }

  /// Carga la lista de tableros para el menú/breadcrumb.
  Future<void> loadBoards() async {
    try {
      final res = await SupabaseConfig.client
          .from('boards')
          .select()
          .order('id', ascending: true)
          .timeout(const Duration(seconds: 10));
      _boards = (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('BoardDataProvider.loadBoards error: $e');
    }
  }

  /// Crea un tablero hijo del actual y devuelve su id.
  Future<int?> createBoard(String name, int parentId) async {
    try {
      final res = await SupabaseConfig.client
          .from('boards')
          .insert({'name': name, 'parent_id': parentId})
          .select('id')
          .single()
          .timeout(const Duration(seconds: 10));
      final newId = res['id'] as int;
      await loadBoards();
      return newId;
    } catch (e) {
      _error = 'No se pudo crear el tablero';
      debugPrint('BoardDataProvider.createBoard error: $e');
      notifyListeners();
      return null;
    }
  }

  List<BoardElement> get elements => _elements;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => !_loading && _elements.isEmpty && _error == null;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @visibleForTesting
  void setElementsForTest(List<BoardElement> els) {
    _elements = List.of(els);
  }

  // Ordenar por z para respetar capas (mayor z = adelante).
  List<BoardElement> get zOrdered {
    final list = [..._elements];
    list.sort((a, b) => a.z.compareTo(b.z));
    return list;
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('board_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_elements',
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.delete) {
              final oldId = payload.oldRecord['id'] as int?;
              if (oldId != null) {
                _elements.removeWhere((e) => e.id == oldId);
                notifyListeners();
              }
              return;
            }
            final el = BoardElement.fromMap(payload.newRecord);
            if (el.boardId != _boardId) return;
            final idx = _elements.indexWhere((e) => e.id == el.id);
            if (idx >= 0) {
              // No pisar moves/resizes locales pendientes con la versión cloud.
              if (_pendingMoves.containsKey(el.id) ||
                  _pendingResizes.containsKey(el.id)) {
                return;
              }
              _elements[idx] = el;
              notifyListeners();
              return;
            }
            // Evita duplicar el elemento optimista recién insertado
            // (misma posición/tipo/contenido y todavía sin id).
            final optIdx = _elements.indexWhere((e) =>
                e.id == null &&
                e.type == el.type &&
                e.content == el.content &&
                (e.x - el.x).abs() < 1 &&
                (e.y - el.y).abs() < 1);
            if (optIdx >= 0) {
              final local = _elements[optIdx];
              _elements[optIdx] = el.copyWith(
                x: local.x,
                y: local.y,
                width: local.width,
                height: local.height,
                content: local.content.isNotEmpty ? local.content : null,
                data: local.data.isNotEmpty ? local.data : null,
                z: local.z,
              );
            } else {
              _elements.add(el);
            }
            notifyListeners();
          },
        )
        .subscribe();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await SupabaseConfig.client
          .from('board_elements')
          .select()
          .eq('board_id', _boardId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      _elements =
          (res as List).map((e) => BoardElement.fromMap(e as Map<String, dynamic>)).toList();
      _error = null;
      if (_channel == null) _subscribeRealtime();
      await loadBoards();
    } catch (e) {
      _elements = [];
      _error = 'No se pudieron cargar los elementos de la pizarra';
      debugPrint('BoardDataProvider.load error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  /// Inserta optimista y fusiona el id cloud devuelto (evita duplicados y
  /// permite seleccionar/conectar/borrar el elemento recién creado).
  Future<void> add(BoardElement el) async {
    _error = null;
    el = el.copyWith(boardId: _boardId);
    _elements.add(el);
    notifyListeners();
    try {
      final res = await SupabaseConfig.client
          .from('board_elements')
          .insert(el.toMap())
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      final cloud = BoardElement.fromMap(res);
      final idx = _elements.indexWhere((e) => identical(e, el));
      if (idx >= 0) {
        // Conserva x/y/data locales por si el usuario ya movió o editó.
        final local = _elements[idx];
        _elements[idx] = cloud.copyWith(
          x: local.x,
          y: local.y,
          width: local.width,
          height: local.height,
          content: local.content,
          data: local.data,
          z: local.z,
        );
      } else {
        // Ya fue reemplazado por realtime u otro path: actualiza por id.
        final byId = _elements.indexWhere((e) => e.id == cloud.id);
        if (byId >= 0) {
          _elements[byId] = cloud;
        } else {
          _elements.add(cloud);
        }
      }
      notifyListeners();
    } catch (e) {
      _elements.removeWhere((e) => identical(e, el));
      _error = 'No se pudo agregar el elemento';
      debugPrint('BoardDataProvider.add error: $e');
      notifyListeners();
    }
  }

  Future<void> update(BoardElement el) async {
    if (el.id == null) return;
    try {
      await SupabaseConfig.client
          .from('board_elements')
          .update(el.toMap())
          .eq('id', el.id!)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo actualizar el elemento';
      debugPrint('BoardDataProvider.update error: $e');
      notifyListeners();
    }
  }

  /// Mueve un elemento localmente (optimista). Con ID persiste hacia Supabase.
  void moveLocal(BoardElement el, double x, double y) {
    if (el.id != null) {
      move(el.id!, x, y);
      return;
    }
    final idx = _elements.indexWhere((e) => identical(e, el));
    if (idx == -1) return;
    _elements[idx] = _elements[idx].copyWith(x: x, y: y);
    notifyListeners();
  }

  Future<void> move(int id, double x, double y) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1 || id == 0) return;
    _elements[idx] = _elements[idx].copyWith(x: x, y: y);
    _pendingMoves[id] = _PendingMove(x, y);
    notifyListeners();
    _scheduleFlush();
  }

  /// Redimensiona un elemento (optimista). Con ID persiste hacia Supabase.
  void resizeLocal(BoardElement el, double width, double height) {
    if (el.id != null) {
      resize(el.id!, width, height);
      return;
    }
    final idx = _elements.indexWhere((e) => identical(e, el));
    if (idx == -1) return;
    _elements[idx] = _elements[idx].copyWith(width: width, height: height);
    notifyListeners();
  }

  Future<void> resize(int id, double width, double height) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1 || id == 0) return;
    _elements[idx] = _elements[idx].copyWith(width: width, height: height);
    _pendingResizes[id] = _PendingResize(width, height);
    notifyListeners();
    _scheduleFlush();
  }

  /// Trae un elemento al frente ajustando su z al máximo + 1 y persistiendo.
  Future<void> bringToFront(int id) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final maxZ = _elements.fold<int>(0, (acc, e) => e.z > acc ? e.z : acc);
    _elements[idx] = _elements[idx].copyWith(z: maxZ + 1);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('board_elements')
          .update({'z': maxZ + 1})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('BoardDataProvider.bringToFront error: $e');
    }
  }

  /// Actualiza el mapa `data` de un elemento (persiste). Funciona con y sin ID.
  void updateDataLocal(BoardElement el, Map<String, dynamic> data) {
    if (el.id != null) {
      _updateData(el.id!, data);
      return;
    }
    final idx = _elements.indexWhere((e) => identical(e, el));
    if (idx == -1) return;
    _elements[idx] = _elements[idx].copyWith(data: data);
    notifyListeners();
  }

  Future<void> _updateData(int id, Map<String, dynamic> data) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _elements[idx] = _elements[idx].copyWith(data: data);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('board_elements')
          .update({'data': data})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('BoardDataProvider._updateData error: $e');
    }
  }

  Future<void> updateContent(int id, String content) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _elements[idx] = _elements[idx].copyWith(content: content);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('board_elements')
          .update({'content': content})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('BoardDataProvider.updateContent error: $e');
    }
  }

  /// Actualiza el contenido localmente por referencia (elementos recién creados).
  void updateContentLocal(BoardElement el, String content) {
    if (el.id != null) {
      updateContent(el.id!, content);
      return;
    }
    final idx = _elements.indexWhere((e) => identical(e, el));
    if (idx == -1) return;
    _elements[idx] = _elements[idx].copyWith(content: content);
    notifyListeners();
  }

  Future<void> delete(int id) async {
    _elements.removeWhere((e) => e.id == id);
    // También limpia conectores huérfanos que apuntaban a este id.
    final orphanIds = _elements
        .where((e) =>
            e.type == 'connector' &&
            (e.data['fromId'] == id || e.data['toId'] == id))
        .map((e) => e.id)
        .whereType<int>()
        .toList();
    _elements.removeWhere((e) =>
        e.type == 'connector' &&
        (e.data['fromId'] == id || e.data['toId'] == id));
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from('board_elements')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
      for (final oid in orphanIds) {
        await SupabaseConfig.client
            .from('board_elements')
            .delete()
            .eq('id', oid)
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      _error = 'No se pudo eliminar el elemento';
      debugPrint('BoardDataProvider.delete error: $e');
      await load();
    }
  }

  /// Borra un elemento sin id (recién creado, insert fallido o pendiente).
  void deleteLocal(BoardElement el) {
    if (el.id != null) {
      delete(el.id!);
      return;
    }
    _elements.removeWhere((e) => identical(e, el));
    notifyListeners();
  }

  void _scheduleFlush() {
    final now = DateTime.now();
    if (now.difference(_lastSync).inMilliseconds < 300) return;
    _lastSync = now;
    _flushPending();
  }

  Future<void> _flushPending() async {
    final moves = Map<int, _PendingMove>.from(_pendingMoves);
    final resizes = Map<int, _PendingResize>.from(_pendingResizes);
    _pendingMoves.clear();
    _pendingResizes.clear();
    for (final entry in moves.entries) {
      try {
        await SupabaseConfig.client
            .from('board_elements')
            .update({'x': entry.value.x, 'y': entry.value.y})
            .eq('id', entry.key)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('BoardDataProvider._flushPending(move) error: $e');
      }
    }
    for (final entry in resizes.entries) {
      try {
        await SupabaseConfig.client
            .from('board_elements')
            .update({'width': entry.value.w, 'height': entry.value.h})
            .eq('id', entry.key)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('BoardDataProvider._flushPending(resize) error: $e');
      }
    }
  }

  @override
  void dispose() {
    _flushPending();
    _channel?.unsubscribe();
    super.dispose();
  }
}

class _PendingMove {
  final double x, y;
  _PendingMove(this.x, this.y);
}

class _PendingResize {
  final double w, h;
  _PendingResize(this.w, this.h);
}
