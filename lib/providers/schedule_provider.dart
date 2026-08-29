import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_helper.dart';
import '../models/schedule.dart';
import '../services/event_notification_service.dart';
import '../supabase_config.dart';
import 'schedule_sync.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Schedule> _schedules = [];
  bool _isLoading = false;
  RealtimeChannel? _channel;
  bool _realtimeUp = false;

  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  /// Carga local + sync bidireccional con Supabase + realtime.
  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _pushUnsyncedToCloud();
      await _pullFromCloud();
    } catch (e) {
      developer.log('Sync: fallo al sincronizar schedules: $e');
    }
    await _reloadFromLocal();
    _isLoading = false;
    notifyListeners();
    _subscribeRealtime();
    await _rescheduleNotifs();
  }

  Future<void> _reloadFromLocal() async {
    final maps =
        await _db.getAll('schedules', orderBy: 'date DESC, startTime ASC');
    _schedules = maps.map((e) => Schedule.fromMap(e)).toList();
  }

  /// Reprograma los recordatorios locales con el estado actual.
  Future<void> _rescheduleNotifs() async {
    try {
      await EventNotificationService().rescheduleAll(_schedules);
    } catch (e) {
      developer.log('Sync: fallo recordatorios de eventos: $e');
    }
  }

  /// Sube a Supabase los cambios locales pendientes: elementos nuevos
  /// (cloudId == null) Y ediciones de filas ya sincronizadas que quedaron
  /// "dirty" (synced = 0) por un push offline/falldo (antes estas últimas se
  /// perdían para siempre).
  Future<void> _pushUnsyncedToCloud() async {
    final maps = await _db.getAll('schedules');
    for (final m in maps) {
      final s = Schedule.fromMap(m);
      if (s.cloudId == null) {
        final cloudId = await _insertCloud(s);
        if (cloudId != null) {
          await _db.update('schedules', {'cloudId': cloudId}, s.id!);
        }
      } else if (m['synced'] == 0) {
        try {
          await SupabaseConfig.client
              .from('schedules')
              .update(s.toSupabaseMap())
              .eq('id', s.cloudId!);
          await _db.update('schedules', {'synced': 1}, s.id!);
        } catch (e) {
          developer.log('Sync: fallo re-push schedule ${s.id}: $e');
        }
      }
    }
  }

  /// Trae TODAS las filas cloud y las mergea en SQLite local por cloudId.
  Future<void> _pullFromCloud() async {
    final data = await SupabaseConfig.client.from('schedules').select('*');
    final cloud = (data as List)
        .map((r) => Schedule.fromCloudRow(Map<String, dynamic>.from(r as Map)))
        .toList();

    final localMaps = await _db.getAll('schedules');
    final local = localMaps.map((m) => Schedule.fromMap(m)).toList();
    final plan = buildScheduleSyncPlan(local: local, cloud: cloud);

    for (final s in plan.toInsertLocally) {
      final localMap = s.toMap()..remove('id')..['cloudId'] = s.cloudId;
      await _db.insert('schedules', localMap,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final s in plan.toUpdateLocally) {
      final localMap = s.toMap()
        ..remove('cloudId')
        ..remove('id');
      await _db.update('schedules', localMap, s.id!);
    }
    for (final id in plan.localIdsToDelete) {
      await _db.delete('schedules', id);
    }
  }

  Future<int> addSchedule(Schedule schedule) async {
    // Log the payload being sent to Supabase for debugging
    developer.log('Attempting to add schedule to Supabase: \\${schedule.toSupabaseMap()}');
    int? cloudId;
    try {
      cloudId = await _insertCloud(schedule);
    } catch (e) {
      developer.log('Sync: fallo al subir schedule a Supabase: $e');
      // Rethrow to allow UI to handle the error appropriately
      rethrow;
    }
    final insertedId = await _db.insert(
      'schedules',
      schedule.toMap()..['cloudId'] = cloudId,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    int id = insertedId;
    if (cloudId != null) {
      // Si el realtime ya inserto la misma fila (mismo cloudId), el insert
      // anterior se ignoro; resolver el id de la fila existente.
      final rows = await _db.getWhere('schedules', 'cloudId = ?', [cloudId]);
      if (rows.isNotEmpty) id = rows.first['id'] as int;
    }
    await _reloadFromLocal();
    notifyListeners();
    await _rescheduleNotifs();
    return id;
  }

  Future<void> updateSchedule(Schedule schedule) async {
    final localRow = await _db.getById('schedules', schedule.id!);
    final cloudId = localRow?['cloudId'] as int?;
    final updated = schedule.copyWith(updatedAt: DateTime.now());
    await _db.update('schedules', updated.toMap(), schedule.id!);
    if (cloudId != null) {
      try {
        await SupabaseConfig.client
            .from('schedules')
            .update(updated.toSupabaseMap())
            .eq('id', cloudId);
        await _db.update('schedules', {'synced': 1}, schedule.id!);
      } catch (e) {
        developer.log('Sync: fallo al actualizar schedule en Supabase: $e');
        // Marcar dirty para re-push en la próxima carga con internet.
        await _db.update('schedules', {'synced': 0}, schedule.id!);
      }
    } else {
      try {
        final newCloudId = await _insertCloud(updated);
        if (newCloudId != null) {
          await _db.update('schedules', {'cloudId': newCloudId}, schedule.id!);
        }
      } catch (e) {
        developer.log('Sync: fallo al insertar schedule en Supabase: $e');
      }
    }
    await _reloadFromLocal();
    notifyListeners();
    await _rescheduleNotifs();
  }

  Future<void> deleteSchedule(int id) async {
    final localRow = await _db.getById('schedules', id);
    final cloudId = localRow?['cloudId'] as int?;
    await _db.delete('schedules', id);
    if (cloudId != null) {
      try {
        await SupabaseConfig.client
            .from('schedules')
            .delete()
            .eq('id', cloudId);
      } catch (e) {
        developer.log('Sync: fallo al borrar schedule en Supabase: $e');
      }
    }
    await _reloadFromLocal();
    notifyListeners();
    await _rescheduleNotifs();
  }

  Future<int?> _insertCloud(Schedule schedule) async {
    final res = await SupabaseConfig.client
        .from('schedules')
        .insert(schedule.toSupabaseMap())
        .select('id')
        .single();
    return res['id'] as int?;
  }

  void _subscribeRealtime() {
    if (_realtimeUp) return;
    _realtimeUp = true;
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('schedules_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'schedules',
          callback: _onRealtimeEvent,
        )
        .subscribe();
  }

  Future<void> _onRealtimeEvent(PostgresChangePayload payload) async {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final oldId = payload.oldRecord['id'] as int?;
        if (oldId != null) {
          await _deleteLocalByCloudId(oldId);
          notifyListeners();
          await _rescheduleNotifs();
        }
        return;
      }
      final cloudS = Schedule.fromCloudRow(payload.newRecord);
      final rows = await _db.getWhere(
          'schedules', 'cloudId = ?', [cloudS.cloudId]);
      if (rows.isEmpty) {
        await _db.insert(
          'schedules',
          cloudS.toMap()
            ..remove('id')
            ..['cloudId'] = cloudS.cloudId,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } else {
        final localS = Schedule.fromMap(rows.first);
        if (cloudS.updatedAt.isAfter(localS.updatedAt)) {
          await _db.update(
            'schedules',
            cloudS.toMap()
              ..remove('id')
              ..remove('cloudId'),
            localS.id!,
          );
        }
      }
      await _reloadFromLocal();
      notifyListeners();
      await _rescheduleNotifs();
    } catch (e) {
      developer.log('Sync: fallo realtime schedules: $e');
    }
  }

  Future<void> _deleteLocalByCloudId(int cloudId) async {
    final rows =
        await _db.getWhere('schedules', 'cloudId = ?', [cloudId]);
    for (final r in rows) {
      await _db.delete('schedules', r['id'] as int);
    }
    _schedules.removeWhere((s) => s.cloudId == cloudId);
  }

  Future<List<Schedule>> getSchedulesByDate(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await _db.getWhere('schedules', "date LIKE ?", ['$dateStr%'],
        orderBy: 'startTime ASC');
    return maps.map((e) => Schedule.fromMap(e)).toList();
  }

  List<Schedule> getTodaysSchedules() {
    final today = DateTime.now();
    return _schedules
        .where((s) =>
            s.date.year == today.year &&
            s.date.month == today.month &&
            s.date.day == today.day)
        .toList();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
