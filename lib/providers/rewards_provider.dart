import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/rewards.dart';
import '../supabase_config.dart';

/// Puntos y recompensas de pareja: cajita de deseos (rewards) + libro de
/// puntos (PointsEntry). Sin cache local (como finanzas/workouts).
class RewardsProvider extends ChangeNotifier {
  static const _rewardsTable = 'couple_rewards';
  static const _pointsTable = 'couple_points';

  List<CoupleReward> _rewards = [];
  List<PointsEntry> _entries = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<CoupleReward> get rewards => List.unmodifiable(_rewards);
  List<PointsEntry> get entries => List.unmodifiable(_entries);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  String get myId => AppState.myId ?? '';

  int get myBalance => PointsStats.balanceOf(_entries, myId);
  int get totalBalance => PointsStats.total(_entries);
  int get totalEarned => PointsStats.pointsEarned(_entries, myId);

  List<CoupleReward> get pendingRewards =>
      _rewards.where((r) => !r.fulfilled).toList();
  List<CoupleReward> get fulfilledRewards =>
      _rewards.where((r) => r.fulfilled).toList();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.wait([_loadRewards(), _loadPoints()]);
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  Future<void> _loadRewards() async {
    try {
      final data = await SupabaseConfig.client
          .from(_rewardsTable)
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      _rewards = (data as List)
          .map((r) => CoupleReward.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      _error = 'No se pudieron cargar las recompensas';
      developer.log('RewardsProvider._loadRewards error: $e');
    }
  }

  Future<void> _loadPoints() async {
    try {
      final data = await SupabaseConfig.client
          .from(_pointsTable)
          .select()
          .order('created_at', ascending: true)
          .timeout(const Duration(seconds: 10));
      _entries = (data as List)
          .map((r) => PointsEntry.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      _error = 'No se pudieron cargar los puntos';
      developer.log('RewardsProvider._loadPoints error: $e');
    }
  }

  Future<void> addReward(String title, String emoji, int cost) async {
    _error = null;
    try {
      await SupabaseConfig.client.from(_rewardsTable).insert(
          CoupleReward(title: title, emoji: emoji, cost: cost, createdBy: myId).toMap());
      await _loadRewards();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo crear la recompensa';
      developer.log('RewardsProvider.addReward error: $e');
      notifyListeners();
    }
  }

  Future<void> deleteReward(int id) async {
    _rewards.removeWhere((r) => r.id == id);
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_rewardsTable)
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo eliminar la recompensa';
      developer.log('RewardsProvider.deleteReward error: $e');
      await _loadRewards();
      notifyListeners();
    }
  }

  Future<void> toggleFulfilled(int id) async {
    final idx = _rewards.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final next = _rewards[idx].copyWith(fulfilled: !_rewards[idx].fulfilled);
    _rewards[idx] = next;
    notifyListeners();
    try {
      await SupabaseConfig.client
          .from(_rewardsTable)
          .update({'fulfilled': next.fulfilled})
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo actualizar la recompensa';
      developer.log('RewardsProvider.toggleFulfilled error: $e');
      await _loadRewards();
      notifyListeners();
    }
  }

  /// Registra un movimiento de puntos (hook para futura automatización).
  Future<void> addPoints(String userId, String reason, int delta) async {
    _error = null;
    try {
      await SupabaseConfig.client
          .from(_pointsTable)
          .insert(PointsEntry(userId: userId, reason: reason, delta: delta).toMap());
      await _loadPoints();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudieron guardar los puntos';
      developer.log('RewardsProvider.addPoints error: $e');
      notifyListeners();
    }
  }

  /// Otorga puntos de forma IDEMPOTENTE por `reason`: inserta con
  /// `ON CONFLICT DO NOTHING` sobre (user_id, reason), que es transaccional y
  /// atómico (evita el race check-then-insert de la versión anterior que podía
  /// duplicar puntos cuando dos dispositivos/realtime disparan la misma razón).
  /// Fire-and-forget.
  Future<void> awardOnce(String userId, String reason, int delta) async {
    if (userId.isEmpty || reason.isEmpty) return;
    _error = null;
    try {
      await SupabaseConfig.client
          .from(_pointsTable)
          .upsert(
            PointsEntry(userId: userId, reason: reason, delta: delta).toMap(),
            onConflict: 'user_id,reason',
            ignoreDuplicates: true,
          )
          .timeout(const Duration(seconds: 10));
      await _loadPoints();
      notifyListeners();
    } catch (e) {
      _error = 'No se pudieron guardar los puntos';
      developer.log('RewardsProvider.awardOnce error: $e');
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('rewards_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _rewardsTable,
          callback: _onRewardsRealtime,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _pointsTable,
          callback: _onPointsRealtime,
        )
        .subscribe();
  }

  void _onRewardsRealtime(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['id'];
      if (id != null) {
        _rewards