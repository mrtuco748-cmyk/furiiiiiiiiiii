import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../models/class_schedule.dart';
import '../services/class_notification_service.dart';
import '../supabase_config.dart';
import 'helpers/class_schedule_sync_service.dart';

class ClassScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  late final ClassScheduleSyncService _syncService = ClassScheduleSyncService(_db);

  List<ClassSchedule> _schedules = [];
  RealtimeChannel? _channel;
  bool _realtimeUp = false;

  List<ClassSchedule> get schedules => _schedules;

  Future<void> loadSchedules() async {
    await _reloadFromLocal();
    try {
      await _syncService.syncUnsynced(_schedules);
      await _syncService.pullFromCloud();
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

  Future<int> addSchedule(ClassSchedule s) async {
    final added0 = s.copyWith(updatedAt: DateTime.now());
    int? cloudId;
    try {
      cloudId = await _syncService.pushToSupabase(added0.toSupabaseMap());
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
      final rows =
          await _db.getWhere('class_schedules', 'cloudId = ?', [cloudId]);
      if (rows.isNotEmpty) id = rows.first['id'] as int;
    }
    final added = ClassSchedule(
      id: id,
      cloudId: cloudId,
      dayOfWeek: s.dayOfWeek,
      classTypeId: s.classTypeId,
      startTime: s.startTime,
      title: s.title,
      endTime: s.endTime,
      professor: s.professor,
      userId: s.userId,
      color: s.color,
      updatedAt: added0.updatedAt,
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
    final pushed = await _syncService.pushToSupabase(
      updated.toSupabaseMap(),
      localId: s.id,
      cloudId: cloudId,
      updatedAt: now,
    );
    if (pushed == null) {
      await _db.update('class_schedules', {'synced': 0}, s.id!);
    } else {
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
    await _syncService.deleteFromSupabase(cloudId);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
    await _rescheduleNotifs();
  }

  List<ClassSchedule> getByDay(int dayOfWeek) {
    return _schedules.where((s) => s.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
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
