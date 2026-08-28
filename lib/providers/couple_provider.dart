import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/couple_stats.dart';
import '../supabase_config.dart';

/// Racha de pareja: días consecutivos en que AMBOS miembros estuvieron
/// "activos" (registraron mood o completaron un entrenamiento). Calculado
/// desde tablas con `user_id` + fecha, sin cache local (como finanzas/workouts).
class CoupleProvider extends ChangeNotifier {
  static const _moodsTable = 'moods';
  static const _completionsTable = 'workout_completions';

  /// Señales de "actividad intencional" por usuario y día. Se unifican en
  /// `activeDays` como base de la racha.
  final List<CoupleActivity> _activities = [];

  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  bool _realtimeUp = false;
  bool _reloading = false;
  bool _reloadQueued = false;

  List<CoupleActivity> get activities => List.unmodifiable(_activities);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  String get myId => AppState.myId ?? '';
  String get partnerId => AppState.partnerId ?? '';

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Días en que ambos miembros estuvieron activos.
  Set<DateTime> get bothDays => CoupleStats.bothActiveDays(
      _activeByDay, members: {myId, partnerId});

  Map<DateTime, Set<String>> get _activeByDay =>
      CoupleStats.activeByDay(_activities);

  /// Racha actual de pareja.
  int get coupleStreak => CoupleStats.streakFor(bothDays);

  /// Racha de pareja más larga registrada.
  int get bestCoupleStreak => CoupleStats.bestStreak(bothDays);

  /// ¿Hoy ya fue un día activo de ambos?
  bool get todayActive => myId.isNotEmpty &&
      partnerId.isNotEmpty &&
      CoupleStats.isBothActiveOn(bothDays, DateTime.now());

  // ─── CARGA ────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await _reload();
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  Future<List<CoupleActivity>> _fetchMoods() async {
    final data = await SupabaseConfig.client
        .from(_moodsTable)
        .select('user_id, date')
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((r) => CoupleActivity.fromMap(Map<String, dynamic>.from(r as Map)))
        .where((a) => a.userId.isNotEmpty)
        .toList();
  }

  Future<List<CoupleActivity>> _fetchCompletions() async {
    final data = await SupabaseConfig.client
        .from(_completionsTable)
        .select('user_id, completed_on')
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((r) => CoupleActivity.fromMap({
              'user_id': r['user_id'],
              'date': r['completed_on'],
            }))
        .where((a) => a.userId.isNotEmpty)
        .toList();
  }

  // ─── REALTIME ─────────────────────────────────────────────────

  void _subscribeRealtime() {
    if (_realtimeUp) return;
    _realtimeUp = true;
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('couple_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _moodsTable,
          callback: (_) => _reload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _completionsTable,
          callback: (_) => _reload(),
        )
        .subscribe();
  }

  /// Recarga serializada: los fetch llenan listas LOCALES y se asignan
  /// atómicamente al final. Antes se hacía `clear()` sobre la lista compartida
  /// y dos eventos realtime simultáneos (mood + completion) se cruzaban:
  /// uno borraba lo que el otro ya había agregado y quedaban duplicados.
  Future<void> _reload() async {
    if (_reloading) {
      _reloadQueued = true;
      return;
    }
    _reloading = true;
    try {
      final results = await Future.wait([_fetchMoods(), _fetchCompletions()]);
      final all = <CoupleActivity>[...results[0], ...results[1]];
      _activities
        ..clear()
        ..addAll(all);
    } catch (e) {
      _error = 'No se pudo cargar la racha';
      developer.log('CoupleProvider._reload error: $e');
    } finally {
      _reloading = false;
    }
    notifyListeners();
    if (_reloadQueued) {
      _reloadQueued = false;
      await _reload();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}