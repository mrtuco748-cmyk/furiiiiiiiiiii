import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../models/class_schedule.dart';
import '../services/class_notification_service.dart';
import '../supabase_config.dart';

class ClassScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<ClassSchedule> _schedules = [];
  RealtimeChannel? _channel;
  bool _realtimeUp = false;

  List<ClassSchedule> get schedules => _schedules;

  Future<void> loadSchedules() async {
    await _reloadFromLocal();
    try {
      await _syncUnsyncedToSupabase();
      await _pullFromCloud();
    } catch (e) {
      developer.log('Sync: fallo al sincronizar class_schedules: $e');
    }
    await _reloadFromLocal();
    notifyListeners();
    _subscribeRealtime();
    await _rescheduleNotifs();
  }

  Future<void> _reloadFromLocal() async {
    final maps =
        await _db.getAll('class_schedules', orderBy: 'dayOfWeek ASC, startTime ASC');
    _schedules = maps.map((e) => ClassSchedule.fromMap(e)).toList();
  }

  /// Reprograma los recordatorios locales con el estado actual.
  Future<void> _rescheduleNotifs() async {
    try {
      await ClassNotificationService().rescheduleAll(_schedules);
    } catch (e) {
      developer.log('Sync: fallo recordatorios de clases: $e');
    }
  }

  /// Sube a Supabase las clases pendientes: las locales sin cloudId (nunca
  /// sincronizadas) Y las YA sincronizadas pero modificadas offline (synced=0,
  /// que antes se perdían para siempre).
  Future<void> _syncUnsyncedToSupabase() async {
    final rows = await _db.getWhere(
      'class_schedules',
      'cloudId IS NULL OR synced = 0',
      <dynamic>[],
    );
    for (final r in rows) {
      final s = ClassSchedule.fromMap(r);
      final cloudId = r['cloudId'] as int?;
      final newCloudId = await _pushToSupabase(
        s.toSupabaseMap(),
        localId: s.id,
        cloudId: cloudId,
        updatedAt: s.updatedAt,
      );
      if (newCloudId == null) continue; // sin red: reintentar en próxima carga
      await _db.update(
        'class_schedules',
        {'cloudId': newCloudId, 'synced': 1},
        s.id!,
      );
      final i = _schedules.indexWhere((x) => x.id == s.id);
      if (i != -1) _schedules[i] = s.copyWith(cloudId: newCloudId);
    }
  }

  /// Trae TODAS las clases cloud y las mergea en SQLite local por cloudId.
  /// Las clases de la pareja aparecen, y sus EDICIONES sobre clases existentes
  /// (día, hora, profesor) también bajan (antes solo se insert/delete, jamás
  /// se actualizaba una fila local existente → cambios de la pareja se perdían).
  Future<void> _pullFromCloud() async {
    final data =
        await SupabaseConfig.client.from('class_schedules').select('*');
    final cloud = (data as List)
        .map((r) =>
            ClassSchedule.fromCloudRow(Map<String, dynamic>.from(r as Map)))
        .toList();
    final cloudIds = cloud.map((s) => s.cloudId).whereType<int>().toSet();

    final localMaps = await _db.getAll('class_schedules');
    for (final c in cloud) {
      if (c.cloudId == null) continue;
      final pair = localMaps.where((m) => m['cloudId'] == c.cloudId).toList();
      if (pair.isEmpty) {
        await _db.insert(
          'class_schedules',
          c.toMap()
            ..remove('id')
            ..['cloudId'] = c.cloudId,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } else {
        // Espejo por recencia: solo sobrescribir la local con la cloud si la
        // cloud es más nueva (o la local no tiene timestamp aún). Preserva la
        // edición offline local mientras la cloud no la supere (espeja schedules).
        final localTs = pair.first['updatedAt'] is String
            ? DateTime.tryParse(pair.first['updatedAt'] as String)
            : null;
        final cloudTs = c.updatedAt;
        if (cloudTs == null || localTs == null || cloudTs.isAfter(localTs)) {
          final localMap = c.toMap()
            ..remove('id')
            ..remove('cloudId')
            ..['cloudId'] = c.cloudId;
          await _db.update('class_schedules', localMap, pair.first['id'] as int);
        }
      }
    }
    for (final m in localMaps) {
      final cid = m['cloudId'] as int?;
      if (cid != null && !cloudIds.contains(cid)) {
        await _db.delete('class_schedules', m['id'] as int);
      }
    }
  }

  Future<int> addSchedule(ClassSchedule s) async {
    final added0 = s.copyWith(updatedAt: DateTime.now());
    int? cloudId;
    try {
      cloudId = await _pushToSupabase(added0.toSupabaseMap());
    } catch (e) {
      developer.log('Sync: fallo clases a Supabase: $e');
    }
    final insertedId = await _db.insert(
      'class_schedules',
      added0.toMap()..['cloudId'] = cloudId,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    int id = insertedId;
    if (cloudId != null) {
      // Si el realtime ya inserto la misma fila (mismo cloudId), resolverla.
      final rows =
          await _db.getWhere('class_schedules', 'cloudId = ?', [cloudId]);
      if (rows.isNotEmpty) id = rows.first['id'] as int;
    }
    final added = ClassSchedule(
      id: id, cloudId: cloudId, dayOfWeek: s.dayOfWeek, classTypeId: s.classTypeId,
      startTime: s.startTime, title: s.title,
      endTime: s.endTime, professor: s.professor,
      userId: s.userId, color: s.color, updatedAt: added0.updatedAt,
    );
    _schedules.add(added);
    notifyListeners();
    await _rescheduleNotifs();
    return id;
  }

  Future<void> updateSchedule(ClassSchedule s) async {
    final now = DateTime.now();
    final updated = s.copyWith(updatedAt: now);
    final localRow = await _db.getById('class_schedules', s.id!);
    final cloudId = localRow?['cloudId'] as int?;
    await _db.update('class_schedules', updated.toMap(), s.id!);
    final pushed = await _pushToSupabase(updated.toSupabaseMap(),
        localId: s.id, cloudId: cloudId, updatedAt: now);
    if (pushed == null) {
      // Pull offline/falló: marcar dirty para re-push en la próxima carga.
      await _db.update('class_schedules', {'synced': 0}, s.id!);
    } else {
      // Push exitoso: la fila quedó sincronizada, volver a marcar limpia para
      // no re-subirla redundantemente en cada load().
      await _db.update('class_schedules', {'synced': 1}, s.id!);
    }
    final i = _schedules.indexWhere((x) => x.id == s.id);
    if (i != -1) _schedules[i] = updated;
    notifyListeners();
    await _rescheduleNotifs();
  }

  Future<void> deleteSchedule(int id) async {
    final localRow = await _db.getById('class_schedules', id);
    final cloudId = localRow?['cloudId'] as int?;
    await _db.delete('class_schedules', id);
    await _deleteFromSupabase(cloudId);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
    await _rescheduleNotifs();
  }

  List<ClassSchedule> getByDay(int dayOfWeek) {
    return _schedules.where((s) => s.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Inserta o actualiza en Supabase. Usa [cloudId] (si existe) como PK cloud;
  /// las filas sin cloudId se insertan y devuelve el id asignado por Supabase.
  Future<int?> _pushToSupabase(Map<String, dynamic> map,
      {int? localId, int? cloudId, DateTime? updatedAt}) async {
    try {
      if (cloudId != null) {
        // No pisar la edición más reciente de la pareja (último-write-gana):
        // si la fila cloud es más nueva que la local, no subimos la vieja y la
        // próxima pull la aplica en este dispositivo (espeja schedules).
        if (updatedAt != null) {
          final cur = await SupabaseConfig.client
              .from('class_schedules')
              .select('updated_at')
              .eq('id', cloudId)
              .maybeSingle();
          final cloudTs =
              (cur != null && cur['updated_at'] is String)
                  ? DateTime.tryParse(cur['updated_at'] as String)
                  : null;
          if (cloudTs != null && cloudTs.isAfter(updatedAt)) {
            return cloudId; // espejo más reciente: no sobrescribir
          }
        }
        await SupabaseConfig.client
            .from('class_schedules')
            .update(map)
            .eq('id', cloudId);
        return cloudId;
      }
      final res = await SupabaseConfig.client
          .from('class_schedules')
          .insert(map)
          .select('id')
          .single();
      return res['id'] as int?;
    } catch (e) {
      developer.log('Sync: fallo clases a Supabase: $e');
      return null;
    }
  }

  Future<void> _deleteFromSupabase(int? cloudId) async {
    if (cloudId == null) return;
    try {
      await SupabaseConfig.client.from('class_schedules').delete().eq('id', cloudId);
    } catch (e) {
      developer.log('Sync: fallo borrar clase en Supabase: $e');
    }
  }

  void _subscribeRealtime() {
    if (_realtimeUp) return;
    _realtimeUp = true;
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('class_schedules_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'class_schedules',
          callback: _onRealtimeEvent,
        )
        .subscribe();
  }

  Future<void> _onRealtimeEvent(PostgresChangePayload payload) async {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final oldId = payload.oldRecord['id'] as int?;
        if (oldId != null) {
          final rows = await _db
              .getWhere('class_schedules', 'cloudId = ?', [oldId]);
          for (final r in rows) {
            await _db.delete('class_schedules', r['id'] as int);
          }
          _schedules.removeWhere((s) => s.cloudId == oldId);
          notifyListeners();
          await _rescheduleNotifs();
        }
        return;
      }
      final cloudS = ClassSchedule.fromCloudRow(payload.newRecord);
      final rows = await _db
          .getWhere('class_schedules', 'cloudId = ?', [cloudS.cloudId]);
      if (rows.isEmpty) {
        await _db.insert(
          'class_schedules',
          cloudS.toMap()
            ..remove('id')
            ..['cloudId'] = cloudS.cloudId,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } else {
        // UPDATE de una clase existente por parte de la pareja: aplicar solo si
        // la cloud es más nueva que la local (no pisar una edición offline más
        // reciente en este dispositivo).
        final localTs = rows.first['updatedAt'] is String
            ? DateTime.tryParse(rows.first['updatedAt'] as String)
            : null;
        final cloudTs = cloudS.updatedAt;
        if (cloudTs == null || localTs == null || cloudTs.isAfter(localTs)) {
          final localMap = cloudS.toMap()
            ..remove('id')
            ..remove('cloudId')
            ..['cloudId'] = cloudS.cloudId;
          await _db.update(
            'class_schedules', localMap, rows.first['id'] as int);
        }
      }
      await _reloadFromLocal();
      notifyListeners();
      await _rescheduleNotifs();
    } catch (e) {
      developer.log('Sync: fallo realtime class_schedules: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
