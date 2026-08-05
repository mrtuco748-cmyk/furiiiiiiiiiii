import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/event_type.dart';

class EventTypeProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<EventType> _types = [];

  List<EventType> get types => _types;

  static final List<EventType> defaults = [
    EventType(name: 'Práctico', color: 0xFFFF9800, icon: 'handyman'),
    EventType(name: 'Examen', color: 0xFFE53935, icon: 'assignment'),
  ];

  Future<void> loadTypes() async {
    final maps = await _db.getAll('event_types', orderBy: 'name ASC');
    _types = maps.map((e) => EventType.fromMap(e)).toList();
    if (_types.isEmpty) {
      for (final d in defaults) {
        await _db.insert('event_types', d.toMap());
      }
      final maps2 = await _db.getAll('event_types', orderBy: 'name ASC');
      _types = maps2.map((e) => EventType.fromMap(e)).toList();
    }
    notifyListeners();
  }

  Future<void> addType(EventType type) async {
    final id = await _db.insert('event_types', type.toMap());
    _types.add(EventType(id: id, name: type.name, color: type.color, icon: type.icon));
    notifyListeners();
  }

  Future<void> updateType(EventType type) async {
    await _db.update('event_types', type.toMap(), type.id!);
    final i = _types.indexWhere((t) => t.id == type.id);
    if (i != -1) _types[i] = type;
    notifyListeners();
  }

  Future<void> deleteType(int id) async {
    await _db.delete('event_types', id);
    _types.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
