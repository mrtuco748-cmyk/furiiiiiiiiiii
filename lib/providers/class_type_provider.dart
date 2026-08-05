import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/class_type.dart';

class ClassTypeProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<ClassType> _types = [];

  List<ClassType> get types => _types;

  static final List<ClassType> defaults = [
    ClassType(name: 'Gastronomía 1', color: 0xFF7B2D8E),
    ClassType(name: 'Pastelería 1', color: 0xFF4CAF50),
  ];

  Future<void> loadTypes() async {
    final maps = await _db.getAll('class_types', orderBy: 'name ASC');
    _types = maps.map((e) => ClassType.fromMap(e)).toList();
    if (_types.isEmpty) {
      for (final d in defaults) {
        await _db.insert('class_types', d.toMap());
      }
      final maps2 = await _db.getAll('class_types', orderBy: 'name ASC');
      _types = maps2.map((e) => ClassType.fromMap(e)).toList();
    }
    notifyListeners();
  }

  Future<void> addType(ClassType type) async {
    final id = await _db.insert('class_types', type.toMap());
    _types.add(ClassType(id: id, name: type.name, color: type.color));
    notifyListeners();
  }

  Future<void> updateType(ClassType type) async {
    await _db.update('class_types', type.toMap(), type.id!);
    final i = _types.indexWhere((t) => t.id == type.id);
    if (i != -1) _types[i] = type;
    notifyListeners();
  }

  Future<void> deleteType(int id) async {
    await _db.delete('class_types', id);
    _types.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
