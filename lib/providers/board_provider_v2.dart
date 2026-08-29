import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../database/database_helper.dart';
import '../models/board_element_v2.dart';
import '../models/board_element_data.dart';
import '../app_state.dart';

class BoardProviderV2 extends ChangeNotifier {
  List<BoardElementV2> _elements = [];
  List<BoardActivity> _activity = [];
  List<Map<String, dynamic>> _boards = [];
  bool _loading = false;
  String? _error;
  int _boardId = 1;
  RealtimeChannel? _channel;
  final Map<int, Timer> _debounceTimers = {};
  final Set<int> _dirtyElements = {};
  bool _isOnline = true;

  // Getters
  List<BoardElementV2> get elements => _elements.where((e) => !e.isArchived).toList();
  List<BoardElementV2> get allElements => _elements;
  List<BoardElementV2> get archivedElements => _elements.where((e) => e.isArchived).toList();
  List<BoardActivity> get activity => _activity;
  List<Map<String, dynamic>> get boards => _boards;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => !_loading && _elements.isEmpty;
  int get boardId => _boardId;
  bool get isOnline => _isOnline;

  /// Nombre del tablero actual (breadcrumb).
  String get boardName {
    for (final b in _boards) {
      if (b['id'] == _boardId) return b['name'] as String? ?? 'Pizarra';
    }
    return 'Pizarra';
  }

  /// Id del tablero padre del actual (null si es el raiz).
  int? get parentBoardId {
    for (final b in _boards) {
      if (b['id'] == _boardId) return b['parent_id'] as int?;
    }
    return null;
  }

  void setBoard(int id) {
    if (id == _boardId) return;
    _boardId = id;
    load();
  }

  void goBackBoard() {
    final parent = parentBoardId;
    if (parent != null) setBoard(parent);
  }

