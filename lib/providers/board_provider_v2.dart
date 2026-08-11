import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../database/database_helper.dart';
import '../models/board_element_v2.dart';
import '../app_state.dart';

class BoardProviderV2 extends ChangeNotifier {
  List<BoardElementV2> _elements = [];
  List<BoardActivity> _activity = [];
  List<Map<String, dynamic>> _savedTags = [];
  bool _loading = false;
  String? _error;
  int _boardId = 1;
  RealtimeChannel? _channel;
  final Map<int, Timer> _debounceTimers = {};
  bool _isOnline = true;

  // Getters
  List<BoardElementV2> get elements => _elements.where((e) => !e.isArchived).toList();
  List<BoardElementV2> get allElements => _elements;
  List<BoardElementV2> get archivedElements => _elements.where((e) => e.isArchived).toList();
  List<BoardActivity> get activity => _activity;
  List<Map<String, dynamic>> get savedTags => _savedTags;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => !_loading && _elements.isEmpty;
  int get boardId => _boardId;
  bool get isOnline => _isOnline;

  void setBoard(int id) {
    if (id == _boardId) return;
    _boardId = id;
    load();
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
    await _loadTags();
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
            return BoardElementV2.fromMap(map);
          })
          .toList();
    } catch (e) {
      debugPrint('BoardProviderV2._loadFromLocal error: $e');
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final res = await SupabaseConfig.client
          .from('board_elements_v2')
          .select()
          .eq('board_id', _boardId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      final cloudElements = (res as List)
          .map((e) => BoardElementV2.fromMap(e as Map<String, dynamic>))
          .toList();

      // Merge: cloud gana sobre local (último cambio)
      for (final cloudEl in cloudElements) {
        final localIdx = _elements.indexWhere((e) => e.id == cloudEl.id);
        if (localIdx >= 0) {
          // Cloud es más reciente → reemplazar
          if (cloudEl.updatedAt.isAfter(_elements[localIdx].updatedAt)) {
            _elements[localIdx] = cloudEl;
          }
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
        final localId = el.id;
        final res = await SupabaseConfig.client
            .from('board_elements_v2')
            .insert(el.copyWith(clearId: true).toMap())
            .select()
            .single()
            .timeout(const Duration(seconds: 10));
        final cloudId = res['id'] as int;

        // Actualizar con id cloud (memoria + SQLite). El id local de SQLite
        // NO es el id cloud: hay que reconciliar la fila local con el cloud.
        if (localId != null) {
          final idx = _elements.indexWhere((e) => e.id == localId);
          if (idx >= 0) {
            _elements[idx] = _elements[idx].copyWith(id: cloudId);
          }
          await db.delete('board_elements_v2', where: 'id = ?', whereArgs: [localId]);
        } else {
          final idx = _elements.indexWhere((e) => e.createdAt == el.createdAt);
          if (idx >= 0) {
            _elements[idx] = _elements[idx].copyWith(id: cloudId);
          }
        }

        // Guardar fila local reconciliada con id cloud
        await _saveToLocal(_elements.firstWhere(
          (e) => e.id == cloudId,
          orElse: () => el.copyWith(id: cloudId),
        ));
        await db.update(
          'board_elements_v2',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [cloudId],
        );
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
              // No pisar cambios locales pendientes
              if (el.updatedAt.isAfter(_elements[idx].updatedAt)) {
                _elements[idx] = el;
                _saveToLocal(el);
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

        final cloudEl = BoardElementV2.fromMap(res);
        final idx = _elements.indexWhere((e) => e.createdAt == el.createdAt);
        if (idx >= 0) {
          _elements[idx] = cloudEl.copyWith(
            x: _elements[idx].x,
            y: _elements[idx].y,
            title: _elements[idx].title,
            content: _elements[idx].content,
            data: _elements[idx].data,
          );
          // Marcar synced en SQLite
          final db = await DatabaseHelper().database;
          await db.update(
            'board_elements_v2',
            {'synced': 1, 'id': cloudEl.id},
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

    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 300), () {
      _debounceTimers.remove(id);
      if (_isOnline) {
        try {
          SupabaseConfig.client
              .from('board_elements_v2')
              .update(updated.toMap())
              .eq('id', id)
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('BoardProviderV2.moveLocal error: $e');
        }
      }
    });
  }

  /// Actualiza un elemento con debounce (para moves/resizes frecuentes).
  Future<void> update(BoardElementV2 el) async {
    final id = el.id;
    if (id == null) return;

    final idx = _elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    _elements[idx] = el.copyWith(updatedAt: DateTime.now());
    notifyListeners();

    // Guardar local inmediatamente
    await _saveToLocal(el);

    // Debounce para cloud (300ms)
    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 300), () async {
      _debounceTimers.remove(id);
      if (_isOnline) {
        try {
          await SupabaseConfig.client
              .from('board_elements_v2')
              .update(el.toMap())
              .eq('id', id)
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('BoardProviderV2.update error: $e');
        }
      }
    });
  }

  /// Borra un elemento.
  Future<void> delete(int id) async {
    final el = _elements.firstWhere((e) => e.id == id, orElse: () => throw Exception('Not found'));
    _elements.removeWhere((e) => e.id == id);
    notifyListeners();

    // Borrar local
    await _deleteLocal(id);

    // Agregar actividad
    _addActivity(
      action: 'deleted',
      elementId: id,
      elementType: el.type,
      description: '${AppState.identity ?? 'Alguien'} eliminó ${_typeName(el.type)}',
    );

    // Borrar cloud
    if (_isOnline) {
      try {
        await SupabaseConfig.client
            .from('board_elements_v2')
            .delete()
            .eq('id', id)
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

  Future<void> _loadTags() async {
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query('board_tags', orderBy: 'created_at ASC');
      _savedTags = rows.map((r) => {'name': r['name'], 'color': r['color']}).toList();
    } catch (e) {
      debugPrint('BoardProviderV2._loadTags error: $e');
    }
  }

  Future<void> saveTag(String name, String color) async {
    try {
      final db = await DatabaseHelper().database;
      await db.insert(
        'board_tags',
        {'name': name, 'color': color, 'created_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await _loadTags();
    } catch (e) {
      debugPrint('BoardProviderV2.saveTag error: $e');
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

  Future<void> _saveToLocal(BoardElementV2 el) async {
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

      if (el.id != null) {
        await db.update(
          'board_elements_v2',
          map,
          where: 'id = ?',
          whereArgs: [el.id],
        );
      } else {
        await db.insert('board_elements_v2', map);
      }
    } catch (e) {
      debugPrint('BoardProviderV2._saveToLocal error: $e');
    }
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
