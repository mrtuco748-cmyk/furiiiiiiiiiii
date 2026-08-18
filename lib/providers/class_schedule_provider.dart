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

  /// Las clases previas al sync viven solo en SQLite (sin cloudId). Al cargar,
  /// se suben a Supabase para que el bot y la pareja las conozcan.
  Future<void> _syncUnsyncedToSupabase() async {
    final unsynced = _schedules.where((s) => s.cloudId == null).toList();
    for (final s in unsynced) {
      final cloudId = await _pushToSupabase(s.toSupabaseMap());
      if (cloudId != null) {
        await _db.update('class_schedules', {'cloudId': cloudId}, s.id!);
        final i = _schedules.indexWhere((x) => x.id == s.id);
        if (i != -1) _schedules[i] = s.copyWith(cloudId: cloudId);
      }
    }
  }

  /// Trae TODAS las clases cloud y las mergea en SQLite local por cloudId.
  /// Asi las clases cargadas por la pareja aparecen en este dispositivo.
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
    int? cloudId;
    try {
      cloudId = await _pushToSupabase(s.toSupabaseMap());
    } catch (e) {
      developer.log('Sync: fallo clases a Supabase: $e');
    }
    final insertedId = await _db.insert(
      'class_schedules',
      s.toMap()..['cloudId'] = cloudId,
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
      userId: s.userId, color: s.color,
    );
    _schedules.add(added);
    notifyListeners();
    await _rescheduleNotifs();
    return id;
  }

  Future<void> updateSchedule(ClassSchedule s) async {
    final localRow = await _db.getById('class_schedules', s.id!);
    final cloudId = localRow?['cloudId'] as int?;
    await _db.update('class_schedules', s.toMap(), s.id!);
    await _pushToSupabase(s.toSupabaseMap(),
        localId: s.id, cloudId: cloudId);
    final i = _schedules.indexWhere((x) => x.id == s.id);
    if (i != -1) _schedules[i] = s;
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
  Future<int?> _pushToSupabase(Map<String, dynamic> map, {int? localId, int? cloudId}) async {
    try {
      if (cloudId != null) {
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
