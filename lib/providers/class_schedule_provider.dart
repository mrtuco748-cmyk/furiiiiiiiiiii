import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/class_schedule.dart';

class ClassScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<ClassSchedule> _schedules = [];

  List<ClassSchedule> get schedules => _schedules;

  Future<void> loadSchedules() async {
    final maps = await _db.getAll('class_schedules', orderBy: 'dayOfWeek ASC, startTime ASC');
    _schedules = maps.map((e) => ClassSchedule.fromMap(e)).toList();
    notifyListeners();
  }

  Future<int> addSchedule(ClassSchedule s) async {
    final id = await _db.insert('class_schedules', s.toMap());
    final added = ClassSchedule(
      id: id, dayOfWeek: s.dayOfWeek, classTypeId: s.classTypeId,
      startTime: s.startTime, title: s.title,
    );
    _schedules.add(added);
    notifyListeners();
    return id;
  }

  Future<void> updateSchedule(ClassSchedule s) async {
    await _db.update('class_schedules', s.toMap(), s.id!);
    final i = _schedules.indexWhere((x) => x.id == s.id);
    if (i != -1) _schedules[i] = s;
    notifyListeners();
  }

  Future<void> deleteSchedule(int id) async {
    await _db.delete('class_schedules', id);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  List<ClassSchedule> getByDay(int dayOfWeek) {
    return _schedules.where((s) => s.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}
