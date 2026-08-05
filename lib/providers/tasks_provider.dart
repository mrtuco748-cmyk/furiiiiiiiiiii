import 'package:flutter/foundation.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../models/task.dart';
import 'sync_provider.dart';

class TasksProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _loading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() { _error = null; notifyListeners(); }

  List<Task> byColumn(int col) => _tasks.where((t) => t.column == col).toList()
    ..sort((a, b) => b.priority.compareTo(a.priority));

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await SupabaseConfig.client
          .from('tasks')
          .select()
          .or('created_by.eq.${AppState.myId},shared.eq.true')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      _tasks = (res as List).map((e) => Task.fromMap(e as Map<String, dynamic>)).toList();
      _error = null;
    } catch (e) {
      _tasks = [];
      _error = 'No se pudieron cargar las tareas';
      debugPrint('TasksProvider.load error: $e');
    }
    _loading = false; notifyListeners();
  }

  Future<void> add(Task task) async {
    final t = task.copyWith(createdBy: AppState.myId);
    _error = null;
    try {
      await SupabaseConfig.client.from('tasks').insert(t.toMap()).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo crear la tarea';
      debugPrint('TasksProvider.add error: $e');
      notifyListeners();
      return;
    }
    if (task.dueDate != null) {
      SyncProvider.instance?.emit(SyncEventType.taskWithDate, {
        'title': task.title,
        'due_date': task.dueDate!.toIso8601String(),
      });
    }
    await load();
  }

  Future<void> update(Task task) async {
    if (task.id == null) return;
    _error = null;
    try {
      await SupabaseConfig.client.from('tasks').update(task.toMap()).eq('id', task.id!).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo actualizar la tarea';
      debugPrint('TasksProvider.update error: $e');
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> move(int id, int newColumn) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(column: newColumn);
    notifyListeners();
    try {
      await SupabaseConfig.client.from('tasks').update({'column': newColumn}).eq('id', id).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo mover la tarea';
      debugPrint('TasksProvider.move error: $e');
      await load();
    }
  }

  Future<void> delete(int id) async {
    _tasks.removeWhere((t) => t.id == id); notifyListeners();
    try {
      await SupabaseConfig.client.from('tasks').delete().eq('id', id).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar la tarea';
      debugPrint('TasksProvider.delete error: $e');
      await load();
    }
  }
}
