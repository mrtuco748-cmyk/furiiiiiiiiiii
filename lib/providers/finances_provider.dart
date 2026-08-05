import 'package:flutter/foundation.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../models/transaction.dart';
import 'sync_provider.dart';

class FinancesProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _loading = false;
  String _period = 'month';
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  String get period => _period;
  set period(String v) { _period = v; notifyListeners(); }

  void clearError() { _error = null; notifyListeners(); }

  double get totalIncome => _filtered.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);
  double get totalExpenses => _filtered.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);
  double get balance => totalIncome - totalExpenses;

  List<Transaction> get _filtered {
    if (_period == 'all') return _transactions;
    final cutoff = _period == 'year' ? DateTime.now().subtract(const Duration(days: 365)) : DateTime.now().subtract(const Duration(days: 30));
    return _transactions.where((t) => t.date.isAfter(cutoff)).toList();
  }

  List<CategorySummary> get expensesByCategory {
    final map = <String, double>{};
    for (final t in _filtered.where((t) => t.type == 'expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map.entries.map((e) => CategorySummary(
      category: e.key, total: e.value,
      icon: _catIcon(e.key),
    )).toList()..sort((a, b) => b.total.compareTo(a.total));
  }

  static const _catIcons = {
    'food': '🍕', 'transport': '🚗', 'home': '🏠', 'shopping': '🛍️',
    'entertainment': '🎬', 'health': '💊', 'education': '📚', 'salary': '💼',
    'freelance': '💻', 'savings': '🏦', 'other': '📦',
  };
  String _catIcon(String cat) => _catIcons[cat] ?? '📦';

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await SupabaseConfig.client
          .from('transactions')
          .select()
          .order('date', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 10));
      _transactions = (res as List).map((e) => Transaction.fromMap(e as Map<String, dynamic>)).toList();
      _error = null;
    } catch (e) {
      _transactions = [];
      _error = 'No se pudieron cargar las finanzas';
      debugPrint('FinancesProvider.load error: $e');
    }
    _loading = false; notifyListeners();
  }

  Future<void> add(Transaction t) async {
    _error = null;
    try {
      await SupabaseConfig.client.from('transactions').insert(t.toMap()).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo guardar la transacción';
      debugPrint('FinancesProvider.add error: $e');
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> update(int id, Transaction t) async {
    _error = null;
    try {
      await SupabaseConfig.client.from('transactions').update(t.toMap()).eq('id', id).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo actualizar la transacción';
      debugPrint('FinancesProvider.update error: $e');
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> delete(int id) async {
    _transactions.removeWhere((t) => t.id == id); notifyListeners();
    try {
      await SupabaseConfig.client.from('transactions').delete().eq('id', id).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar la transacción';
      debugPrint('FinancesProvider.delete error: $e');
      await load();
    }
  }
}
