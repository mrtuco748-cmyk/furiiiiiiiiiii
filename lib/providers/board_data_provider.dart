import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../database/database_helper.dart';
import '../models/board_element.dart';
import '../supabase_config.dart';

/// Provider central para el Pizarrón Infinito colaborativo de F.U.R.I.
/// Soporta persistencia local SQLite (offline-first), sync en tiempo real
/// con Supabase, carga en chunks (2x viewport) y debounced sync para
/// movimientos y escalado a 60/120 FPS.
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
              'created_at':
                  n['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              'updated_at':
                  n['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
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
    // Pizarrón infinito: sin recortes ni límites artificiales de coordenadas
    _elements = result.map((m) {
      final map = Map<String, dynamic>.from(m);
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
        await db.insert(_tableName, c.toMap(includeId: false));
      } else {
        final localUp = DateTime.tryParse(local.updatedAt ?? '') ?? DateTime(1970);
        final cloudUp = DateTime.tryParse(c.updatedAt ?? '') ?? DateTime(1970);
        if (cloudUp.isAfter(localUp) && local.synced == 1) {
          await db.update(
            _tableName,
            c.toMap(includeId: false),
            where: 'id = ?',
            whereArgs: [local.id],
          );
        }
      }
    }

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

  /// Obtiene los elementos correspondientes a un tablero específico
  List<BoardElement> getElementsByBoard(int boardId) {
    return _elements
        .where((e) =>
            e.boardId == boardId &&
            e.type != 'board_config' &&
            e.type != 'chalk_stroke')
        .toList();
  }

  /// Filtra los elementos interactivos (notas y listas de tareas) que caen dentro
  /// del chunk activo (2x el tamaño de lo mostrado en pantalla).
  /// Si un elemento está siendo editado o arrastrado (`alwaysIncludeId`), siempre se incluye.
  List<BoardElement> getInteractiveElementsInChunk(
    int boardId,
    Rect activeChunkWorldRect, {
    int? alwaysIncludeId,
  }) {
    final result = <BoardElement>[];
    for (final e in _elements) {
      if (e.boardId != boardId) continue;
      if (e.type == 'board_config' ||
          e.type == 'chalk_stroke' ||
          e.type == 'connection') {
        continue;
      }
      if (alwaysIncludeId != null && e.id == alwaysIncludeId) {
        result.add(e);
        continue;
      }
      final elRect = Rect.fromLTWH(e.x, e.y, e.width, e.height);
      if (activeChunkWorldRect.overlaps(elRect)) {
        result.add(e);
      }
    }
    return result;
  }

  /// Obtiene los trazos de tiza en el fondo del pizarrón que intersectan el chunk activo (2x viewport).
  List<BoardElement> getChalkStrokesInChunk(
    int boardId,
    Rect activeChunkWorldRect,
  ) {
    final result = <BoardElement>[];
    for (final e in _elements) {
      if (e.boardId != boardId || e.type != 'chalk_stroke') continue;
      final elRect = Rect.fromLTWH(
        e.x - 20,
        e.y - 20,
        math.max(40.0, e.width + 40),
        math.max(40.0, e.height + 40),
      );
      if (activeChunkWorldRect.overlaps(elRect)) {
        result.add(e);
      }
    }
    return result;
  }

  /// Obtiene todos los trazos de tiza del tablero.
  List<BoardElement> getAllChalkStrokes(int boardId) {
    return _elements
        .where((e) => e.boardId == boardId && e.type == 'chalk_stroke')
        .toList();
  }

  /// Obtiene el color sólido de fondo configurado para el pizarrón (por defecto #141820).
  String getBoardBackgroundColor(int boardId) {
    for (final e in _elements) {
      if (e.boardId == boardId && e.type == 'board_config') {
        if (e.color.isNotEmpty) return e.color;
      }
    }
    return '#141820';
  }

  /// Actualiza el color sólido del fondo del pizarrón y lo sincroniza.
  Future<void> setBoardBackgroundColor(int boardId, String hexColor) async {
    final existingIdx = _elements.indexWhere(
      (e) => e.boardId == boardId && e.type == 'board_config',
    );
    if (existingIdx != -1) {
      final updated = _elements[existingIdx].copyWith(color: hexColor);
      await updateElement(updated);
    } else {
      await addElement(
        boardId: boardId,
        type: 'board_config',
        title: 'board_config',
        color: hexColor,
        x: 0,
        y: 0,
        width: 0,
        height: 0,
      );
    }
  }

  /// Añade un trazo de tiza al fondo del pizarrón con su caja delimitadora en coordenadas del mundo.
  Future<BoardElement?> addChalkStroke({
    int boardId = 1,
    required List<Offset> points,
    required String colorHex,
    double strokeWidth = 6.0,
  }) async {
    if (points.isEmpty) return null;
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    final serializedPoints = <List<double>>[];
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
      serializedPoints.add([
        double.parse(p.dx.toStringAsFixed(1)),
        double.parse(p.dy.toStringAsFixed(1)),
      ]);
    }

    return addElement(
      boardId: boardId,
      type: 'chalk_stroke',
      title: 'chalk',
      color: colorHex,
      x: minX,
      y: minY,
      width: math.max(1.0, maxX - minX),
      height: math.max(1.0, maxY - minY),
      data: {
        'points': serializedPoints,
        'strokeWidth': strokeWidth,
      },
    );
  }

  /// Deshace el último trazo de tiza del tablero.
  Future<void> undoLastChalkStroke(int boardId) async {
    final strokes = getAllChalkStrokes(boardId);
    if (strokes.isEmpty) return;
    final last = strokes.last;
    if (last.id != null) {
      await deleteElement(last.id!);
    }
  }

  /// Borra todos los trazos de tiza del tablero.
  Future<void> clearChalkStrokes(int boardId) async {
    final strokes = getAllChalkStrokes(boardId);
    for (final s in strokes) {
      if (s.id != null) {
        await deleteElement(s.id!);
      }
    }
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
    final author =
        (rawIdentity != null && rawIdentity.isNotEmpty) ? rawIdentity : 'Facu';
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

  /// Duplica un elemento con un desplazamiento de grilla
  Future<BoardElement?> duplicateElement(int localId,
      {double offset = 30.0}) async {
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
      _persistGeometry(localId);
    });
  }

  /// Actualización suave de posición y tamaño (llamado al estirar desde la esquina
  /// o al hacer pinch con dos dedos sobre una nota a 60/120 FPS).
  void updateGeometryLocal(
    int localId, {
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    final idx = _elements.indexWhere((e) => e.id == localId);
    if (idx == -1) return;

    final cur = _elements[idx];
    _elements[idx] = cur.copyWith(
      x: x ?? cur.x,
      y: y ?? cur.y,
      width: width ?? cur.width,
      height: height ?? cur.height,
    );
    notifyListeners();

    _moveDebouncers[localId]?.cancel();
    _moveDebouncers[localId] = Timer(const Duration(milliseconds: 300), () {
      _persistGeometry(localId);
    });
  }

  Future<void> _persistGeometry(int localId) async {
    final idx = _elements.indexWhere((e) => e.id == localId);
    if (idx == -1) return;
    final el = _elements[idx];
    final now = DateTime.now().toIso8601String();

    try {
      final db = await DatabaseHelper().database;
      await db.update(
        _tableName,
        {
          'x': el.x,
          'y': el.y,
          'width': el.width,
          'height': el.height,
          'updated_at': now,
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [localId],
      );

      if (el.cloudId != null) {
        await SupabaseConfig.client.from(_tableName).update({
          'x': el.x,
          'y': el.y,
          'width': el.width,
          'height': el.height,
          'updated_at': now,
        }).eq('id', el.cloudId!);

        await db.update(
          _tableName,
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [localId],
        );
      }
    } catch (e) {
      developer.log('BoardDataProvider _persistGeometry error: $e');
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
        withTime.toMap(includeId: false),
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
        await SupabaseConfig.client
            .from(_tableName)
            .delete()
            .eq('id', el.cloudId!);
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
        _elements.add(incoming);
        notifyListeners();
        DatabaseHelper().database.then((db) async {
          try {
            final newId =
                await db.insert(_tableName, incoming.toMap(includeId: false));
            final insertedIdx =
                _elements.indexWhere((e) => e.cloudId == incoming.cloudId);
            if (insertedIdx != -1) {
              _elements[insertedIdx] = incoming.copyWith(id: newId);
            }
          } catch (e) {
            developer.log('BoardDataProvider realtime insert db error: $e');
          }
        }).catchError((e) {
          developer.log('BoardDataProvider realtime insert error: $e');
        });
      } else {
        final current = _elements[idx];
        final currentUp =
            DateTime.tryParse(current.updatedAt ?? '') ?? DateTime(1970);
        final incomingUp =
            DateTime.tryParse(incoming.updatedAt ?? '') ?? DateTime(1970);

        if (incomingUp.isAfter(currentUp) ||
            incomingUp.isAtSameMomentAs(currentUp)) {
          _elements[idx] = incoming.copyWith(id: current.id);
          notifyListeners();
          DatabaseHelper().database.then((db) async {
            try {
              await db.update(
                _tableName,
                incoming.toMap(includeId: false),
                where: 'id = ?',
                whereArgs: [current.id],
              );
            } catch (e) {
              developer.log('BoardDataProvider realtime update db error: $e');
            }
          }).catchError((e) {
            developer.log('BoardDataProvider realtime update error: $e');
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
