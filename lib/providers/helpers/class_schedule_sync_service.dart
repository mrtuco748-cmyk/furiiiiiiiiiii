import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../../models/class_schedule.dart';
import '../../supabase_config.dart';

/// Servicio auxiliar para la sincronización de horarios de clases con Supabase.
class ClassScheduleSyncService {
  final DatabaseHelper _db;

  ClassScheduleSyncService(this._db);

  /// Sube a Supabase las clases pendientes: las locales sin cloudId Y las ya sincronizadas pero modificadas offline.
  Future<void> syncUnsynced(List<ClassSchedule> schedules) async {
    final rows = await _db.getWhere(
      'class_schedules',
      'cloudId IS NULL OR synced = 0',
      <dynamic>[],
    );
    for (final r in rows) {
      final s = ClassSchedule.fromMap(r);
      final cloudId = r['cloudId'] as int?;
      final newCloudId = await pushToSupabase(
        s.toSupabaseMap(),
        localId: s.id,
        cloudId: cloudId,
        updatedAt: s.updatedAt,
      );
      if (newCloudId == null) continue;
      await _db.update(
        'class_schedules',
        {'cloudId': newCloudId, 'synced': 1},
        s.id!,
      );
      final i = schedules.indexWhere((x) => x.id == s.id);
      if (i != -1) schedules[i] = s.copyWith(cloudId: newCloudId);
    }
  }

  /// Trae todas las clases cloud y las mergea en SQLite local por cloudId.
  Future<void> pullFromCloud() async {
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
        final localTs = pair.first['updatedAt'] is String
            ? DateTime.tryParse(pair.first['updatedAt'] as String)
            : null;
        final cloudTs = c.updatedAt;
        if (cloudTs == null || localTs == null || cloudTs.isAfter(localTs)) {
          final localMap = c.toMap()
            ..remove('id')
            ..remove('cloudId')
            ..['cloudId'] = c.cloudId;
          await _db.update(
              'class_schedules', localMap, pair.first['id'] as int);
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

  /// Inserta o actualiza en Supabase respetando la recencia.
  Future<int?> pushToSupabase(
    Map<String, dynamic> map, {
    int? localId,
    int? cloudId,
    DateTime? updatedAt,
  }) async {
    try {
      if (cloudId != null) {
        if (updatedAt != null) {
          final cur = await SupabaseConfig.client
              .from('class_schedules')
              .select('updated_at')
              .eq('id', cloudId)
              .maybeSingle();
          final cloudTs = (cur != null && cur['updated_at'] is String)
              ? DateTime.tryParse(cur['updated_at'] as String)
              : null;
          if (cloudTs != null && cloudTs.isAfter(updatedAt)) {
            return cloudId;
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

  Future<void> deleteFromSupabase(int? cloudId) async {
    if (cloudId == null) return;
    try {
      await SupabaseConfig.client
          .from('class_schedules')
          .delete()
          .eq('id', cloudId);
    } catch (e) {
      developer.log('Sync: fallo borrar clase en Supabase: $e');
    }
  }
}