  Future<void> loadBoards() async {
    try {
      final res = await SupabaseConfig.client
          .from('boards')
          .select()
          .order('created_at', ascending: true)
          .timeout(const Duration(seconds: 10));
      _boards = (res as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (e) {
      debugPrint('BoardProviderV2.loadBoards error: $e');
    }
  }

  Future<int?> createBoard(String name, int parentId) async {
    try {
      final res = await SupabaseConfig.client
          .from('boards')
          .insert({'name': name, 'parent_id': parentId})
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      final id = res['id'] as int;
      await loadBoards();
      return id;
    } catch (e) {
      debugPrint('BoardProviderV2.createBoard error: $e');
      _error = 'No se pudo crear el tablero';
      notifyListeners();
      return null;
    }
  }

  /// Busca el elemento vivo por id cloud (null-safe).
  BoardElementV2? findById(int? id) {
    if (id == null) return null;
    for (final e in _elements) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Carga elementos: primero SQLite (offline), luego Supabase (online).
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Cargar desde SQLite (offline-first)
      await _loadFromLocal();

      // 2. Si hay internet, sincronizar con Supabase
      _isOnline = await _checkConnection();
      if (_isOnline) {
        await _syncFromCloud();
        _subscribeRealtime();
      }
    } catch (e) {
      _error = 'No se pudo cargar el pizarrón';
      debugPrint('BoardProviderV2.load error: $e');
    }

    _loading = false;
    if (_isOnline) await loadBoards();
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query(
        'board_elements_v2',
        where: 'board_id = ?',
        whereArgs: [_boardId],
        orderBy: 'z ASC, created_at ASC',
      );
      _elements = rows
          .map((r) {
            // Convert ints back to bools
            final map = Map<String, dynamic>.from(r);
            map['is_bold'] = (map['is_bold'] as int?) == 1;
            map['is_italic'] = (map['is_italic'] as int?) == 1;
            map['is_underline'] = (map['is_underline'] as int?) == 1;
            map['is_collapsed'] = (map['is_collapsed'] as int?) == 1;
            map['is_locked'] = (map['is_locked'] as int?) == 1;
            map['is_archived'] = (map['is_archived'] as int?) == 1;
            map['is_new'] = (map['is_new'] as int?) == 1;
            // Parse JSON strings
            if (map['tags'] is String) {
              try { map['tags'] = jsonDecode(map['tags'] as String); } catch (_) {}
            }
            if (map['data'] is String) {
              try { map['data'] = jsonDecode(map['data'] as String); } catch (_) {}
            }
            // Id cloud distinto del rowid local. Reglas:
            //  - cloud_id != null → id = cloud_id (elemento sincronizado)
            //  - cloud_id null + synced=1 → id legado = cloud_id (migración v9)
            //  - cloud_id null + synced=0 → nunca sincronizado → id = null
            final cloudId = map['cloud_id'] as int?;
            final synced = map['synced'] as int? ?? 0;
            if (cloudId == null && synced == 0) {
              map['id'] = null;
            } else {
              map['id'] = cloudId ?? map['id'];
            }
            return BoardElementV2.fromMap(map);
          })
          .toList();
    } catch (e) {
      debugPrint('BoardProviderV2._loadFromLocal error: $e');
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      // BUG 10: Cargar IDs de elementos locales dirty (synced=0) antes de mergear.
      final db = await DatabaseHelper().database;
      final dirtyRows = await db.query(
        'board_elements_v2',
        columns: ['id'],
        where: 'synced = 0',
      );
      final dirtyIds = dirtyRows
          .map((r) => r['id'] as int?)
          .where((id) => id != null)
          .map((id) => id!)
          .toSet();

      final res = await SupabaseConfig.client
          .from('board_elements_v2')
          .select()
          .eq('board_id', _boardId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      final cloudElements = (res as List)
          .map((e) => BoardElementV2.fromMap(e as Map<String, dynamic>))
          .toList();

      // Merge parcial: preservar cambios locales y aplicar los del cloud.
      // Si el local está marcado como dirty (modificado offline), preservar
      // x/y y otros campos localmente; aplicar del cloud solo lo que venga
      // actualizado (title, color, priority, etc.) y usar updatedAt del más nuevo.
      for (final cloudEl in cloudElements) {
        final localIdx = _elements.indexWhere((e) => e.id == cloudEl.id);
        if (localIdx >= 0) {
          final local = _elements[localIdx];

          // Determinar si preservar coordenadas locales (elemento modificado offline)
          final preserveLocalXY =
              local.id != null && dirtyIds.contains(local.id);

          // Merge parcial: preservar x/y locales si está dirty, sino usar del cloud
          final resultX = preserveLocalXY || cloudEl.x == null ? local.x : cloudEl.x;
          final resultY = preserveLocalXY || cloudEl.y == null ? local.y : cloudEl.y;

          // Merge de otros campos: usar del cloud si vienen actualizados y son distintos
          final resultTitle =
              cloudEl.title != null && cloudEl.title.isNotEmpty &&
                      (local.title == null || local.title != cloudEl.title)
                  ? cloudEl.title
                  : local.title;
          final resultColor =
              cloudEl.color != null && cloudEl.color != local.color
                  ? cloudEl.color
                  : local.color;
          final resultPriority = cloudEl.priority ?? local.priority;
          final resultZ = cloudEl.z ?? local.z;

          // Usar updatedAt del más nuevo
          final resultUpdatedAt =
              cloudEl.updatedAt.isAfter(local.updatedAt)
                  ? cloudEl.updatedAt
                  : local.updatedAt;

          final merged = local.copyWith(
            x: resultX,
            y: resultY,
            title: resultTitle,
            color: resultColor,
            priority: resultPriority,
            z: resultZ,
            updatedAt: resultUpdatedAt,
          );
          _elements[localIdx] = merged;
        } else {
          _elements.add(cloudEl);
        }
      }

      // Subir elementos locales no sincronizados
      await _pushUnsyncedToCloud();

      // Marcar elementos como "nuevos" si fueron creados en última hora
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      for (final el in _elements) {
        if (el.isNew && el.createdAt.isBefore(oneHourAgo)) {
          final idx = _elements.indexWhere((e) => e.id == el.id);
          if (idx >= 0) {
            _elements[idx] = el.copyWith(isNew: false);
          }
        }
      }
    } catch (e) {
      debugPrint('BoardProviderV2._syncFromCloud error: $e');
    }
  }

  Future<void> _pushUnsyncedToCloud() async {
    final db = await DatabaseHelper().database;
    final unsynced = await db.query(
      'board_elements_v2',
      where: 'synced = 0',
    );

    for (final row in unsynced) {
      try {
        final el = BoardElementV2.fromMap(Map<String, dynamic>.from(row));
        final localId = el.cloudId;

        if (localId != null) {
          // Elemento ya sincronizado pero modificado offline → UPDATE por id cloud.
          await SupabaseConfig.client
              .from('board_elements_v2')
              .update(el.toMap())
              .eq('id', localId)
              .timeout(const Duration(seconds: 10));
          await db.update(
            'board_elements_v2',
            {'synced': 1},
            where: 'cloud_id = ?',
            whereArgs: [localId],
          );
          final mi = _elements.indexWhere((e) => e.cloudId == localId);
          if (mi >= 0) {
            _elements[mi] = _elements[mi].copyWith(
                id: localId, cloudId: localId);
          }
        } else {
          // Elemento nuevo, nunca sincronizado → INSERT. Insertar SIN id local
          // (el rowid de SQLite NO es un id cloud válido y colisionaría).
          final res = await SupabaseConfig.client
              .from('board_elements_v2')
              .insert(el.copyWith(clearId: true, clearCloudId: true).toMap())
              .select()
              .single()
              .timeout(const Duration(seconds: 10));
          final cloudId = res['id'] as int;

          final updated = el.copyWith(id: cloudId, cloudId: cloudId);
          // Reconciliar en memoria (por createdAt del snapshot) y en SQLite
          // usando cloud_id como clave.
          final idx = _elements.indexWhere((e) => e.createdAt == el.createdAt);
          if (idx >= 0) _elements[idx] = updated;
          await db.update(
            'board_elements_v2',
            {'cloud_id': cloudId, 'synced': 1},
            where: 'created_at = ?',
            whereArgs: [el.createdAt.toIso8601String()],
          );
        }
      } catch (e) {
        debugPrint('BoardProviderV2._pushUnsyncedToCloud error: $e');
      }
    }
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('board_v2_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_elements_v2',
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.delete) {
              final oldId = payload.oldRecord['id'] as int?;
              if (oldId != null) {
                _elements.removeWhere((e) => e.id == oldId);
                _deleteLocal(oldId);
                notifyListeners();
              }
              return;
            }

            final el = BoardElementV2.fromMap(payload.newRecord);
            if (el.boardId != _boardId) return;

            final idx = _elements.indexWhere((e) => e.id == el.id);
            if (idx >= 0) {
              // No pisar un cambio local pendiente (p. ej. un move en curso,
              // o un update que aún no subió a la nube): preservamos la
              // posición local y dejamos que el propio debounce retrase el
              // valor autoritativo. Así el realtime no "rompe" el drag.
              if (_dirtyElements.contains(el.id)) {
                final local = _elements[idx];
                _elements[idx] = el.copyWith(x: local.x, y: local.y);
                _saveToLocal(_elements[idx]);
              } else if (el.updatedAt.isAfter(_elements[idx].updatedAt)) {
                // BUG 2: Merge reactions del cloud con las locales (evita race condition).
                final localReactions = _reactionsOf(_elements[idx].data);
                final cloudReactions = _reactionsOf(el.data);
                if (localReactions.isNotEmpty && cloudReactions.isNotEmpty) {
                  final merged = <String, List<String>>{};
                  for (final entry in cloudReactions.entries) {
                    merged[entry.key] = List<String>.from(entry.value);
                  }
                  for (final entry in localReactions.entries) {
                    if (merged.containsKey(entry.key)) {
                      for (final uid in entry.value) {
                        if (!merged[entry.key]!.contains(uid)) {
                          merged[entry.key]!.add(uid);
                        }
                      }
                    } else {
                      merged[entry.key] = List<String>.from(entry.value);
                    }
                  }
                  final mergedData = Map<String, dynamic>.from(el.data);
                  mergedData['reactions'] = merged;
                  _elements[idx] = el.copyWith(data: mergedData);
                } else {
                  _elements[idx] = el;
                }
                _saveToLocal(_elements[idx]);
              }
            } else {
              _elements.add(el);
              _saveToLocal(el);
            }
            notifyListeners();
          },
        )
        .subscribe();
  }

  /// Agrega un elemento nuevo (optimista).
  Future<void> add(BoardElementV2 el) async {
    _error = null;
    el = el.copyWith(boardId: _boardId);
    _elements.add(el);
    notifyListeners();

    // Guardar local inmediatamente
    await _saveToLocal(el);

    // Agregar actividad
    _addActivity(
      action: 'created',
      elementId: el.id,
      elementType: el.type,
      description: '${AppState.identity ?? 'Alguien'} creó ${_typeName(el.type)}',
    );

    // Si hay internet, subir a cloud
    if (_isOnline) {
      try {
        final res = await SupabaseConfig.client
            .from('board_elements_v2')
            .insert(el.toMap())
            .select()
            .single()
            .timeout(const Duration(seconds: 10));

        final cloudId = res['id'] as int;
        final cloudEl = BoardElementV2.fromMap(res)
            .copyWith(id: cloudId, cloudId: cloudId);
        final idx = _elements.indexWhere((e) => e.createdAt == el.createdAt);
        if (idx >= 0) {
          _elements[idx] = cloudEl.copyWith(
            x: _elements[idx].x,
            y: _elements[idx].y,
            title: _elements[idx].title,
            content: _elements[idx].content,
            data: _elements[idx].data,
          );
          // Marcar synced en SQLite, guardando cloud_id del id cloud.
          final db = await DatabaseHelper().database;
          await db.update(
            'board_elements_v2',
            {'synced': 1, 'cloud_id': cloudId, 'id': cloudId},
            where: 'created_at = ?',
            whereArgs: [el.createdAt.toIso8601String()],
          );
        }
        notifyListeners();
      } catch (e) {
        _error = 'No se pudo sincronizar el elemento';
        debugPrint('BoardProviderV2.add error: $e');
        notifyListeners();
      }
    }
  }

  String _typeName(String type) {
    switch (type) {
      case BoardElementType.note: return 'una nota';
      case BoardElementType.checklist: return 'una checklist';
      case BoardElementType.drawing: return 'un dibujo';
      case BoardElementType.video: return 'un video';
      case BoardElementType.audio: return 'un audio';
      case BoardElementType.connector: return 'un conector';
      default: return 'un elemento';
    }
  }

  /// Mueve un elemento en x/y. Funciona también sin id cloud (recién creado):
  /// actualiza solo la copia local hasta que el insert de cloud devuelva el id.
