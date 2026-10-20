import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/board_element.dart';
import 'helpers/board_chalk_helper.dart';
import 'helpers/board_chunks_helper.dart';
import 'helpers/board_local_storage.dart';
import 'helpers/board_realtime_handler.dart';
import 'helpers/board_sync_service.dart';

/// Provider central para el Pizarrón Infinito colaborativo de F.U.R.I.
/// Soporta persistencia local SQLite (offline-first), sync en tiempo real
/// con Supabase, carga en chunks (2x viewport) y debounced sync para
/// movimientos y escalado a 60/120 FPS.
class BoardDataProvider extends ChangeNotifier {
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
      await BoardSyncService.pushUnsyncedToCloud();
      await BoardSyncService.pullFromCloud();
    } catch (e) {
      developer.log('BoardDataProvider.load sync error: $e');
    }
    _elements = await BoardLocalStorage.reloadFromLocal();
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  List<BoardElement> getElementsByBoard(int boardId) =>
      BoardChunksHelper.getElementsByBoard(_elements, boardId);

  List<BoardElement> getInteractiveElementsInChunk(
    int boardId,
    Rect activeChunkWorldRect, {
    int? alwaysIncludeId,
  }) =>
      BoardChunksHelper.getInteractiveElementsInChunk(_elements, boardId,
          activeChunkWorldRect, alwaysIncludeId: alwaysIncludeId);

  List<BoardElement> getChalkStrokesInChunk(
    int boardId,
    Rect activeChunkWorldRect,
  ) =>
      BoardChunksHelper.getChalkStrokesInChunk(
          _elements, boardId, activeChunkWorldRect);

  List<BoardElement> getAllChalkStrokes(int boardId) =>
      BoardChunksHelper.getAllChalkStrokes(_elements, boardId);

  String getBoardBackgroundColor(int boardId) =>
      BoardChunksHelper.getBoardBackgroundColor(_elements, boardId);

  Future<void> setBoardBackgroundColor(int boardId, String hexColor) async {
    final i = _elements.indexWhere(
        (e) => e.boardId == boardId && e.type == 'board_config');
    if (i != -1) {
      await updateElement(_elements[i].copyWith(color: hexColor));
    } else {
      await addElement(
        boardId: boardId,
        type: 'board_config',
        title: 'board_config',
        color: hexColor,
      );
    }
  }

  Future<BoardElement?> addChalkStroke({
    int boardId = 1,
    required List<Offset> points,
    required String colorHex,
    double strokeWidth = 6.0,
  }) async {
    final el = BoardChalkHelper.buildChalkStrokeElement(
      boardId: boardId,
      points: points,
      colorHex: colorHex,
      strokeWidth: strokeWidth,
    );
    if (el == null) return null;
    return addElement(
      boardId: el.boardId,
      type: el.type,
      title: el.title,
      color: el.color,
      x: el.x,
      y: el.y,
      width: el.width,
      height: el.height,
      data: el.data,
    );
  }

  Future<void> undoLastChalkStroke(int boardId) async {
    final lastId = BoardChalkHelper.getLastChalkStrokeId(_elements, boardId);
    if (lastId != null) await deleteElement(lastId);
  }

  Future<void> clearChalkStrokes(int boardId) async {
    for (final id in BoardChalkHelper.getAllChalkStrokeIds(_elements, boardId)) {
      await deleteElement(id);
    }
  }

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
    final author = AppState.identity?.isNotEmpty == true ? AppState.identity! : 'Facu';
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

    final localId = await BoardLocalStorage.insertElement(el);
    final created = el.copyWith(id: localId);
    _elements.add(created);
    notifyListeners();

    _syncNewElement(created);
    return created;
  }

  Future<BoardElement?> duplicateElement(int localId,
      {double offset = 30.0}) async {
    final idx = _elements.indexWhere((e) => e.id == localId);
    if (idx == -1) return null;
    final o = _elements[idx];
    return addElement(
      boardId: o.boardId,
      type: o.type,
      title: o.title.isEmpty ? '' : '${o.title} (Copia)',
      content: o.content,
      color: o.color,
      x: o.x + offset,
      y: o.y + offset,
      width: o.width,
      height: o.height,
      data: Map<String, dynamic>.from(o.data),
    );
  }

  Future<BoardElement> addConnection({
    int boardId = 1,
    required int fromElementId,
    required int toElementId,
    String color = '#9D00FF',
    String label = '',
  }) =>
      addElement(
        boardId: boardId,
        type: 'connection',
        title: label,
        color: color,
        width: 0,
        height: 0,
        data: {'fromId': fromElementId, 'toId': toElementId},
      );

  Future<void> _syncNewElement(BoardElement el) async {
    try {
      final cloudId = await BoardSyncService.insertCloud(el);
      if (cloudId != null && el.id != null) {
        await BoardLocalStorage.markSynced(el.id!, cloudId);
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

  void updatePositionLocal(int localId, double newX, double newY) =>
      updateGeometryLocal(localId, x: newX, y: newY);

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
    await BoardSyncService.persistGeometry(_elements[idx]);
  }

  Future<void> updateElement(BoardElement updated) async {
    if (updated.id == null) return;
    final now = DateTime.now().toIso8601String();
    final withTime = updated.copyWith(updatedAt: now);

    final idx = _elements.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _elements[idx] = withTime;
      notifyListeners();
    }
    await BoardSyncService.persistUpdate(withTime);
  }

  Future<void> deleteElement(int localId) async {
    final idx = _elements.indexWhere((e) => e.id == localId);
    if (idx == -1) return;
    final el = _elements.removeAt(idx);
    notifyListeners();
    await BoardSyncService.persistDelete(el);
  }

  void _subscribeRealtime() {
    if (_realtimeUp) return;
    try {
      _channel = BoardSyncService.subscribeRealtime((p) {
        BoardRealtimeHandler.handlePayload(
            payload: p, elements: _elements, notify: notifyListeners);
      });
      _realtimeUp = true;
    } catch (e) {
      developer.log('BoardDataProvider realtime subscription error: $e');
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
