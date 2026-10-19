import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../database/database_helper.dart';
import '../models/board_element.dart';
import '../supabase_config.dart';

/// Provider central para el Pizarrón Infinito colaborativo de F.U.R.I.
/// Soporta persistencia local SQLite (offline-first), sync en tiempo real
/// con Supabase y debounced sync para movimientos de arrastre a 60/120 FPS.
class BoardDataProvider extends ChangeNotifier {
  static const _tableName = 'board_elements';

  List<BoardElement> _elements = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  bool _realtimeUp = false;

  final Map<int, Timer> _moveDebouncers = {};

  List<BoardElement> get elements => _elements;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => !_loading && _elements.isEmpty;
  bool get isRealtimeConnected => _realtimeUp;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _pushUnsyncedToCloud();
      await _pullFromCloud();
    } catch (e) {
      developer.log('BoardDataProvider.load sync error: $e');
    }
    await _reloadFromLocal();
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  Future<void> _reloadFromLocal() async {
    final db = await DatabaseHelper().database;
    var result = await db.query(_tableName, orderBy: 'id ASC');
    if (result.isEmpty) {
      try {
        final legacy = await db.query('notes');
        if (legacy.isNotEmpty) {
          double curX = 100.0;
          double curY = 100.0;
          for (final n in legacy) {
            final title = n['title']?.toString() ?? 'Nota';
            final content = n['content']?.toString() ?? '';
            final color = n['color']?.toString() ?? '#9D00FF';
            await db.insert(_tableName, {
              'board_id': 1,
              'user_id': n['user_id']?.toString() ?? AppState.identity,
              'type': 'note',
              'title': title,
              'content': content,
              'color': color,
              'x': curX,
              'y': curY,
              'width': 220.0,
              'height': 160.0,
              'data': '{}',
              'synced': 0,
              'created_at': n['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              'updated_at': n['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
            });
            curX += 240.0;
            if (curX > 800) {
              curX = 100.0;
              curY += 180.0;
            }
          }
          result = await db.query(_tableName, orderBy: 'id ASC');
        }
      } catch (e) {
        developer.log('Error al migrar notas legacy: $e');
      }
    }
    _elements = result.map((m) {
      final map = Map<String, dynamic>.from(m);
      double x = (map['x'] as num?)?.toDouble() ?? 0.0;
      double y = (map['y'] as num?)?.toDouble() ?? 0.0;
      bool changed = false;
      if (x > 2200.0) {
        x -= 3400.0;
        if (x < 40.0) x = 120.0;
        map['x'] = x;
        changed = true;
      }
      if (y > 1500.0) {
        y -= 3400.0;
        if (y < 40.0) y = 120.0;
        map['y'] = y;
        changed = true;
      }
      if (changed && map['id'] != null) {
        db.update(_tableName, {'x': x, 'y': y}, where: 'id = ?', whereArgs: [map['id']]);
      }
      return BoardElement.fromMap(map);
    }).toList();
  }

  /// Sube filas locales pendientes a Supabase (creadas offline o modificadas sin sincronizar).
  Future<void> _pushUnsyncedToCloud() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(_tableName);
    for (final m in result) {
      final element = BoardElement.fromMap(Map<String, dynamic>.from(m));
      if (element.cloudId == null) {
        final cloudId = await _insertCloud(element);
        if (cloudId != null) {
          await db.update(
            _tableName,
            {'cloud_id': cloudId, 'synced': 1},
            where: 'id = ?',
            whereArgs: [element.id],
          );
        }
      } else if (m['synced'] == 0) {
        try {
          await SupabaseConfig.client
              .from(_tableName)
              .update(element.toSupabaseMap())
              .eq('id', element.cloudId!);
          await db.update(
            _tableName,
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [element.id],
          );
        } catch (e) {
          developer.log('BoardDataProvider re-push error: $e');
        }
      }
    }
  }

  /// Trae todos los elementos de Supabase y los mergea en SQLite local.
  Future<void> _pullFromCloud() async {
    final data = await SupabaseConfig.client
        .from(_tableName)
        .select()
        .timeout(const Duration(seconds: 10));
    final cloud = (data as List)
        .map((r) => BoardElement.fromCloudRow(Map<String, dynamic>.from(r as Map)))
        .toList();

    final db = await DatabaseHelper().database;
    final localRows = await db.query(_tableName);
    final localByCloud = <int, BoardElement>{};
    for (final m in localRows) {
      final el = BoardElement.fromMap(Map<String, dynamic>.from(m));
      if (el.cloudId != null) {
        localByCloud[el.cloudId!] = el;
      }
    }

    final cloudIds = <int>{};
    for (final c in cloud) {
      if (c.cloudId == null) continue;
      cloudIds.add(c.cloudId!);
      final local = localByCloud[c.cloudId!];
      if (local == null) {
        await db.insert(_tableName, c.toMap());
      } else {
        // Si el cloud es más reciente o el local está sincronizado, mergear
        final localUp = DateTime.tryParse(local.updatedAt ?? '') ?? DateTime(1970);
        final cloudUp = DateTime.tryParse(c.updatedAt ?? '') ?? DateTime(1970);
        if (cloudUp.isAfter(localUp) && local.synced == 1) {
          await db.update(
            _tableName,
            c.toMap(),
            where: 'id = ?',
            whereArgs: [local.id],
          );
        }
      }
    }

    // Si fue eliminado en la nube y estaba sincronizado, borrarlo local
    for (final local in localByCloud.values) {
      if (!cloudIds.contains(local.cloudId!) && local.synced == 1) {
        await db.delete(_tableName, where: 'id = ?', whereArgs: [local.id]);
      }
    }
  }

  Future<int?> _insertCloud(BoardElement el) async {
    try {
      final res = await SupabaseConfig.client
          .from(_tableName)
          .insert(el.toSupabaseMap())
          .select('id')
          .single();
      return (res['id'] as num?)?.toInt();
    } catch (e) {
      developer.log('BoardDataProvider _insertCloud error: $e');
      return null;
    }
  }

  /// Obtiene los elementos correspondientes a un tablero específico (sub-tableros anidados)
  List<BoardElement> getElementsByBoard(int boardId) {
    return _elements.where((e) => e.boardId == boardId).toList();
  }

  /// Añade un nuevo elemento al canvas
  Future<BoardElement> addElement({
    int boardId = 1,
    required String type,
    String title = '',
    String content = '',
    String color = '#FFF9C4',
    double x = 0.0,
    double y = 0.0,
    double width = 220.0,
    double height = 180.0,
    Map<String, dynamic>? data,
  }) async {
    final now = DateTime.now().toIso8601String();
    final rawIdentity = AppState.identity;
    final author = (rawIdentity != null && rawIdentity.isNotEmpty) ? rawIdentity : 'Facu';
    final el = BoardElement(
      boardId: boardId,
      userId: author,
      type: type,
      title: title,
      content: content,
      color: color,
      x: x,
      y: y,
      width: width,
      height: height,
      data: data ?? {},
      synced: 0,
      createdAt: now,
      updatedAt: now,
    );

    final db = await DatabaseHelper().database;
    final localId = await db.insert(_tableName, el.toMap());
    final created = el.copyWith(id: localId);
    _elements.add(created);
    notifyListeners();

    // Sincronizar en segundo plano
    _syncNewElement(created);
    return created;
  }

  /// Duplica un elemento con un desplazamiento de grilla (estilo Milanote)
  Future<BoardElement?> duplicateElement(int localId, {double offset = 30.0}) async {
    final idx = _elements.indexWhere((e) => e.id == localId);
    if (idx == -1) return null;
    final original = _elements[idx];
    return addElement(
      boardId: original.boardId,
      type: original.type,
      title: original.title.isEmpty ? '' : '${original.title} (Copia)',
      content: original.content,
      color: original.color,
      x: original.x + offset,
      y: original.y + offset,
      width: original.width,
      height: original.height,
      data: Map<String, dynamic>.from(original.data),
    );
  }

  /// Crea una línea conectora entre dos elementos
  Future<BoardElement> addConnection({
    int boardId = 1,
    required int fromElementId,
    required int toElementId,
    String color = '#9D00FF',
    String label = '',
  }) async {
    return addElement(
      boardId: boardId,
      type: 'connection',
      title: label,
      color: color,
      x: 0,
      y: 0,
      width: 0,
      height: 0,
      data: {
        'fromId': fromElementId,
        'toId': toElementId,
      },
    );
  }

  Future<void> _syncNewElement(BoardElement el) async {
    try {
      final cloudId = await _insertCloud(el);
      if (cloudId != null && el.id != null) {
        final db = await DatabaseHelper().database;
        await db.update(
          _tableName,
          {'cloud_id': cloudId, 'synced': 1},
          where: 'id = ?',
          whereArgs: [el.id],
        );
        final idx = _elements.indexWhere((e) => e.id == el.id);
        if (idx != -1) {
          _elements[idx] = _elements[idx].copyWith(cloudId: cloudId, synced: 1);
          notifyListeners();
        }
      }
    } catch (e) {
      developer.log('BoardDataProvider _syncNewElement error: $e');
    }
  }

  /// Actualización suave de la posición x, y (llamado durante el drag a 60/120 FPS).
  /// Modifica el estado en memoria al instante y retrasa el guardado en disco y red
  /// para evitar saturación de I/O mientras el usuario arrastra.
  void updatePositionLocal(int localId, double newX, double newY) {
    final idx = _elements.indexWhere((e) => e.id == localId);
    if (idx == -1) return;

    _elements[idx] = _elements[idx].copyWith(x: newX, y: newY);
    notifyListeners();

    _moveDebouncers[localId]?.cancel();
    _moveDebouncers[localId] = Timer(const Duration(milliseconds: 300), () {
      _persistPosition(localId, newX, newY);
    });
  }

  Future<void> _persistPosition(int localId, double x, double y) async {
    final idx = _elements.indexWhere((e) => e.id == localId);
    if (idx == -1) return;
    final el = _elements[idx];
    final now = DateTime.now().toIso8601String();

    try {
      final db = await DatabaseHelper().database;
      await db.update(
        _tableName,
        {'x': x, 'y': y, 'updated_at': now, 'synced': el.cloudId == null ? 0 : 0},
        where: 'id = ?',
        whereArgs: [localId],
      );

      if (el.cloudId != null) {
        await SupabaseConfig.client.from(_tableName).update({
          'x': x,
          'y': y,
          'updated_at': now,
        }).eq('id', el.cloudId!);

        await db.update(_tableName, {'synced': 1}, where: 'id = ?', whereArgs: [localId]);
      }
    } catch (e) {
      developer.log('BoardDataProvider _persistPosition error: $e');
    }
  }

  /// Actualiza contenido o propiedades del elemento
  Future<void> updateElement(BoardElement updated) async {
    if (updated.id == null) return;
    final now = DateTime.now().toIso8601String();
    final withTime = updated.copyWith(updatedAt: now);

    final idx = _elements.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _elements[idx] = withTime;
      notifyListeners();
    }

    try {
      final db = await DatabaseHelper().database;
      await db.update(
        _tableName,
        withTime.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );

      if (withTime.cloudId != null) {
        await SupabaseConfig.client
            .from(_tableName)
            .update(withTime.toSupabaseMap())
            .eq('id', withTime.cloudId!);
      }
    } catch (e) {
      developer.log('BoardDataProvider updateElement error: $e');
    }
  }

  /// Elimina un elemento del canvas y de la base de datos
  Future<void> deleteElement(int localId) async {
    final idx = _elements.indexWhere((e) => e.id == localId);
    if (idx == -1) return;
    final el = _elements.removeAt(idx);
    notifyListeners();

    try {
      final db = await DatabaseHelper().database;
      await db.delete(_tableName, where: 'id = ?', whereArgs: [localId]);

      if (el.cloudId != null) {
        await SupabaseConfig.client.from(_tableName).delete().eq('id', el.cloudId!);
      }
    } catch (e) {
      developer.log('BoardDataProvider deleteElement error: $e');
    }
  }

  void _subscribeRealtime() {
    if (_realtimeUp) return;
    try {
      _channel = SupabaseConfig.client
          .channel('board_elements_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _tableName,
            callback: _handleRealtimePayload,
          )
          .subscribe();
      _realtimeUp = true;
    } catch (e) {
      developer.log('BoardDataProvider realtime subscription error: $e');
    }
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord;
      final oldRecord = payload.oldRecord;

      if (payload.eventType == PostgresChangeEvent.delete) {
        final cloudId = (oldRecord['id'] as num?)?.toInt();
        if (cloudId != null) {
          _elements.removeWhere((e) => e.cloudId == cloudId);
          notifyListeners();
          DatabaseHelper().database.then((db) {
            db.delete(_tableName, where: 'cloud_id = ?', whereArgs: [cloudId]);
          });
        }
        return;
      }

      if (record.isEmpty) return;
      final incoming = BoardElement.fromCloudRow(record);
      if (incoming.cloudId == null) return;

      final idx = _elements.indexWhere((e) => e.cloudId == incoming.cloudId);
      if (idx == -1) {
        // Elemento nuevo insertado por la pareja
        _elements.add(incoming);
        notifyListeners();
        DatabaseHelper().database.then((db) {
          db.insert(_tableName, incoming.toMap());
        });
      } else {
        // Elemento existente actualizado
        final current = _elements[idx];
        final currentUp = DateTime.tryParse(current.updatedAt ?? '') ?? DateTime(1970);
        final incomingUp = DateTime.tryParse(incoming.updatedAt ?? '') ?? DateTime(1970);

        if (incomingUp.isAfter(currentUp) || incomingUp.isAtSameMomentAs(currentUp)) {
          _elements[idx] = incoming.copyWith(id: current.id);
          notifyListeners();
          DatabaseHelper().database.then((db) {
            db.update(_tableName, incoming.toMap(), where: 'id = ?', whereArgs: [current.id]);
          });
        }
      }
    } catch (e) {
      developer.log('BoardDataProvider _handleRealtimePayload error: $e');
    }
  }

  @override
  void dispose() {
    for (final timer in _moveDebouncers.values) {
      timer.cancel();
    }
    _moveDebouncers.clear();
    _channel?.unsubscribe();
    super.dispose();
  }
}