Future<void> moveLocal(BoardElementV2 el, double x, double y) async {
    var idx = _elements.indexWhere((e) => identical(e, el));
    if (idx == -1) {
      idx = _elements.indexWhere((e) => e.id == el.id);
    }
    if (idx == -1) {
      idx = _elements.indexWhere((e) => e.createdAt == el.createdAt);
    }
    if (idx == -1) return;

    if (_elements[idx].isLocked) return;

    final previous = _elements[idx];
    final updated = previous.copyWith(
      x: x,
      y: y,
      updatedAt: DateTime.now(),
    );
    _elements[idx] = updated;
    notifyListeners();

    await _saveToLocal(updated);

    final id = updated.id;
    if (id == null) return;
    _dirtyElements.add(id);

    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 300), () async {
      _debounceTimers.remove(id);
      if (!_isOnline) {
        // BUG 1+9: Marcar como no sincronizado para retry en próxima carga.
        await _markUnsynced(id);
        return;
      }
      try {
        await SupabaseConfig.client
            .from('board_elements_v2')
            .update(updated.toMap())
            .eq('id', id)
            .timeout(const Duration(seconds: 5));
        _dirtyElements.remove(id);
      } catch (e) {
        debugPrint('BoardProviderV2.moveLocal error: $e');
        await _markUnsynced(id);
      }
    });
  }

  /// Actualiza un elemento con debounce (para moves/resizes frecuentes).
  /// Soporta elementos recién creados sin id cloud (actualiza solo local).
  Future<void> update(BoardElementV2 el) async {
    var idx = _elements.indexWhere((e) => identical(e, el));
    if (idx == -1) idx = _elements.indexWhere((e) => e.id == el.id);
    if (idx == -1) {
      idx = _elements.indexWhere((e) => e.createdAt == el.createdAt);
    }
    if (idx == -1) return;

    if (_elements[idx].isLocked) return;

    _elements[idx] = el.copyWith(updatedAt: DateTime.now());
    notifyListeners();

    // Guardar local inmediatamente (BUG 1+9: marcar synced=0 si offline)
    await _saveToLocal(_elements[idx], syncedFlag: _isOnline ? null : 0);

    final id = _elements[idx].id;
    if (id == null) return;
    _dirtyElements.add(id);

    // Debounce para cloud (300ms)
    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 300), () async {
      _debounceTimers.remove(id);
      if (!_isOnline) {
        await _markUnsynced(id);
        return;
      }
      try {
        await SupabaseConfig.client
            .from('board_elements_v2')
            .update(el.toMap())
            .eq('id', id)
            .timeout(const Duration(seconds: 5));
        // Cloud write exitoso: marcar synced=1
        final db = await DatabaseHelper().database;
        await db.update(
          'board_elements_v2',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
        _dirtyElements.remove(id);
      } catch (e) {
        debugPrint('BoardProviderV2.update error: $e');
        await _markUnsynced(id);
      }
    });
  }

  /// Reacciona a un elemento vía RPC de merge atómico (evita el race de
  /// "último write gana" que ocurría al enviar el `data` completo en cada
  /// update). Optimista en memoria + reconciliación con la respuesta
  /// autoritativa que devuelve el servidor.
  Future<void> react(
    BoardElementV2 el,
    Map<String, dynamic> newData,
    String key,
  ) async {
    var idx = _elements.indexWhere((e) => identical(e, el));
    if (idx == -1) idx = _elements.indexWhere((e) => e.id == el.id);
    if (idx == -1) return;
    if (_elements[idx].isLocked) return;
    final prev = _elements[idx];
    final updated = prev.copyWith(data: newData, updatedAt: DateTime.now());
    _elements[idx] = updated;
    notifyListeners();
    await _saveToLocal(updated, syncedFlag: _isOnline ? 1 : 0);

    final id = updated.id;
    if (id == null || !_isOnline) return;

    try {
      final res = await SupabaseConfig.client
          .rpc('toggle_reaction', params: {
            'target_table': 'board_elements_v2',
            'target_col': 'data',
            'row_id': id,
            'reaction_key': key,
            'user_id': AppState.myId ?? '',
          })
          .timeout(const Duration(seconds: 5));
      final authoritative = _reactionsOf({'reactions': res});
      final mi = _elements.indexWhere((e) => e.id == id);
      if (mi >= 0) {
        final live = _elements[mi];
        final mergedData = Map<String, dynamic>.from(live.data)
          ..['reactions'] = {
            for (final entry in authoritative.entries)
              entry.key: List<String>.from(entry.value),
          };
        _elements[mi] = live.copyWith(data: mergedData);
        await _saveToLocal(_elements[mi], syncedFlag: 1);
      }
      notifyListeners();
    } catch (e) {
      _elements[idx] = prev;
      _error = 'No se pudo guardar la reacción';
      debugPrint('BoardProviderV2.react error: $e');
      await _markUnsynced(id);
      notifyListeners();
    }
  }

  /// Borra un elemento.
  Future<void> delete(int id) async {
    final el = _elements.firstWhere((e) => e.id == id, orElse: () => throw Exception('Not found'));

    // BUG 3: Limpiar conectores que referencian este elemento (cascade).
    final orphanConnectors = _elements
        .where((e) =>
            e.type == BoardElementType.connector &&
            e.id != null &&
            e.id != id)
        .where((e) {
      final cd = ConnectorData.fromMap(e.data);
      return cd.fromId == id || cd.toId == id;
    }).toList();
    for (final c in orphanConnectors) {
      if (c.id != null) {
        _elements.removeWhere((e) => e.id == c.id);
        await _deleteLocal(c.id!);
        if (_isOnline) {
          try {
            await SupabaseConfig.client
                .from('board_elements_v2')
                .delete()
                .eq('id', c.id!)
                .timeout(const Duration(seconds: 5));
          } catch (e) {
            debugPrint('BoardProviderV2.delete connector cascade error: $e');
          }
        }
      }
    }

    // BUG 7: Limpiar comentarios que reply a este elemento (cascade).
    final orphanReplies = _findCommentsRepliedTo(id);
    for (final replyId in orphanReplies) {
      if (replyId == id) continue;
      final replyEl = _elements.firstWhere((e) => e.id == replyId, orElse: () => throw Exception('Not found'));
      _elements.removeWhere((e) => e.id == replyId);
      await _deleteLocal(replyId);
      if (_isOnline) {
        try {
          await SupabaseConfig.client
              .from('board_elements_v2')
              .delete()
              .eq('id', replyId)
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('BoardProviderV2.delete reply cascade error: $e');
        }
      }
    }

    _elements.removeWhere((e) => e.id == id);
    notifyListeners();

    // Cancelar cualquier debounce pendiente de move/update de este elemento
    // (evita que un write a la nube llegue DESPUÉS del borrado y recree la fila).
    _debounceTimers[id]?.cancel();
    _debounceTimers.remove(id);
    _dirtyElements.remove(id);

    // Borrar local
    await _deleteLocal(id);

    // Agregar actividad
    _addActivity(
      action: 'deleted',
      elementId: id,
      elementType: el.type,
      description: '${AppState.identity ?? 'Alguien'} eliminó ${_typeName(el.type)}',
    );

    // No borrar elementos bloqueados.
    if (_elements.firstWhere((e) => e.id == id, orElse: () => throw Exception('Not found')).isLocked) return;

    // Borrar cloud (solo si alguna vez se sincronizó; un elemento puramente
    // local/optimista no tiene id cloud que borrar).
    final cloudId = el.cloudId;
    if (_isOnline && cloudId != null) {
      try {
        await SupabaseConfig.client
            .from('board_elements_v2')
            .delete()
            .eq('id', cloudId)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('BoardProviderV2.delete error: $e');
      }
    }
  }

  /// Marca un elemento como "visto" (quita badge NUEVO).
  Future<void> markAsSeen(int id) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _elements[idx] = _elements[idx].copyWith(isNew: false);
    notifyListeners();

    // Actualizar local
    await _saveToLocal(_elements[idx]);

    // Actualizar cloud
    if (_isOnline) {
      try {
        await SupabaseConfig.client
            .from('board_elements_v2')
            .update({'is_new': false, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', id)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('BoardProviderV2.markAsSeen error: $e');
      }
    }
  }

  /// Archiva o desarchiva un elemento.
  Future<void> toggleArchive(int id) async {
    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    _elements[idx] = _elements[idx].copyWith(
      isArchived: !_elements[idx].isArchived,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    await _saveToLocal(_elements[idx]);

    if (_isOnline) {
      try {
        await SupabaseConfig.client
            .from('board_elements_v2')
            .update({
              'is_archived': _elements[idx].isArchived,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
      } catch (e) {
        debugPrint('BoardProviderV2.toggleArchive error: $e');
      }
    }
  }

  // --- Tags ---

  /// Carga TODOS los elementos (sin filtro de board_id) para búsqueda cross-board.
  Future<List<BoardElementV2>> loadSearchPool() async {
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query(
        'board_elements_v2',
        where: 'is_archived = 0',
        orderBy: 'created_at DESC',
      );
      return rows.map((r) {
        final map = Map<String, dynamic>.from(r);
        map['is_bold'] = (map['is_bold'] as int?) == 1;
        map['is_italic'] = (map['is_italic'] as int?) == 1;
        map['is_underline'] = (map['is_underline'] as int?) == 1;
        map['is_collapsed'] = (map['is_collapsed'] as int?) == 1;
        map['is_locked'] = (map['is_locked'] as int?) == 1;
        map['is_archived'] = (map['is_archived'] as int?) == 1;
        map['is_new'] = (map['is_new'] as int?) == 1;
        if (map['tags'] is String) {
          try { map['tags'] = jsonDecode(map['tags'] as String); } catch (_) {}
        }
        if (map['data'] is String) {
          try { map['data'] = jsonDecode(map['data'] as String); } catch (_) {}
        }
        return BoardElementV2.fromMap(map);
      }).toList();
    } catch (e) {
      debugPrint('BoardProviderV2.loadSearchPool error: $e');
      return [];
    }
  }

  // --- Actividad ---

  Future<void> _addActivity({
    required String action,
    int? elementId,
    required String elementType,
    required String description,
  }) async {
    final activity = BoardActivity(
      userId: AppState.myId ?? '',
      action: action,
      elementId: elementId,
      elementType: elementType,
      description: description,
      timestamp: DateTime.now(),
    );
    _activity.insert(0, activity);

    // Guardar local (max 100 registros)
    try {
      final db = await DatabaseHelper().database;
      await db.insert('board_activity', activity.toMap());
      final count = await db.query('board_activity');
      if (count.length > 100) {
        await db.rawDelete(
          'DELETE FROM board_activity WHERE id NOT IN (SELECT id FROM board_activity ORDER BY timestamp DESC LIMIT 100)',
        );
      }
    } catch (e) {
      debugPrint('BoardProviderV2._addActivity error: $e');
    }
  }

  Future<void> loadActivity() async {
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query(
        'board_activity',
        orderBy: 'timestamp DESC',
        limit: 50,
      );
      _activity = rows.map((r) => BoardActivity.fromMap(r)).toList();
    } catch (e) {
      debugPrint('BoardProviderV2.loadActivity error: $e');
    }
  }

  // --- SQLite helpers ---

  Future<void> _saveToLocal(BoardElementV2 el, {int? syncedFlag}) async {
    try {
      final db = await DatabaseHelper().database;
      final map = el.toMap();
      // Convert bools to ints for SQLite
      map['is_bold'] = el.isBold ? 1 : 0;
      map['is_italic'] = el.isItalic ? 1 : 0;
      map['is_underline'] = el.isUnderline ? 1 : 0;
      map['is_collapsed'] = el.isCollapsed ? 1 : 0;
      map['is_locked'] = el.isLocked ? 1 : 0;
      map['is_new'] = el.isNew ? 1 : 0;
      map['is_archived'] = el.isArchived ? 1 : 0;
      map['tags'] = jsonEncode(el.tags);
      map['data'] = jsonEncode(el.data);
      map['cloud_id'] = el.cloudId;
      if (syncedFlag != null) map['synced'] = syncedFlag;

      // Un elemento con id cloud se matchea por cloud_id (nunca por el rowid
      // local, que NO coincide con el id cloud).
      if (el.cloudId != null) {
        final updated = await db.update(
          'board_elements_v2',
          Map<String, dynamic>.from(map)..['id'] = el.cloudId,
          where: 'cloud_id = ?',
          whereArgs: [el.cloudId],
        );
        if (updated == 0) {
          await db.insert('board_elements_v2', map);
        }
      } else {
        // Sin id cloud todavía: matchear la fila local por created_at para no
        // acumular filas duplicadas en cada save.
        final updated = await db.update(
          'board_elements_v2',
          map,
          where: 'created_at = ?',
          whereArgs: [el.createdAt.toIso8601String()],
        );
        if (updated == 0) {
          await db.insert('board_elements_v2', map);
        }
      }
    } catch (e) {
      debugPrint('BoardProviderV2._saveToLocal error: $e');
    }
  }

  /// Marca un elemento como no sincronizado en SQLite (synced=0).
  Future<void> _markUnsynced(int id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.update(
        'board_elements_v2',
        {'synced': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
} catch (e) {
      debugPrint('BoardProviderV2._deleteLocal error: $e');
    }
  }

  /// Encuentra IDs de comentarios que reply (tienen replyToId = id).
  /// Busca recursivamente: si A responde a B, y borramos B, también borramos A.
  List<int> _findCommentsRepliedTo(int id) {
    final result = <int>[];
    // Buscar en todos los elementos del tablero
    for (final e in _elements) {
      if (e.type != BoardElementType.note) continue; // Solo notas tienen comentarios
      final comments = _commentsOf(e.data);
      for (final c in comments) {
        if (c['replyToId']?.toString() == id.toString()) {
          result.add(e.id!);
          // Agregar recursivamente los comentarios que reply a este comentario
          final repliedIds = _findCommentsRepliedToHelper(e.id!, id);
          result.addAll(repliedIds);
        }
      }
    }
    return result;
  }

  /// Helper recursivo: encuentra comentarios que reply a `parentId` dentro del elemento `el`
  List<int> _findCommentsRepliedToHelper(int elId, int parentId) {
    final result = <int>[];
    final el = _elements.firstWhere((e) => e.id == elId, orElse: () => throw Exception('Not found'));
    final comments = _commentsOf(el.data);
    for (final c in comments) {
      if (c['replyToId']?.toString() == parentId.toString() && c['id']?.toString() != parentId.toString()) {
        result.add(c['id'] as int? ?? -1).where((id) => id != -1).toList();
        // Recursivo: este comentario también puede tener respuestas propias
        final repliedIds = _findCommentsRepliedToHelper(c['id'] as int, parentId);
        result.addAll(repliedIds);
      }
    }
    return result.where((id) => id != -1).toList();
  }

  /// Extrae las reacciones del campo `data` de un elemento.
  Map<String, List<String>> _reactionsOf(Map<String, dynamic> data) {
    final raw = data['reactions'];
    if (raw is! Map) return {};
    final out = <String, List<String>>{};
    for (final e in raw.entries) {
      final v = e.value;
      out[e.key] =
          v is List ? List<String>.from(v.map((x) => x.toString())) : <String>[];
    }
    return out;
  }

  /// Extrae los comentarios del campo `data` de un elemento (mismo formato que BoardSocialData.commentsOf).
  List<Map<String, dynamic>> _commentsOf(Map<String, dynamic> data) {
    final raw = data['comments'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> _deleteLocal(int id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete(
        'board_elements_v2',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('BoardProviderV2._deleteLocal error: $e');
    }
  }

  Future<bool> _checkConnection() async {
    try {
      await SupabaseConfig.client
          .from('board_elements_v2')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _channel?.unsubscribe();
    super.dispose();
  }
}
