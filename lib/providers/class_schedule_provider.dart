import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/class_schedule.dart';
import '../supabase_config.dart';

class ClassScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<ClassSchedule> _schedules = [];

  List<ClassSchedule> get schedules => _schedules;

  Future<void> loadSchedules() async {
    final maps = await _db.getAll('class_schedules', orderBy: 'dayOfWeek ASC, startTime ASC');
    _schedules = maps.map((e) => ClassSchedule.fromMap(e)).toList();
    await _syncUnsyncedToSupabase();
    notifyListeners();
  }

  /// Las clases previas al sync viven solo en SQLite (sin cloudId). Al cargar,
  /// se suben a Supabase para que el bot las conozca, y se guarda el id cloud.
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

  Future<int> addSchedule(ClassSchedule s) async {
    final id = await _db.insert('class_schedules', s.toMap());
    final cloudId = await _pushToSupabase(s.toSupabaseMap());
    if (cloudId != null) {
      await _db.update('class_schedules', {'cloudId': cloudId}, id);
    }
    final added = ClassSchedule(
      id: id, cloudId: cloudId, dayOfWeek: s.dayOfWeek, classTypeId: s.classTypeId,
      startTime: s.startTime, title: s.title,
      endTime: s.endTime, professor: s.professor,
      userId: s.userId, color: s.color,
    );
    _schedules.add(added);
    notifyListeners();
    return id;
  }

  Future<void> updateSchedule(ClassSchedule s) async {
    await _db.update('class_schedules', s.toMap(), s.id!);
    await _pushToSupabase(s.toSupabaseMap(), localId: s.id, cloudId: s.cloudId);
    final i = _schedules.indexWhere((x) => x.id == s.id);
    if (i != -1) _schedules[i] = s;
    notifyListeners();
  }

  Future<void> deleteSchedule(int id) async {
    final s = _schedules.firstWhere((x) => x.id == id, orElse: () => ClassSchedule(dayOfWeek: 0, startTime: '', title: ''));
    await _db.delete('class_schedules', id);
    await _deleteFromSupabase(s.cloudId);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
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
}
