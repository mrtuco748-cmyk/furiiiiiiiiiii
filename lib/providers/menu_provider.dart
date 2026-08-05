import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/menu_plan.dart';

class MenuProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<MenuPlan> _menus = [];
  bool _isLoading = false;

  List<MenuPlan> get menus => _menus;
  bool get isLoading => _isLoading;

  Future<void> loadMenus() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.getAll('menu_plans', orderBy: 'date DESC, mealType ASC');
    _menus = maps.map((e) => MenuPlan.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addMenu(MenuPlan menu) async {
    final id = await _db.insert('menu_plans', menu.toMap());
    await loadMenus();
    return id;
  }

  Future<void> updateMenu(MenuPlan menu) async {
    await _db.update(
        'menu_plans', menu.copyWith(updatedAt: DateTime.now()).toMap(), menu.id!);
    await loadMenus();
  }

  Future<void> deleteMenu(int id) async {
    await _db.delete('menu_plans', id);
    await loadMenus();
  }

  Future<List<MenuPlan>> getMenusByDate(DateTime date) async {
    final maps = await _db.getWhere('menu_plans',
        "date LIKE ?", ['${date.toIso8601String().substring(0, 10)}%']);
    return maps.map((e) => MenuPlan.fromMap(e)).toList();
  }
}
