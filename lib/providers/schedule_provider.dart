import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/schedule.dart';
import '../supabase_config.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Schedule> _schedules = [];
  bool _isLoading = false;

  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();
    final maps =
        await _db.getAll('schedules', orderBy: 'date DESC, startTime ASC');
    _schedules = maps.map((e) => Schedule.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addSchedule(Schedule schedule) async {
    final id = await _db.insert('schedules', schedule.toMap());
    try {
      await SupabaseConfig.client.from('schedules').insert({
        'title': schedule.title,
        'description': schedule.description,
        'date': schedule.date.toIso8601String().substring(0, 10),
        'startTime': schedule.startTime,
        'endTime': schedule.endTime,
        'location': schedule.location,
        'instructor': schedule.instructor,
        'type': schedule.type,
        'color': schedule.color,
        'createdAt': schedule.createdAt.toIso8601String(),
        'updatedAt': schedule.updatedAt.toIso8601String(),
      });
    } catch (e) {
      developer.log('Sync: fallo al subir schedule a Supabase: $e');
    }
    await loadSchedules();
    return id;
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _db.update(
        'schedules', schedule.copyWith(updatedAt: DateTime.now()).toMap(), schedule.id!);
    await loadSchedules();
  }

  Future<void> deleteSchedule(int id) async {
    await _db.delete('schedules', id);
    await loadSchedules();
  }

  Future<List<Schedule>> getSchedulesByDate(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await _db.getWhere('schedules', "date LIKE ?", ['$dateStr%'], orderBy: 'startTime ASC');
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
}
