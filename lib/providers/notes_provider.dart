import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../database/database_helper.dart';
import '../models/note.dart';
import '../supabase_config.dart';

/// Notas del pizarrón/sección "Notas". Desde 2026-09-01 se comparten con la
/// pareja: cada nota vive en SQLite local (offline-first, cache) Y en Supabase
/// (tabla `notes`), con sync bidireccional por `cloudId` + realtime. Espeja el
/// patrón de ScheduleProvider (cloudId + synced + merge por cloudId).
class NotesProvider extends ChangeNotifier {
  static const _notesTable = 'notes';
  List<Note> _notes = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  bool _realtimeUp = false;

  List<Note> get notes => _notes;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => !loading && _notes.isEmpty;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _pushUnsyncedToCloud();
      await _pullFromCloud();
    } catch (e) {
      developer.log('NotesProvider.load sync error: $e');
    }
    await _reloadFromLocal();
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  Future<void> _reloadFromLocal() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(_notesTable, orderBy: 'updated_at DESC');
    _notes = result.map((m) => Note.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  /// Sube a Supabase los cambios locales pendientes: notas nuevas (sin
  /// cloudId) y ediciones de filas "dirty" (synced = 0) por push offline.
  Future<void> _pushUnsyncedToCloud() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(_notesTable);
    for (final m in result) {
      final note = Note.fromMap(Map<String, dynamic>.from(m));
      if (note.cloudId == null) {
        final cloudId = await _insertCloud(note);
        if (cloudId != null) {
          await db.update(
              _notesTable, {'cloud_id': cloudId}, where: 'id = ?', whereArgs: [note.id]);
        }
      } else if (m['synced'] == 0) {
        try {
          await SupabaseConfig.client
              .from(_notesTable)
              .update(note.toSupabaseMap())
              .eq('id', note.cloudId!);
          await db.update(
              _notesTable, {'synced': 1}, where: 'id = ?', whereArgs: [note.id]);
        } catch (e) {
          developer.log('NotesProvider re-push ${note.id} error: $e');
        }
      }
    }
  }

  /// Trae TODAS las notas cloud y las mergea en SQLite local por cloudId.
  Future<void> _pullFromCloud() async {
    final data = await SupabaseConfig.client
        .from(_notesTable)
        .select()
        .timeout(const Duration(seconds: 10));
    final cloud = (data as List)
        .map((r) => Note.fromCloudRow(Map<String, dynamic>.from(r as Map)))
        .toList();

    final db = await DatabaseHelper().database;
    final localRows = await db.query(_notesTable);
    final localByCloud = <int, Note>{};
    final pendingDeleteIds = <int>[];
    for (final m in localRows) {
      final note = Note.fromMap(Map<String, dynamic>.from(m));
      if (note.cloudId == null) continue; // sin sync aún: no tocar
      localByCloud[note.cloudId!] = note;
    }

    final cloudIds = cloud.map((c) => c.cloudId).whereType<int>().toSet();
    for (final entry in localByCloud.entries) {
      // Borrar locales cuya fila cloud ya no existe (delete de la pareja).
      if (!cloudIds.contains(entry.key)) pendingDeleteIds.add(entry.value.id!);
    }

    Map<String, dynamic> noteLocalMap(Note c) => {
      'cloud_id': c.cloudId,
      'user_id': c.userId,
      'title': c.title,
      'content': c.content,
      'color': c.color,
      'created_at': c.createdAt,
      'updated_at': c.updatedAt,
    };

    for (final c in cloud) {
      final existing = localByCloud[c.cloudId];
      if (existing == null) {
        await db.insert(
          _notesTable,
          noteLocalMap(c),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } else {
        // El cloud es autoritativo; conservar updated_at más nuevo.
        final cloudTs = DateTime.tryParse(c.updatedAt ?? '');
        final localTs = DateTime.tryParse(existing.updatedAt ?? '');
        if (cloudTs != null && (localTs == null || cloudTs.isAfter(localTs))) {
          await db.update(
            _notesTable,
            noteLocalMap(c),
            where: 'id = ?',
            whereArgs: [existing.id],
          );
        }
      }
    }

    for (final id in pendingDeleteIds) {
      await db.delete(_notesTable, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> add(Note note) async {
    try {
      final created =
          note.copyWith(userId: AppState.myId ?? '');
      final n = Note(
        title: created.title,
        content: created.content,
        color: created.color,
        userId: created.userId,
        createdAt: DateTime.now().toIso8601String(),
      );
      int? cloudId;
      try {
        cloudId = await _insertCloud(n);
      } catch (e) {
        developer.log('NotesProvider.add cloud error: $e');
      }
      final db = await DatabaseHelper().database;
      // Mapa local en snake_case (columnas de la tabla SQLite).
      final map = {
        'cloud_id': cloudId,
        'user_id': n.userId,
        'title': n.title,
        'content': n.content,
        'color': n.color,
        'created_at': n.createdAt,
        'updated_at': n.updatedAt,
      };
      await db.insert(_notesTable, map,
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await _reloadFromLocal();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> update(Note note) async {
    try {
      if (note.id == null) return;
      final db = await DatabaseHelper().database;
      final rows = await db
          .query(_notesTable, where: 'id = ?', whereArgs: [note.id]);
      final localRow = rows.isNotEmpty
          ? Note.fromMap(Map<String, dynamic>.from(rows.first))
          : null;
      final cloudId = localRow?.cloudId ?? note.cloudId;
      final updated = Note(
        id: note.id,
        cloudId: note.cloudId,
        userId: note.userId,
        title: note.title,
        content: note.content,
        color: note.color,
        createdAt: note.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      // La edición no cambia el autor; solo actualizamos los campos de texto.
      final map = {
        'title': updated.title,
        'content': updated.content,
        'color': updated.color,
        'updated_at': updated.updatedAt,
      };
      await db.update(_notesTable, map, where: 'id = ?', whereArgs: [note.id]);
      if (cloudId != null) {
        try {
          await SupabaseConfig.client
              .from(_notesTable)
              .update(updated.toSupabaseMap())
              .eq('id', cloudId);
          await db.update(
              _notesTable, {'synced': 1}, where: 'id = ?', whereArgs: [note.id]);
        } catch (e) {
          developer.log('NotesProvider.update cloud error: $e');
          await db.update(
              _notesTable, {'synced': 0}, where: 'id = ?', whereArgs: [note.id]);
        }
      } else {
        try {
          final newCloudId = await _insertCloud(updated);
          if (newCloudId != null) {
            await db.update(_notesTable, {'cloud_id': newCloudId},
                where: 'id = ?', whereArgs: [note.id]);
          }
        } catch (e) {
          developer.log('NotesProvider.update insert error: $e');
        }
      }
      await _reloadFromLocal();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await DatabaseHelper().database;
      final rows =
          await db.query(_notesTable, where: 'id = ?', whereArgs: [id]);
      final cloudId = rows.isNotEmpty
          ? Note.fromMap(Map<String, dynamic>.from(rows.first)).cloudId
          : null;
      await db.delete(_notesTable, where: 'id = ?', whereArgs: [id]);
      if (cloudId != null) {
        try {
          await SupabaseConfig.client
              .from(_notesTable)
              .delete()
              .eq('id', cloudId);
} catch (e) {
          developer.log('NotesProvider.deleteAll cloud error: $e');
        }
      }
      await _reloadFromLocal();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAll() async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete(_notesTable);
      try {
        await SupabaseConfig.client.from(_notesTable).delete();
      } catch (e) {
        developer.log('NotesProvider.deleteAll cloud error: $e');
      }
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void upsert(Note note) async {
    if (note.id == null) {
      await add(note);
    } else {
      await update(note);
    }
  }

  Future<int?> _insertCloud(Note note) async {
    final res = await SupabaseConfig.client
        .from(_notesTable)
        .insert(note.toSupabaseMap())
        .select('id')
        .single()
        .timeout(const Duration(seconds: 10));
    return res['id'] as int?;
  }

  void _subscribeRealtime() {
    if (_realtimeUp) return;
    _realtimeUp = true;
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('notes_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _notesTable,
          callback: (_) => _debouncedReload(),
        )
        .subscribe();
  }

  Timer? _debounce;
  void _debouncedReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!_realtimeUp) return;
      _pullFromCloud().then((_) => _reloadFromLocal()).then((_) {
        notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}